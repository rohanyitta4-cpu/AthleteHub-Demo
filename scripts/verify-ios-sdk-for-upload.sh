#!/usr/bin/env bash
# Verify the active Xcode toolchain meets App Store Connect requirements (iOS 26 SDK / Xcode 26+).
# Run before archiving: ./scripts/verify-ios-sdk-for-upload.sh

set -euo pipefail

MIN_XCODE_MAJOR=26
MIN_IOS_SDK_MAJOR=26

echo "=== Xcode path ==="
xcode-select -p

echo ""
echo "=== Xcode version ==="
xcodebuild -version

echo ""
echo "=== iOS SDKs ==="
xcodebuild -showsdks | grep -E 'iOS|Simulator - iOS' || true

echo ""
echo "=== Flutter Xcode ==="
flutter doctor -v 2>/dev/null | sed -n '/Xcode - develop/,/^$/p' || flutter doctor -v | head -20

XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}')
XCODE_MAJOR=${XCODE_VERSION%%.*}

IOS_SDK=$(xcodebuild -showsdks 2>/dev/null | awk '/^[[:space:]]+iOS [0-9]/ {print $2; exit}')
IOS_SDK_MAJOR=${IOS_SDK%%.*}

echo ""
if [[ "$XCODE_MAJOR" -ge "$MIN_XCODE_MAJOR" && "$IOS_SDK_MAJOR" -ge "$MIN_IOS_SDK_MAJOR" ]]; then
  echo "OK: Active toolchain uses iOS ${IOS_SDK} SDK (Xcode ${XCODE_VERSION}). Safe to archive for upload."
  exit 0
fi

echo "FAIL: App Store Connect requires Xcode ${MIN_XCODE_MAJOR}+ with iOS ${MIN_IOS_SDK_MAJOR} SDK."
echo "      Active: Xcode ${XCODE_VERSION}, iOS SDK ${IOS_SDK:-unknown}"
echo ""
echo "Fix:"
echo "  1. Install Xcode 26 from the Mac App Store or https://developer.apple.com/download/"
echo "  2. sudo xcode-select -s /Applications/Xcode.app   (or path to Xcode 26)"
echo "  3. sudo xcodebuild -license accept"
echo "  4. cd ios && pod install && cd .."
echo "  5. flutter clean && flutter pub get && flutter build ipa --release"
exit 1
