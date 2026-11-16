#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required: brew install xcodegen"
  exit 1
fi

xcodegen generate
xcodebuild \
  -project OpenWorld.xcodeproj \
  -scheme OpenWorld \
  -sdk iphoneos \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

mkdir -p Payload
rm -rf Payload/OpenWorld.app
cp -R build/Build/Products/Release-iphoneos/OpenWorld.app Payload/
rm -f OpenWorld-unsigned.ipa
zip -qry OpenWorld-unsigned.ipa Payload
shasum -a 256 OpenWorld-unsigned.ipa
