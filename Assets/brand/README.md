# LifePilot Brand Assets

This directory is the single source of truth for the LifePilot mark. Every icon, favicon, and app-store asset should be generated from `logo.svg` — never redrawn from scratch.

## Files

| File | Description |
|---|---|
| `logo.svg` | Primary lockup — mark on the dark background. Source of truth for all derived assets. |
| `logo-1024.png` | 1024×1024 raster export for app icon / marketing. |

## Usage

- **README / GitHub:** referenced directly as `Assets/brand/logo.svg`.
- **App icon:** `App/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` (single-size iOS 17+ asset).
- **Website:** `Website/public/logo.svg` plus `favicon.ico`, `favicon-32.png`, `apple-touch-icon.png`.

## Regenerating rasters

```sh
./scripts/generate-brand-icons.sh
```

Requires `cairosvg` or `rsvg-convert`, and Pillow (`pip install cairosvg pillow`).
