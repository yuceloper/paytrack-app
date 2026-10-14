#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET="$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset"
SOURCE_B64="$ROOT_DIR/tool/paytrack_app_icon.jpg.b64"
TMP_JPG="$(mktemp -t paytrack-app-icon).jpg"

cleanup() {
  rm -f "$TMP_JPG"
}
trap cleanup EXIT

python3 - "$SOURCE_B64" "$TMP_JPG" <<'PY'
import base64
import pathlib
import sys
src = pathlib.Path(sys.argv[1]).read_text().strip()
pathlib.Path(sys.argv[2]).write_bytes(base64.b64decode(src))
PY

make_icon() {
  local filename="$1"
  local pixels="$2"
  sips -s format png -z "$pixels" "$pixels" "$TMP_JPG" --out "$ICONSET/$filename" >/dev/null
}

make_icon "Icon-App-20x20@1x.png" 20
make_icon "Icon-App-20x20@2x.png" 40
make_icon "Icon-App-20x20@3x.png" 60
make_icon "Icon-App-29x29@1x.png" 29
make_icon "Icon-App-29x29@2x.png" 58
make_icon "Icon-App-29x29@3x.png" 87
make_icon "Icon-App-40x40@1x.png" 40
make_icon "Icon-App-40x40@2x.png" 80
make_icon "Icon-App-40x40@3x.png" 120
make_icon "Icon-App-60x60@2x.png" 120
make_icon "Icon-App-60x60@3x.png" 180
make_icon "Icon-App-76x76@1x.png" 76
make_icon "Icon-App-76x76@2x.png" 152
make_icon "Icon-App-83.5x83.5@2x.png" 167
make_icon "Icon-App-1024x1024@1x.png" 1024

echo "PayTrack iOS app icons installed in: $ICONSET"
