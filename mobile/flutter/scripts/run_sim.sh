#!/bin/bash
# run_sim.sh — Run Flutter on iOS simulator, working around the iOS 26+
# WidgetKit-extension install daemon bug ("Invalid placeholder attributes").
#
# Background: iOS 26.x simulator's install daemon rejects Live Activity
# .appex bundles with "Failed to create app extension placeholder" even
# when the bundle is structurally valid. The extension installs fine on
# physical devices and was working on earlier iOS simulators.
#
# This wrapper:
#   1. Runs `flutter build ios --simulator --debug` to produce Runner.app
#   2. Strips PlugIns/FitWizLiveActivityExtension.appex (sim-only workaround)
#   3. Installs the slimmed Runner.app on the booted simulator
#   4. Launches the app and attaches Flutter's hot-reload session
#
# Use for simulator development. Physical devices and TestFlight/App Store
# builds use the normal `flutter run` / `flutter build ipa` and include the
# extension correctly.
set -e

cd "$(dirname "$0")/.."

# Resolve booted simulator (or first available iPhone)
DEVICE_ID=$(xcrun simctl list devices booted | grep -E "iPhone" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')
if [ -z "$DEVICE_ID" ]; then
  DEVICE_ID=$(xcrun simctl list devices available | grep -E "iPhone 1[5-7]" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')
  if [ -z "$DEVICE_ID" ]; then
    echo "❌ No iPhone simulator available." >&2
    exit 1
  fi
  echo "ℹ️  Booting simulator $DEVICE_ID"
  xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
  open -a Simulator
  sleep 3
fi
echo "📱 Using simulator: $DEVICE_ID"

# Build for simulator (debug)
echo "🔨 Building Flutter app for simulator..."
/opt/homebrew/Caskroom/flutter/3.38.3/flutter/bin/flutter build ios --simulator --debug --no-codesign

APP_PATH="build/ios/iphonesimulator/Runner.app"
EXT_PATH="$APP_PATH/PlugIns/FitWizLiveActivityExtension.appex"

# Strip the Live Activity extension only for simulator install (iOS 26 bug)
if [ -d "$EXT_PATH" ]; then
  echo "✂️  Stripping FitWizLiveActivityExtension.appex (iOS 26 sim workaround)"
  rm -rf "$EXT_PATH"
fi

# Uninstall any previous copy then install
echo "📦 Installing app on simulator..."
xcrun simctl uninstall "$DEVICE_ID" com.aifitnesscoach.app 2>/dev/null || true
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

# Launch
echo "🚀 Launching app..."
xcrun simctl launch "$DEVICE_ID" com.aifitnesscoach.app

echo ""
echo "✅ App is running on simulator $DEVICE_ID"
echo ""
echo "ℹ️  For hot-reload, attach via:"
echo "    flutter attach -d $DEVICE_ID"
