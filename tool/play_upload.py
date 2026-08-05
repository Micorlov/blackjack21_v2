#!/usr/bin/env python3
"""Upload a signed .aab to Google Play and roll it out on a track.

Uses the Google Play Android Developer API v3 with a service account key, so a
release never depends on clicking through the Play Console UI.

    python3 tool/play_upload.py \
        --aab build/app/outputs/bundle/release/app-release.aab \
        --track internal \
        --release-name "1.0.0 (1)" \
        --notes-file tool/release_notes_en-US.txt

The service account key is read from --key (default: android/play-service-account.json),
which is gitignored and must never be committed.
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

# Play's track ids: "internal" and "alpha" (closed testing) never reach the
# store, "beta" (open testing) and "production" do.
TRACKS = ("internal", "alpha", "beta", "production")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--aab", help="path to the signed .aab")
    parser.add_argument(
        "--version-code",
        type=int,
        help="reuse a bundle already uploaded to Play instead of uploading a new one; "
        "this is how one build reaches a second track (Play rejects a re-upload of "
        "the same version code)",
    )
    parser.add_argument("--track", required=True, choices=TRACKS)
    parser.add_argument("--package", default=DEFAULT_PACKAGE)
    parser.add_argument("--key", default=DEFAULT_KEY, help="service account JSON key")
    parser.add_argument("--release-name", help="defaults to the uploaded version code")
    parser.add_argument("--notes-file", help="release notes for en-US, plain text")
    parser.add_argument(
        "--status",
        default="completed",
        choices=("draft", "completed"),
        help="'draft' stages the release without rolling it out (default: completed)",
    )
    return parser.parse_args()


def load_notes(notes_file: str | None) -> list[dict[str, str]]:
    if not notes_file:
        return []
    text = Path(notes_file).read_text(encoding="utf-8").strip()
    if not text:
        return []
    return [{"language": "en-US", "text": text}]


def upload(args: argparse.Namespace) -> int:
    if not args.aab and not args.version_code:
        print("error: pass --aab to upload a bundle, or --version-code to reuse one", file=sys.stderr)
        return 1

    aab = Path(args.aab) if args.aab else None
    if aab and not aab.is_file():
        print(f"error: no such bundle: {aab}", file=sys.stderr)
        return 1

    key = Path(args.key)
    if not key.is_file():
        print(f"error: no service account key at {key}", file=sys.stderr)
        print(
            "Create one in Play Console -> Users and permissions, then save it there.",
            file=sys.stderr,
        )
        return 1

    credentials = service_account.Credentials.from_service_account_file(
        str(key), scopes=[SCOPE]
    )
    service = build(
        "androidpublisher", "v3", credentials=credentials, cache_discovery=False
    )
    edits = service.edits()

    edit_id = edits.insert(body={}, packageName=args.package).execute()["id"]
    print(f"opened edit {edit_id}")

    if aab:
        # resumable=True matters: release bundles run to tens of megabytes, and a
        # single non-resumable POST is what usually dies on a flaky uplink.
        media = MediaFileUpload(
            str(aab), mimetype="application/octet-stream", resumable=True
        )
        bundle = (
            edits.bundles()
            .upload(packageName=args.package, editId=edit_id, media_body=media)
            .execute()
        )
        version_code = bundle["versionCode"]
        print(f"uploaded {aab.name} as versionCode {version_code}")
    else:
        version_code = args.version_code
        print(f"reusing versionCode {version_code}")

    release = {
        "name": args.release_name or str(version_code),
        "versionCodes": [str(version_code)],
        "status": args.status,
    }
    notes = load_notes(args.notes_file)
    if notes:
        release["releaseNotes"] = notes

    edits.tracks().update(
        packageName=args.package,
        editId=edit_id,
        track=args.track,
        body={"track": args.track, "releases": [release]},
    ).execute()
    print(f"staged release '{release['name']}' on track '{args.track}' ({args.status})")

    edits.commit(packageName=args.package, editId=edit_id).execute()
    print("committed")
    return 0


def main() -> int:
    args = parse_args()
    try:
        return upload(args)
    except HttpError as error:
        # Play puts the useful detail in the response body, not the status line.
        print(f"error: Play API rejected the request: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
