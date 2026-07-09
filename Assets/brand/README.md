# LifePilot Brand Assets

This directory is the single source of truth for the LifePilot mark. Every icon, favicon, and app-store asset should be generated from `logo.svg` — never redrawn from scratch.

## Files

| File | Description |
|---|---|
| `logo.svg` | Primary lockup — mark, wordmark, and tagline, on the dark background. Source of truth for all derived assets. |

## Usage

- **README / GitHub:** referenced directly as `Assets/brand/logo.svg`.
- **App icon:** `App/Assets.xcassets/AppIcon.appiconset` should contain PNG exports of the mark (no wordmark, no tagline) at the sizes Apple requires. Not yet generated — see below.
- **Website:** `Website/public/logo.svg` mirrors this file for the marketing site header and favicon.

## Generating raster exports

No PNG/ICO variants are committed yet — this machine has no SVG rasterizer (`rsvg-convert`, `inkscape`, or ImageMagick) installed. To produce the app icon set and favicons, run the source SVG through one of these and export the standard Apple icon sizes (20–1024pt @1x/2x/3x) plus `favicon.ico` / `favicon.png` for the web:

```sh
# example, once a rasterizer is available
rsvg-convert -w 1024 -h 1024 logo.svg -o logo-1024.png
```

Until then, the mark ships as SVG only, which renders natively on GitHub and in any modern browser.
