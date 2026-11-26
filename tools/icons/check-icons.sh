#!/bin/bash
# Checks that every icon an app references exists at the size its slot needs.
# Reads only; run after tools/icons/make-icons.sh <app>. Exit 0 = all good.
# Usage: tools/icons/check-icons.sh <pos|sm>
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
NAME="${1:-}"
[ -n "$NAME" ] && [ -d "$HERE/../../packages/applications/$NAME" ] || { echo "usage: check-icons.sh <app>" >&2; exit 2; }
APP="$HERE/../../packages/applications/$NAME"
RES="$APP/android/app/src/main/res"
failures=0

fail() { echo "FAIL $1"; failures=$((failures + 1)); }
width() { sips -g pixelWidth "$1" 2>/dev/null | awk '/pixelWidth/ {print $2}'; }
expect_px() { # expect_px <file> <px>
  [ -f "$1" ] || { fail "missing ${1#"$APP"/}"; return; }
  local w; w="$(width "$1")"
  [ "$w" = "$2" ] || fail "${1#"$APP"/} is ${w}px, expected $2"
}

for spec in mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432; do
  IFS=: read -r density legacy adaptive <<<"$spec"
  expect_px "$RES/mipmap-$density/ic_launcher.png" "$legacy"
  expect_px "$RES/mipmap-$density/ic_launcher_foreground.png" "$adaptive"
done
expect_px "$APP/web/favicon.png" 32

# every icon the web manifest names exists at the size it declares
while IFS=' ' read -r src size; do
  expect_px "$APP/web/$src" "${size%%x*}"
done < <(python3 -c '
import json, sys
for icon in json.load(open(sys.argv[1]))["icons"]:
    print(icon["src"], icon["sizes"])' "$APP/web/manifest.json")
grep -q '"purpose": "maskable"' "$APP/web/manifest.json" || fail "manifest has no maskable icon"

# every href icon in index.html exists
for href in $(grep -oE '<link rel="(icon|apple-touch-icon)"[^>]*href="[^"]+"' "$APP/web/index.html" | sed -E 's/.*href="([^"]+)"/\1/'); do
  [ -f "$APP/web/$href" ] || fail "index.html names $href, which is missing"
done

# the adaptive icon's drawables resolve
ADAPTIVE="$RES/mipmap-anydpi-v26/ic_launcher.xml"
[ -f "$ADAPTIVE" ] || fail "missing mipmap-anydpi-v26/ic_launcher.xml"
BRAND="$(tr -d '[:space:]' < "$HERE/$NAME/brand" 2>/dev/null)"
grep -qi "name=\"ic_launcher_background\">$BRAND<" "$RES/values/ic_launcher_background.xml" 2>/dev/null \
  || fail "values/ic_launcher_background.xml does not set ic_launcher_background to ${BRAND:-the brand colour}"
grep -qi "\"theme_color\": \"$BRAND\"" "$APP/web/manifest.json" || fail "manifest theme_color is not ${BRAND:-the brand colour}"

# the Flutter template icon is gone (its 512 px web icon is this exact size)
TEMPLATE_512_BYTES=8252
[ "$(wc -c < "$APP/web/icons/Icon-512.png" | tr -d ' ')" != "$TEMPLATE_512_BYTES" ] || fail "web/icons/Icon-512.png is still the Flutter template icon"

[ "$failures" -eq 0 ] && echo "check-icons: $NAME all good" || { echo "check-icons: $NAME $failures failure(s)"; exit 1; }
