#!/bin/bash

# Exit instantly if any command fails
set -e

echo "📲 Installing APK to the running emulator..."
# The -r flag forces an overwrite/re-install if it exists
adb install -r bin/Release/net10.0-android/android-x64/com.andydragon.feature_logging-Signed.apk

echo "🔍 Finding the exact MainActivity string..."
# Asks Android to find the exact Main launcher activity inside your installed package
ACTIVITY_PATH=$(adb shell cmd package resolve-activity --brief com.andydragon.feature_logging | tail -n 1)

if [[ -z "$ACTIVITY_PATH" || "$ACTIVITY_PATH" == *"No activity found"* ]]; then
    echo "❌ Error: Could not resolve the MainActivity layout on the emulator."
    exit 1
fi

echo "🏁 Launching resolved activity: $ACTIVITY_PATH"
# Launches the exact resolved path dynamically
adb shell am start -n "$ACTIVITY_PATH"

echo "✅ App successfully started on your Intel Mac Emulator!"
