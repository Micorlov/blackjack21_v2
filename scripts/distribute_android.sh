#!/usr/bin/env bash
# Build the Android release APK and push it to Firebase App Distribution testers.
#
# One-time setup (Firebase console or CLI), not done by this script:
#   firebase login
#   firebase appdistribution:group:create "Testers" testers
# then add tester emails to that group in the Firebase console
# (Project blackjack21-v2 -> App Distribution -> Testers & groups).
set -euo pipefail

cd "$(dirname "$0")/.."

APP_ID="1:445894203200:android:443961c8ebc5627a2d0ca5"
GROUP="testers"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if command -v firebase >/dev/null 2>&1; then
  FIREBASE_CMD=(firebase)
else
  FIREBASE_CMD=(npx --yes firebase-tools)
fi

flutter build apk --release

RELEASE_NOTES="$(git log -1 --pretty=%s)"

"${FIREBASE_CMD[@]}" appdistribution:distribute "$APK_PATH" \
  --app "$APP_ID" \
  --groups "$GROUP" \
  --release-notes "$RELEASE_NOTES"
