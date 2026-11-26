#!/usr/bin/env bash
# Runs the POS app's Maestro flows against the LOCAL test stack, on the
# Android emulator or in a browser.
#
#   maestro.sh <android|web> [<flow>|all] [--headless]
#
#   maestro.sh android all            every flow on the emulator
#   maestro.sh web sell_and_bill      one flow in a browser window
#   maestro.sh web all --headless     every flow, no window (1400x900)
#
# It starts the local stack, builds and installs (or serves) the app, gives
# each flow a product of its own, and stops what it started. There is no way
# to name another target: the app is built from config/e2e-local.json, which
# must point at 127.0.0.1.
#
# The flows have a database of their own (state in ${TMPDIR}/pos-e2e-maestro-stack),
# not the Dart suite's, which is crowded on purpose: Maestro cannot pick one
# product out of a plain dropdown of hundreds. Both stacks use the same ports,
# so only one runs at a time. Maestro's output (it holds typed text) goes to
# ${TMPDIR}/pos-e2e-maestro, never into the repository.
#
# Environment: E2E_AVD (emulator name, default Medium_Phone);
# E2E_MAESTRO_REUSE_BUILD=1 skips the build when the artefact exists.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../../packages/applications/pos" && pwd)"
FLOWS_DIR="$APP_DIR/maestro"
CONFIG="${E2E_MAESTRO_CONFIG:-$APP_DIR/config/e2e-local.json}"
ENV_FILE="${E2E_MAESTRO_ENV_FILE:-$APP_DIR/.env.e2e.local}"
MAESTRO="${MAESTRO_BIN:-maestro}"
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="$SDK/platform-tools/adb"
AVD="${E2E_AVD:-Medium_Phone}"
APP_ID=app.devper.pos
WEB_PORT=8090
OUT_ROOT="${TMPDIR:-/tmp}"
OUT_ROOT="${OUT_ROOT%/}/pos-e2e-maestro"
BOOT_TIMEOUT_SEC=240
TMP_ROOT="${TMPDIR:-/tmp}"
export E2E_STACK_STATE="${E2E_MAESTRO_STACK_STATE:-${TMP_ROOT%/}/pos-e2e-maestro-stack}"
ALL_FLOWS="auth navigation sell_and_bill customer receive_stock product_edit stock_adjust stock_count product_add_delete bill_cancel_return roles"

log() { printf 'maestro.sh: %s\n' "$*"; }
die() { printf 'maestro.sh: %s\n' "$*" >&2; exit 1; }
usage() { echo "usage: $0 <android|web> [<flow>|all] [--headless]" >&2; exit 2; }

platform=""; flow="all"; headless=0
for arg in "$@"; do
  case "$arg" in
    android|web) [ -z "$platform" ] || usage; platform="$arg" ;;
    --headless) headless=1 ;;
    -*) usage ;;
    *) [ -n "$platform" ] || usage; flow="$arg" ;;
  esac
done
[ -n "$platform" ] || usage

refuse() { printf 'maestro.sh: %s\n' "$*" >&2; exit 2; }

# The local-only guard: both API addresses in the app's build config.
grep -q '"apiUrl": *"http://127\.0\.0\.1:8585"' "$CONFIG" 2>/dev/null \
  && grep -q '"hostApp": *"http://127\.0\.0\.1:8586"' "$CONFIG" \
  || refuse "$CONFIG does not point at the local stack (127.0.0.1:8585 and :8586); refusing to run"

if [ "$flow" = all ]; then
  flows=""
  for f in $ALL_FLOWS; do [ -f "$FLOWS_DIR/$platform/$f.yaml" ] && flows="$flows $f"; done
  [ -n "$flows" ] || refuse "no such flow: nothing under $FLOWS_DIR/$platform"
else
  [ -f "$FLOWS_DIR/$platform/$flow.yaml" ] || refuse "no such flow: $FLOWS_DIR/$platform/$flow.yaml"
  flows="$flow"
fi

export MAESTRO_CLI_NO_ANALYTICS=1
export MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true
export MAESTRO_DISABLE_UPDATE_CHECK=true
export SE_OFFLINE=true   # Selenium Manager uses the browser it already has; it downloads nothing

