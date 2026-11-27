#!/bin/bash
# Renders one app's launcher and web icons from tools/icons/<app>/mark.svg.inc on
# the colour in tools/icons/<app>/brand.
# macOS only: uses QuickLook (qlmanage) to rasterise the SVG, sips to resize and
# python3 (standard library) to give the launcher shapes their clear pixels.
# Downloads nothing. Run from anywhere: tools/icons/make-icons.sh <pos|sm>
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
NAME="${1:-}"
[ -n "$NAME" ] && [ -f "$HERE/$NAME/mark.svg.inc" ] && [ -f "$HERE/$NAME/brand" ] || {
  echo "usage: make-icons.sh <app>   (an app with tools/icons/<app>/mark.svg.inc and brand)" >&2; exit 2; }
APP="$HERE/../../packages/applications/$NAME"
RES="$APP/android/app/src/main/res"
BRAND="$(tr -d '[:space:]' < "$HERE/$NAME/brand")"
MASTER_PX=1024
MARK="$(cat "$HERE/$NAME/mark.svg.inc")"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

svg() { # svg <name> <body>: an opaque image (the body fills the square)
  printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96" width="%s" height="%s">%s</svg>' \
    "$MASTER_PX" "$MASTER_PX" "$2" > "$WORK/$1.svg"
  qlmanage -t -s "$MASTER_PX" -o "$WORK" "$WORK/$1.svg" >/dev/null 2>&1
  [ -f "$WORK/$1.svg.png" ] || { echo "make-icons: could not render $1" >&2; exit 1; }
}
# QuickLook paints white wherever an SVG is transparent. A shape that needs
# clear pixels is rendered on black and on white, and png_alpha.py recovers the
# alpha channel from the two.
svg_clear() { # svg_clear <name> <body>
  svg "$1-on-black" "<rect width=\"96\" height=\"96\" fill=\"#000000\"/>$2"
  svg "$1-on-white" "<rect width=\"96\" height=\"96\" fill=\"#ffffff\"/>$2"
  python3 "$HERE/png_alpha.py" matte "$WORK/$1-on-black.svg.png" "$WORK/$1-on-white.svg.png" "$WORK/$1.svg.png"
}
png() { # png <master> <px> <target>
  mkdir -p "$(dirname "$3")"
  sips -z "$2" "$2" "$WORK/$1.svg.png" --out "$3" >/dev/null
}

# The mark is drawn for a 96 box with its optical centre at y=52.5.
# rounded: launcher shape with clear corners. maskable: full bleed, mark inside the
# central 80%. foreground: Android adaptive layer, mark inside the central 66/108.
svg_clear rounded    "<rect width=\"96\" height=\"96\" rx=\"21\" fill=\"$BRAND\"/><g transform=\"translate(0 -4.5)\">$MARK</g>"
svg maskable   "<rect width=\"96\" height=\"96\" fill=\"$BRAND\"/><g transform=\"translate(48 48) scale(0.8) translate(-48 -52.5)\">$MARK</g>"
svg_clear foreground "<g transform=\"translate(48 48) scale(0.58) translate(-48 -52.5)\">$MARK</g>"

for spec in mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432; do
  IFS=: read -r density legacy adaptive <<<"$spec"
  png rounded    "$legacy"   "$RES/mipmap-$density/ic_launcher.png"
  png foreground "$adaptive" "$RES/mipmap-$density/ic_launcher_foreground.png"
done

# the adaptive icon and its background colour, so the colour has one source (brand)
mkdir -p "$RES/mipmap-anydpi-v26"
cat > "$RES/mipmap-anydpi-v26/ic_launcher.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
XML
cat > "$RES/values/ic_launcher_background.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">$BRAND</color>
</resources>
XML

# The launch screen's mark on its brand disc, 108 dp across, drawn on the
# launch surface of each mode (values[-night]/launch_colors.xml): QuickLook
# paints what an SVG leaves transparent white, so the image carries its own
# surround instead of relying on transparency. Apps without a launch
# surface (sm) have no launch mark.
launch_surface() { # launch_surface <values dir>
  sed -nE 's/.*<color name="launch_surface">(#[0-9A-Fa-f]{6})<.*/\1/p' "$RES/$1/launch_colors.xml"
}
if [ -f "$RES/values/launch_colors.xml" ]; then
  for mode in values:drawable values-night:drawable-night; do
    IFS=: read -r values drawable <<<"$mode"
    SURFACE="$(launch_surface "$values")"
    [ -n "$SURFACE" ] || { echo "make-icons: no launch_surface in $values" >&2; exit 1; }
    svg "launch-$values" "<rect width=\"96\" height=\"96\" fill=\"$SURFACE\"/><circle cx=\"48\" cy=\"48\" r=\"48\" fill=\"$BRAND\"/><g transform=\"translate(48 48) scale(0.58) translate(-48 -52.5)\">$MARK</g>"
    for spec in mdpi:108 hdpi:162 xhdpi:216 xxhdpi:324 xxxhdpi:432; do
      IFS=: read -r density px <<<"$spec"
      png "launch-$values" "$px" "$RES/$drawable-$density/launch_mark.png"
    done
  done
fi

png rounded  192 "$APP/web/icons/Icon-192.png"
png rounded  512 "$APP/web/icons/Icon-512.png"
png maskable 192 "$APP/web/icons/Icon-maskable-192.png"
png maskable 512 "$APP/web/icons/Icon-maskable-512.png"
png rounded  32  "$APP/web/favicon.png"
echo "make-icons: wrote $NAME Android mipmaps and web icons"
