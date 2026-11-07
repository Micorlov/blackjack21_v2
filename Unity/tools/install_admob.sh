#!/bin/bash
# Fetches the Google Mobile Ads Unity plugin and imports it into this project. Not committed, like Firebase.
# Run once per checkout, after tools/install_firebase.sh (the plugin uses the dependency manager Firebase bundles).
#
#   Unity/tools/install_admob.sh [path/to/GoogleMobileAds-v11.6.0.unitypackage]
set -euo pipefail

VERSION=11.6.0
SHA256=e42c4af9284a6efa3e925ecb58047b722e07c12ac28dceb4547bb743f3db4763
URL="https://github.com/googleads/googleads-mobile-unity/releases/download/v${VERSION}/GoogleMobileAds-v${VERSION}.unitypackage"
UNITY="${UNITY:-/Applications/Unity/Hub/Editor/6000.3.25f1/Unity.app/Contents/MacOS/Unity}"

HERE="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PACKAGE="${1:-$WORK/GoogleMobileAds.unitypackage}"
if [ ! -f "$PACKAGE" ]; then
  echo "Downloading $URL"
  curl -fL -o "$PACKAGE" "$URL"
fi

echo "Verifying checksum"
echo "$SHA256  $PACKAGE" | shasum -a 256 -c -

echo "Unpacking into Assets"
python3 -I "$HERE/tools/unpack_unitypackage.py" "$HERE" "$PACKAGE"

echo "Configuring the project (defines ADMOB_SDK, imports the new assets)"
"$UNITY" -batchmode -nographics -quit -projectPath "$HERE" \
  -executeMethod Blackjack.EditorTools.BuildTools.Configure -logFile "$WORK/configure.log" \
  || { tail -30 "$WORK/configure.log"; exit 1; }
echo "Google Mobile Ads imported."
