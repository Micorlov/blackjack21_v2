#!/usr/bin/env python3
"""Upload the store listing's images to Google Play.

The listing's *text* can be edited through several tools, but its images have
to go through the Android Publisher API (or the Console by hand). This does the
API route with the same service account the bundle upload uses, so a refreshed
screenshot set never depends on clicking through a browser.

    python3 tool/play_images.py --language en-US

Each image type is cleared before it is re-uploaded: Play appends otherwise,
and the old four screenshots would sit behind the new eight.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

SCOPE = "https://www.googleapis.com/auth/androidpublisher"
DEFAULT_PACKAGE = "com.micorlov.blackjack21_v2"
DEFAULT_KEY = "android/play-service-account.json"
ASSETS = Path(__file__).resolve().parent.parent / "play-assets"

# Play's own names for the slots, and what this repo puts in each. Order is
# preserved on the listing, so the first phone screenshot is the one a browsing
# player sees in search results.
IMAGE_SETS = {
    "featureGraphic": ["feature-graphic.png"],
    "icon": ["icon-512.png"],
    "phoneScreenshots": [f"screen-{i:02d}.png" for i in range(1, 9)],
    "sevenInchScreenshots": ["tab7-01.png", "tab7-02.png"],
    "tenInchScreenshots": ["tab10-01.png", "tab10-02.png"],
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--language", default="en-US", help="listing locale to attach images to")
    parser.add_argument("--package", default=DEFAULT_PACKAGE)
    parser.add_argument("--key", default=DEFAULT_KEY)
    parser.add_argument(
        "--only",
        help="comma-separated image types to upload; default is all of them",
    )
    parser.add_argument("--dry-run", action="store_true", help="list what would be uploaded")
    return parser.parse_args()


def run(args: argparse.Namespace) -> int:
    wanted = IMAGE_SETS
    if args.only:
        keys = [k.strip() for k in args.only.split(",")]
        unknown = [k for k in keys if k not in IMAGE_SETS]
        if unknown:
            print(f"error: unknown image type(s): {', '.join(unknown)}", file=sys.stderr)
            return 1
        wanted = {k: IMAGE_SETS[k] for k in keys}

    missing = [f for files in wanted.values() for f in files if not (ASSETS / f).is_file()]
    if missing:
        print(f"error: missing asset(s): {', '.join(missing)}", file=sys.stderr)
        return 1

    if args.dry_run:
        for kind, files in wanted.items():
            print(f"{kind}: {', '.join(files)}")
        return 0

    key = Path(args.key)
    if not key.is_file():
        print(f"error: no service account key at {key}", file=sys.stderr)
        return 1

    credentials = service_account.Credentials.from_service_account_file(str(key), scopes=[SCOPE])
    service = build("androidpublisher", "v3", credentials=credentials, cache_discovery=False)
    edits = service.edits()

    edit_id = edits.insert(body={}, packageName=args.package).execute()["id"]
    print(f"opened edit {edit_id}")

    for kind, files in wanted.items():
        edits.images().deleteall(
            packageName=args.package, editId=edit_id, language=args.language, imageType=kind
        ).execute()
        for name in files:
            media = MediaFileUpload(str(ASSETS / name), mimetype="image/png", resumable=False)
            edits.images().upload(
                packageName=args.package,
                editId=edit_id,
                language=args.language,
                imageType=kind,
                media_body=media,
            ).execute()
            print(f"  uploaded {name} -> {kind}")

    edits.commit(packageName=args.package, editId=edit_id).execute()
    print(f"committed: {args.language} listing images updated")
    return 0


def main() -> int:
    args = parse_args()
    try:
        return run(args)
    except HttpError as error:
        print(f"error: Play API rejected the request: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
