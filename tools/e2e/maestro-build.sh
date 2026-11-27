#!/usr/bin/env bash
# Builds the POS app the Maestro flows drive, pointed at the local stack
# (config/e2e-local.json). Prints the artefact's path on the last line.
#
#   maestro-build.sh apk        debug APK for the emulator
#   maestro-build.sh web        web build with the semantics tree switched on
#                               (Maestro sees nothing of a Flutter web page without it)
#   maestro-build.sh path apk|web   where that artefact is kept, without building
#
# Both artefacts live in places only this script writes. The APK is copied out
# of Gradle's output directory, where any `flutter build apk` or `flutter run`
# leaves a file of the same name that may point at a deployed API.
#
# The APK is built by calling Gradle with a JDK 17: `flutter build apk` picks
# Android Studio's bundled Java, which this project's Gradle cannot run on.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../../packages/applications/pos" && pwd)"
WEB_OUT="$APP_DIR/build/web-maestro"
GRADLE_APK="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"
APK_OUT="$APP_DIR/build/maestro/app-debug.apk"

die() { printf 'maestro-build: %s\n' "$*" >&2; exit 1; }
usage() { echo "usage: $0 apk|web|path apk|path web" >&2; exit 2; }

build_apk() {
  local jdk defines
  jdk="${E2E_JDK17_HOME:-$(/usr/libexec/java_home -v 17 2>/dev/null || true)}"
  [ -n "$jdk" ] && [ -x "$jdk/bin/java" ] \
    || die "no JDK 17 found (/usr/libexec/java_home -v 17); install one or set E2E_JDK17_HOME"
  defines="$(printf 'ENV=e2e-local' | base64)"
  (cd "$APP_DIR" && fvm flutter pub get >/dev/null)
  (cd "$APP_DIR/android" && JAVA_HOME="$jdk" ./gradlew --quiet app:assembleDebug \
    "-Pdart-defines=$defines" -Ptarget-platform=android-arm64) >&2
  [ -f "$GRADLE_APK" ] || die "the build left no $GRADLE_APK"
  mkdir -p "$(dirname "$APK_OUT")"
  cp "$GRADLE_APK" "$APK_OUT"
  printf '%s\n' "$APK_OUT"
}

build_web() {
  (cd "$APP_DIR" && fvm flutter build web --no-web-resources-cdn \
    --dart-define=ENV=e2e-local --dart-define=E2E_SEMANTICS=true -o "$WEB_OUT") >&2
  [ -f "$WEB_OUT/index.html" ] || die "the build left no $WEB_OUT/index.html"
  printf '%s\n' "$WEB_OUT"
}

case "$#:${1:-}:${2:-}" in
  1:apk:) build_apk ;;
  1:web:) build_web ;;
  2:path:apk) printf '%s\n' "$APK_OUT" ;;
  2:path:web) printf '%s\n' "$WEB_OUT" ;;
  *) usage ;;
esac
