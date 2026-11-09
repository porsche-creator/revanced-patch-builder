#!/bin/bash
set -e

mkdir -p build tools stock

echo "=== Configuration ==="
echo "Patch source: $PATCH_SOURCE"
echo "Apps: $APPS"
echo "Custom repo: $CUSTOM_PATCHES_REPO"

# ---------- Download CLI ----------
echo "=== Downloading Morphe CLI ==="
CLI_URL=$(curl -sL https://api.github.com/repos/MorpheApp/morphe-cli/releases/latest \
  | grep -o 'https://[^"]*all\.jar' | head -1)
curl -L "$CLI_URL" -o tools/cli.jar

# ---------- Download Patches ----------
echo "=== Downloading Patches ==="

if [ "$PATCH_SOURCE" = "anddea" ]; then
  PATCHES_URL=$(curl -sL https://api.github.com/repos/anddea/revanced-patches/releases/latest \
    | grep -o 'https://[^"]*\.mpp' | head -1)
elif [ "$PATCH_SOURCE" = "custom" ] && [ -n "$CUSTOM_PATCHES_REPO" ]; then
  PATCHES_URL=$(curl -sL https://api.github.com/repos/$CUSTOM_PATCHES_REPO/releases/latest \
    | grep -o 'https://[^"]*\.mpp' | head -1)
else
  # default = base (Morphe)
  PATCHES_URL=$(curl -sL https://api.github.com/repos/MorpheApp/morphe-patches/releases/latest \
    | grep -o 'https://[^"]*\.mpp' | head -1)
fi

echo "Using patches: $PATCHES_URL"
curl -L "$PATCHES_URL" -o tools/patches.mpp

# ---------- Download + Patch function ----------
patch_app() {
  local name=$1
  local stock_path=$2
  local output_name=$3
  local download_url=$4

  if [[ "$APPS" != *"$name"* ]]; then
    echo "Skipping $name (not selected)"
    return
  fi

  echo "=== Processing $name ==="
  
  if [ ! -f "$stock_path" ]; then
    echo "Downloading stock APK..."
    curl -L "$download_url" -o "$stock_path" || {
      echo "Failed to download $name"
      return
    }
  fi

  echo "Patching $name..."
  java -jar tools/cli.jar patch \
    -p tools/patches.mpp \
    -o "build/$output_name" \
    "$stock_path" || echo "Patching $name failed"
}

# ---------- Apps ----------
# You can update the versions/links when needed
patch_app "youtube" \
  "stock/youtube.apk" \
  "YouTube.apk" \
  "https://archive.org/download/jhc-apks/apks/com.google.android.youtube/21.30.216/com.google.android.youtube_21.30.216-nodpi.apk"

patch_app "youtube-music" \
  "stock/youtube-music.apk" \
  "YouTube-Music.apk" \
  "https://archive.org/download/jhc-apks/apks/com.google.android.apps.youtube.music/9.30.53/com.google.android.apps.youtube.music_9.30.53-arm64-v8a.apk"

# Add more apps here later (reddit, etc.)

echo "=== Build finished ==="
ls -lh build/ || true
