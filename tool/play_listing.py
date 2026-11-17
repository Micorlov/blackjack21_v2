#!/usr/bin/env python3
"""Set the en-US store listing text (title, short and full description) through the Play API.

    python3 tool/play_listing.py --key ~/.config/play/key.json [--file tool/listing_en-US.json]

Only en-US is touched. Limits are checked first (title 30, short 80, full 4000).
"""
import argparse
import json
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build

PACKAGE = "com.micorlov.blackjack21_v2"
LIMITS = {"title": 30, "shortDescription": 80, "fullDescription": 4000}

ap = argparse.ArgumentParser()
ap.add_argument("--key", required=True)
ap.add_argument("--file", default=str(Path(__file__).with_name("listing_en-US.json")))
ap.add_argument("--package", default=PACKAGE)
args = ap.parse_args()

body = json.loads(Path(args.file).read_text(encoding="utf-8"))
for field, limit in LIMITS.items():
    assert len(body[field]) <= limit, f"{field} is {len(body[field])} chars, limit {limit}"

creds = service_account.Credentials.from_service_account_file(
    str(Path(args.key).expanduser()), scopes=["https://www.googleapis.com/auth/androidpublisher"])
api = build("androidpublisher", "v3", credentials=creds, cache_discovery=False).edits()
edit = api.insert(packageName=args.package, body={}).execute()
api.listings().update(packageName=args.package, editId=edit["id"], language="en-US",
                      body={"language": "en-US", **body}).execute()
api.commit(packageName=args.package, editId=edit["id"]).execute()
print("en-US listing updated")
