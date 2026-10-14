#!/bin/bash
# Fetches the Firebase Unity SDK (Auth, Firestore, Analytics, Crashlytics) and imports it into this project.
# The SDK is ~760 MB of native libraries, so it is not committed. Run once per checkout.
#
#   Unity/tools/install_firebase.sh [path/to/firebase_unity_sdk_13.17.0.zip]
set -euo pipefail

VERSION=13.17.0
SHA256=4fba6b1315eb24987dcf5a391c9f88518ea9c3c0eba6c7e45d88a991a034f7c0
URL="https://dl.google.com/firebase/sdk/unity/firebase_unity_sdk_${VERSION}.zip"
UNITY="${UNITY:-/Applications/Unity/Hub/Editor/6000.3.25f1/Unity.app/Contents/MacOS/Unity}"

HERE="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

ZIP="${1:-$WORK/firebase_unity_sdk.zip}"
if [ ! -f "$ZIP" ]; then
  echo "Downloading $URL"
  curl -fL -o "$ZIP" "$URL"
fi

echo "Verifying checksum"
echo "$SHA256  $ZIP" | shasum -a 256 -c -

echo "Extracting packages"
unzip -q -o "$ZIP" \
  "firebase_unity_sdk/FirebaseAuth.unitypackage" "firebase_unity_sdk/FirebaseFirestore.unitypackage" \
  "firebase_unity_sdk/FirebaseAnalytics.unitypackage" "firebase_unity_sdk/FirebaseCrashlytics.unitypackage" -d "$WORK/pkgs"

# The Firebase console config for the Android app (public client keys, committed with the project).
[ -f "$HERE/Assets/google-services.json" ] || { echo "Missing Unity/Assets/google-services.json"; exit 1; }

echo "Unpacking into Assets"
python3 -I "$HERE/tools/unpack_unitypackage.py" "$HERE" \
  "$WORK/pkgs/firebase_unity_sdk/FirebaseAuth.unitypackage" "$WORK/pkgs/firebase_unity_sdk/FirebaseFirestore.unitypackage" \
  "$WORK/pkgs/firebase_unity_sdk/FirebaseAnalytics.unitypackage" "$WORK/pkgs/firebase_unity_sdk/FirebaseCrashlytics.unitypackage"

echo "Configuring the project (defines FIREBASE_SDK, imports the new assets)"
"$UNITY" -batchmode -nographics -quit -projectPath "$HERE" \
  -executeMethod Blackjack.EditorTools.BuildTools.Configure -logFile "$WORK/configure.log" \
  || { tail -30 "$WORK/configure.log"; exit 1; }
echo "Firebase imported."
