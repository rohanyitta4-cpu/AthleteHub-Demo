#!/usr/bin/env bash
# Run the app on iOS simulator. First build compiles 70+ targets (Firebase, etc.) and can take 10–15 min.
# Use --verbose to see detailed progress, or open ios/Runner.xcworkspace in Xcode and press Cmd+R.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
flutter run -d "iPhone 16 Plus" "$@"