# The seeded local accounts reach the flows as MAESTRO_* variables, which
# Maestro hands to a flow by name; they are never on a command line.
value_of() { sed -n "s/^$1=//p" "$ENV_FILE" | head -1; }
load_accounts() {
  [ -f "$ENV_FILE" ] || die "$ENV_FILE is missing; it is written by the first run of this script, when it starts the local stack"
  local role key
  for role in ADMIN MANAGER USER; do
    for key in USERNAME PASSWORD; do
      [ -n "$(value_of "E2E_${role}_${key}")" ] || die "E2E_${role}_${key} is missing from $ENV_FILE"
    done
  done
  MAESTRO_USERNAME="$(value_of E2E_ADMIN_USERNAME)"; MAESTRO_PASSWORD="$(value_of E2E_ADMIN_PASSWORD)"
  MAESTRO_MANAGER_USERNAME="$(value_of E2E_MANAGER_USERNAME)"; MAESTRO_MANAGER_PASSWORD="$(value_of E2E_MANAGER_PASSWORD)"
  MAESTRO_USER_USERNAME="$(value_of E2E_USER_USERNAME)"; MAESTRO_USER_PASSWORD="$(value_of E2E_USER_PASSWORD)"
  export MAESTRO_USERNAME MAESTRO_PASSWORD MAESTRO_MANAGER_USERNAME MAESTRO_MANAGER_PASSWORD \
    MAESTRO_USER_USERNAME MAESTRO_USER_PASSWORD
}

started_emulator=0; emulator_pid=""; started_stack=0; server_pid=""; device=""; data_run_id=""

