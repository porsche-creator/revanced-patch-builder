#!/bin/bash
set -e

mkdir -p build tools stock

echo "=== 1. Download latest Morphe CLI & Patches ==="

# Get latest CLI
CLI_URL=$(curl -sL https://api.github.com/repos/MorpheApp/morphe-cli/releases/latest \
  | grep -o 'https://[^"]*all\.jar' | head -1)

# Get latest patches (.mpp)
PATCHES_URL=$(curl -sL https://api.github.com/repos/MorpheApp/morphe-patches/releases/latest \
  | grep -o 'https://[^"]*\.mpp' | head -1)

echo "CLI:      $CLI_URL"
echo "Patches:  $PATCHES_URL"

curl -L "$CLI_URL" -o tools/cli.jar
curl -L "$PATCHES_URL" -o tools/patches.mpp

echo "=== 2. Download stock APKs ==="

# ---------- YouTube ----------
# Using a reliable community archive (change version if needed)
YT_VERSION="21.30.216"
curl -L "https://archive.org/download/jhc-apks/apks/com.google.android.youtube/${YT_VERSION}/com.google.android.youtube_${YT_VERSION}-nodpi.apk" \
  -o stock/youtube.apk || echo "YouTube download failed"

# ---------- YouTube Music ----------
YTM_VERSION="9.30.53"
curl -L "https://archive.org/download/jhc-apks/apks/com.google.android.apps.youtube.music/${YTM_VERSION}/com.google.android.apps.youtube.music_${YTM_VERSION}-arm64-v8a.apk" \
  -o stock/youtube-music.apk || echo "YouTube Music download failed"

# ---------- Reddit ----------
# You can add more sources later
# curl -L "..." -o stock/reddit.apk

echo "=== 3. Patch apps ==="

patch_app() {
  local input=$1
  local output=$2
  local name=$3

  if [ ! -f "$input" ]; then
    echo "Skipping $name (stock APK missing)"
    return
  fi

  echo "Patching $name..."
  java -jar tools/cli.jar patch \
    -p tools/patches.mpp \
    -o "build/$output" \
    "$input" || echo "Failed to patch $name"
}

patch_app "stock/youtube.apk"        "YouTube-Morphe.apk"        "YouTube"
patch_app "stock/youtube-music.apk"  "YouTube-Music-Morphe.apk"  "YouTube Music"
# patch_app "stock/reddit.apk"       "Reddit-Morphe.apk"         "Reddit"

echo "=== Done ==="
ls -lh build/
