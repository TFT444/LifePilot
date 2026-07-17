#!/usr/bin/env bash
# Rasterize Assets/brand/logo.svg into app icon + website favicons.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="$ROOT/Assets/brand/logo.svg"
OUT_TMP="${TMPDIR:-/tmp}/lifepilot-icon-1024.png"

if command -v cairosvg >/dev/null 2>&1; then
  cairosvg "$SVG" -o "$OUT_TMP" -W 1024 -H 1024
elif command -v rsvg-convert >/dev/null 2>&1; then
  rsvg-convert -w 1024 -h 1024 "$SVG" -o "$OUT_TMP"
else
  echo "Need cairosvg or rsvg-convert" >&2
  exit 1
fi

python3 - <<PY
from PIL import Image
import os
root = "$ROOT"
src = Image.open("$OUT_TMP").convert("RGBA").resize((1024, 1024), Image.Resampling.LANCZOS)
app = os.path.join(root, "App/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
src.save(app)
src.save(os.path.join(root, "Assets/brand/logo-1024.png"))
web = os.path.join(root, "Website/public")
for size, name in [(32, "favicon-32.png"), (16, "favicon-16.png"), (180, "apple-touch-icon.png"), (192, "icon-192.png"), (512, "icon-512.png")]:
    src.resize((size, size), Image.Resampling.LANCZOS).save(os.path.join(web, name))
src.resize((32, 32), Image.Resampling.LANCZOS).save(os.path.join(web, "favicon.ico"), format="ICO", sizes=[(16, 16), (32, 32)])
print("Wrote app icon + favicons")
PY