cleanup() {
  [ -z "$data_run_id" ] || "$SCRIPT_DIR/maestro-data.sh" down "$data_run_id" >/dev/null 2>&1 || true
  if [ -n "$server_pid" ]; then kill "$server_pid" 2>/dev/null || true; fi
  if [ "$started_stack" -eq 1 ]; then "$SCRIPT_DIR/local-stack.sh" stop >/dev/null 2>&1 || true; fi
  if [ "$started_emulator" -eq 1 ]; then
    [ -z "$device" ] || "$ADB" -s "$device" emu kill >/dev/null 2>&1 || true
    # Gone from adb before we return, so a run started next does not adopt a dying emulator.
    for _ in $(seq 1 30); do [ -n "$(running_emulator)" ] || break; sleep 1; done
    # One that never finished booting has no adb name: stop it by its process.
    if [ -n "$emulator_pid" ]; then kill "$emulator_pid" 2>/dev/null || true; fi
    log "stopped the emulator this run started"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM

running_emulator() { "$ADB" devices | awk '$1 ~ /^emulator-/ && $2 == "device" {print $1; exit}'; }

start_emulator() {
  local waited=0
  device="$(running_emulator)"
  if [ -z "$device" ]; then
    [ -x "$SDK/emulator/emulator" ] || die "no emulator at $SDK/emulator/emulator (set ANDROID_HOME)"
    "$SDK/emulator/emulator" -list-avds 2>/dev/null | grep -qx "$AVD" \
      || die "no emulator named $AVD (set E2E_AVD to one of: $("$SDK/emulator/emulator" -list-avds 2>/dev/null | tr '\n' ' '))"
    log "starting the emulator $AVD"
    "$SDK/emulator/emulator" -avd "$AVD" -no-snapshot-save -no-boot-anim -no-audio \
      > "$OUT_ROOT/emulator.log" 2>&1 &
    emulator_pid=$!
    started_emulator=1
  fi
  until [ -n "$device" ] && [ "$("$ADB" -s "$device" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; do
    [ "$waited" -lt "$BOOT_TIMEOUT_SEC" ] || die "the emulator did not boot in ${BOOT_TIMEOUT_SEC}s (see $OUT_ROOT/emulator.log)"
    sleep 2; waited=$((waited + 2)); device="$(running_emulator)"
  done
}

artefact() { # artefact <apk|web>; prints the path of the runner's own artefact
  local kept built
  kept="$("$SCRIPT_DIR/maestro-build.sh" path "$1")"
  if [ "${E2E_MAESTRO_REUSE_BUILD:-0}" = 1 ] && [ -e "$kept" ]; then printf '%s\n' "$kept"; return; fi
  log "building the $1 (a few minutes the first time)" >&2
  built="$("$SCRIPT_DIR/maestro-build.sh" "$1" 2> "$OUT_ROOT/build-$1.log")" \
    || { tail -30 "$OUT_ROOT/build-$1.log" >&2; die "the $1 build failed (log: $OUT_ROOT/build-$1.log)"; }
  printf '%s\n' "$built" | tail -1
}

# The lock screen is the emulator owner's: this script never types a PIN and
# never changes the lock. It keeps the screen from turning off (which is what
# locks it while a build runs) and, when the device is locked anyway, stops
# with the emulator left open so it can be unlocked.
keep_awake_and_unlocked() {
  "$ADB" -s "$device" shell svc power stayon true
  "$ADB" -s "$device" shell input keyevent KEYCODE_WAKEUP
  "$ADB" -s "$device" shell wm dismiss-keyguard >/dev/null 2>&1 || true   # a swipe lock only
  sleep 2
  if "$ADB" -s "$device" shell dumpsys window | grep -qE 'mDreamingLockscreen=true|isStatusBarKeyguard=true|mShowingLockscreen=true'; then
    started_emulator=0   # leave it open for its owner
    die "the emulator $device shows its lock screen. Unlock it (or set Settings > Security > Screen lock to None) and run again; the emulator is left running."
  fi
}

prepare_android() {
  local apk
  [ -x "$ADB" ] || die "adb not found at $ADB (set ANDROID_HOME)"
  # Build first: the emulator must not sit idle through a build of minutes.
  apk="$(artefact apk)"
  start_emulator
  keep_awake_and_unlocked
  "$ADB" -s "$device" install -r "$apk" >/dev/null
  # The emulator reaches the host's stack on its own 127.0.0.1; lost on every boot.
  "$ADB" -s "$device" reverse tcp:8585 tcp:8585 >/dev/null
  "$ADB" -s "$device" reverse tcp:8586 tcp:8586 >/dev/null
  # A freshly booted emulator draws nothing for a while: open the app once and
  # wait for its first frame, so the first flow does not start on a black screen.
  "$ADB" -s "$device" shell am start -W -n "$APP_ID/.MainActivity" >/dev/null
  "$ADB" -s "$device" shell am force-stop "$APP_ID"
}

prepare_web() {
  local dir waited=0
  ! lsof -nP -iTCP:"$WEB_PORT" -sTCP:LISTEN >/dev/null 2>&1 \
    || die "port $WEB_PORT is taken; stop what is listening there"
  dir="$(artefact web)"
  python3 -m http.server "$WEB_PORT" --bind 127.0.0.1 --directory "$dir" > "$OUT_ROOT/web-server.log" 2>&1 &
  server_pid=$!
  until curl -fs -o /dev/null "http://127.0.0.1:$WEB_PORT/"; do
    [ "$waited" -lt 20 ] || die "the web server did not answer on $WEB_PORT"
    sleep 1; waited=$((waited + 1))
  done
}

run_flow() { # run_flow <name> <run id>; prints the PASS/FAIL line, returns maestro's status
  local name="$1" run_id="$2" out="$OUT_ROOT/$2-$1" started code=0
  mkdir -p "$out"
  set -- test -e RUN_ID="$run_id" -e PRODUCT_NAME="MST-$run_id tea" --test-output-dir "$out"
  if [ "$platform" = android ]; then
    [ -z "$device" ] || set -- --device "$device" "$@"
  elif [ "$headless" -eq 1 ]; then
    set -- "$@" --headless --screen-size 1400x900
  fi
  started="$(date +%s)"
  "$MAESTRO" "$@" "$FLOWS_DIR/$platform/$name.yaml" > "$out/maestro.log" 2>&1 || code=$?
  [ "$code" -eq 0 ] || tail -25 "$out/maestro.log"
  [ "${E2E_MAESTRO_SKIP_SETUP:-0}" != 1 ] || cat "$out/maestro.log"
  if [ "$code" -eq 0 ]; then printf 'PASS %s %s %ss\n' "$platform" "$name" "$(( $(date +%s) - started ))"
  else printf 'FAIL %s %s %ss  (output: %s)\n' "$platform" "$name" "$(( $(date +%s) - started ))" "$out"; fi
  return "$code"
}

mkdir -p "$OUT_ROOT"
setup=1; [ "${E2E_MAESTRO_SKIP_SETUP:-0}" != 1 ] || setup=0   # the self-test runs without devices
# Starts the flows' own stack unless it is up already; refuses when another
# local stack (the Dart suite's) holds the ports.
start_stack() {
  if "$SCRIPT_DIR/local-stack.sh" status | grep -q 'pos-api running'; then return; fi
  ! lsof -nP -iTCP:8586 -sTCP:LISTEN >/dev/null 2>&1 \
    || die "another local stack is running on these ports (the Dart suite's?). Stop it first: tools/e2e/local-stack.sh stop"
  local out
  started_stack=1
  out="$("$SCRIPT_DIR/local-stack.sh" start 2>&1)" || { printf '%s\n' "$out" >&2; die "the local stack did not start"; }
  printf '%s\n' "$out" | tail -1
}

if [ "$setup" -eq 0 ]; then load_accounts; fi
if [ "$setup" -eq 1 ]; then
  start_stack   # a first start writes the env file
  load_accounts
  "prepare_$platform"
fi

failed=0; index=0; base_id="$(date +%H%M%S)"
for name in $flows; do
  index=$((index + 1)); run_id="$base_id$index"
  if [ "$setup" -eq 1 ]; then
    "$SCRIPT_DIR/local-stack.sh" reset-limits
    data_run_id="$run_id"
    "$SCRIPT_DIR/maestro-data.sh" up "$run_id" >/dev/null
  fi
  run_flow "$name" "$run_id" || failed=$((failed + 1))
  if [ "$setup" -eq 1 ]; then "$SCRIPT_DIR/maestro-data.sh" down "$run_id" >/dev/null; data_run_id=""; fi
done

[ "$failed" -eq 0 ] || { log "$failed flow(s) failed"; exit 1; }
log "all flows passed"
