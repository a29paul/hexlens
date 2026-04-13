#!/bin/bash
# Usage: ./scripts/generate-icons.sh path/to/icon-1024.png
#
# Generates all macOS app icon sizes + web favicons from a single 1024x1024 PNG.
# Requires: sips (built into macOS)

set -e

INPUT="$1"
if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  echo "Usage: $0 <path-to-1024x1024.png>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SCRIPT_DIR/.."

APP_ICON_DIR="$ROOT/desktop/Resources/Assets.xcassets/AppIcon.appiconset"
WEB_ICON_DIR="$ROOT/web/public/icons"

echo "Generating macOS app icons..."
for SIZE in 16 32 64 128 256 512 1024; do
  sips -z $SIZE $SIZE "$INPUT" --out "$APP_ICON_DIR/icon-${SIZE}.png" >/dev/null 2>&1
  echo "  ✓ icon-${SIZE}.png"
done

echo ""
echo "Generating web icons..."
# Favicon
sips -z 32 32 "$INPUT" --out "$WEB_ICON_DIR/favicon-32.png" >/dev/null 2>&1
echo "  ✓ favicon-32.png"

# Apple touch icon
sips -z 180 180 "$INPUT" --out "$WEB_ICON_DIR/apple-touch-icon.png" >/dev/null 2>&1
echo "  ✓ apple-touch-icon.png"

# Web manifest icons
sips -z 192 192 "$INPUT" --out "$WEB_ICON_DIR/icon-192.png" >/dev/null 2>&1
echo "  ✓ icon-192.png"

sips -z 512 512 "$INPUT" --out "$WEB_ICON_DIR/icon-512.png" >/dev/null 2>&1
echo "  ✓ icon-512.png"

# OG image (copy 512 for social sharing)
cp "$WEB_ICON_DIR/icon-512.png" "$ROOT/web/public/og-image.png"
echo "  ✓ og-image.png"

echo ""
echo "Done. Drop your 1024x1024 PNG and run:"
echo "  ./scripts/generate-icons.sh your-icon.png"
echo ""
echo "Files written:"
echo "  desktop/Resources/Assets.xcassets/AppIcon.appiconset/icon-*.png"
echo "  web/public/icons/*"
echo "  web/public/og-image.png"
