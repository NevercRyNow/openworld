#!/usr/bin/env bash
# Builds an unsigned IPA on a Mac with Xcode + XcodeGen.
#   ./build-ipa.sh
# Output: DSH-unsigned.ipa next to this script.
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen 没有安装：brew install xcodegen" >&2
  exit 1
fi

xcodegen generate

xcodebuild \
  -project DSHPocket.xcodeproj \
  -scheme DSHPocket \
  -sdk iphoneos \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  | tee build.log

rm -rf Payload DSH-unsigned.ipa
mkdir -p Payload
cp -R build/Build/Products/Release-iphoneos/DSH.app Payload/
zip -qry DSH-unsigned.ipa Payload
shasum -a 256 DSH-unsigned.ipa | tee SHA256.txt
ls -lh DSH-unsigned.ipa
