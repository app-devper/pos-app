#!/usr/bin/env bash
# Runs the Maestro flows on the web (headless) and on the Android emulator at
# the same time, once each. Each platform has its own local stack (see
# maestro.sh), so neither sees the other's bills or customers.
#
#   maestro-all.sh [<flow>|all]
#
# The two apps are built one after the other first (two Flutter builds at once
# fight over the same build folders); the flows then run side by side on those
# builds. E2E_MAESTRO_REUSE_BUILD=1 skips a build whose artefact exists.
# Exit 0 only when both platforms passed.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNNER="$SCRIPT_DIR/maestro.sh"
OUT_ROOT="${TMPDIR:-/tmp}"
OUT_ROOT="${OUT_ROOT%/}/pos-e2e-maestro"

usage() { echo "usage: $0 [<flow>|all]" >&2; exit 2; }
[ "$#" -le 1 ] || usage
flow="${1:-all}"
case "$flow" in -*) usage ;; esac

mkdir -p "$OUT_ROOT"
started="$(date +%s)"

if [ "${E2E_MAESTRO_SKIP_SETUP:-0}" != 1 ]; then   # the self-test runs without builds
  for kind in apk web; do
    if [ "${E2E_MAESTRO_REUSE_BUILD:-0}" = 1 ] && [ -e "$("$SCRIPT_DIR/maestro-build.sh" path "$kind")" ]; then continue; fi
    echo "maestro-all.sh: building the $kind"
    "$SCRIPT_DIR/maestro-build.sh" "$kind" > "$OUT_ROOT/build-$kind.log" 2>&1 \
      || { tail -30 "$OUT_ROOT/build-$kind.log" >&2; echo "maestro-all.sh: the $kind build failed (log: $OUT_ROOT/build-$kind.log)" >&2; exit 1; }
  done
fi

web_pid=""; android_pid=""
stop_children() {
  for pid in $web_pid $android_pid; do kill "$pid" 2>/dev/null || true; done
  wait 2>/dev/null || true   # each runner stops what it started
}
trap 'stop_children; exit 130' INT TERM

E2E_MAESTRO_REUSE_BUILD=1 "$RUNNER" web "$flow" --headless > "$OUT_ROOT/all-web.log" 2>&1 &
web_pid=$!
E2E_MAESTRO_REUSE_BUILD=1 "$RUNNER" android "$flow" > "$OUT_ROOT/all-android.log" 2>&1 &
android_pid=$!

web_code=0; android_code=0
wait "$web_pid" || web_code=$?
wait "$android_pid" || android_code=$?

for platform in web android; do
  echo "== $platform"
  cat "$OUT_ROOT/all-$platform.log"
done
echo "maestro-all.sh: web exit $web_code, android exit $android_code, $(( $(date +%s) - started ))s in all"
[ "$web_code" -eq 0 ] && [ "$android_code" -eq 0 ]
