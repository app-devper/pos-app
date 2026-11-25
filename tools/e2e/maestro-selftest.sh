#!/usr/bin/env bash
# Checks of the Maestro runner that need no device, no browser and no stack:
# usage errors, the local-only guard, and the environment Maestro is given.
#   tools/e2e/maestro-selftest.sh
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
failures=0

check() { # check <name> <expected exit> <text the output must hold> -- <command…>
  local name="$1" want="$2" text="$3" out code
  shift 4
  out="$("$@" 2>&1)"
  code=$?
  if [ "$code" -ne "$want" ]; then
    printf 'FAIL %s: exit %s, wanted %s\n%s\n' "$name" "$code" "$want" "$out"
    failures=$((failures + 1))
  elif ! printf '%s' "$out" | grep -qF -- "$text"; then
    printf 'FAIL %s: output lacks "%s"\n%s\n' "$name" "$text" "$out"
    failures=$((failures + 1))
  else
    printf 'ok   %s\n' "$name"
  fi
}

# A stand-in for maestro that prints what the runner handed it.
cat > "$WORK/fake-maestro" <<'EOF'
#!/usr/bin/env bash
echo "args: $*"
env | grep -E '^(MAESTRO_CLI_NO_ANALYTICS|MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED|MAESTRO_DISABLE_UPDATE_CHECK|SE_OFFLINE)=' | sort
env | grep -cE '^MAESTRO_(USERNAME|PASSWORD|MANAGER_USERNAME|MANAGER_PASSWORD|USER_USERNAME|USER_PASSWORD)=.' | sed 's/^/accounts: /'
EOF
chmod +x "$WORK/fake-maestro"

cat > "$WORK/env" <<'EOF'
E2E_ADMIN_USERNAME=a
E2E_ADMIN_PASSWORD=selftest-secret-a
E2E_MANAGER_USERNAME=m
E2E_MANAGER_PASSWORD=selftest-secret-m
E2E_USER_USERNAME=u
E2E_USER_PASSWORD=selftest-secret-u
EOF
printf '{"apiUrl": "https://api.example.com", "hostApp": "http://127.0.0.1:8586"}\n' > "$WORK/other-host.json"

runner="$SCRIPT_DIR/maestro.sh"
data="$SCRIPT_DIR/maestro-data.sh"
build="$SCRIPT_DIR/maestro-build.sh"
dry() { E2E_MAESTRO_SKIP_SETUP=1 MAESTRO_BIN="$WORK/fake-maestro" E2E_MAESTRO_ENV_FILE="$WORK/env" "$@"; }

check 'no platform is a usage error' 2 'usage:' -- "$runner"
check 'an unknown platform is a usage error' 2 'usage:' -- "$runner" ios auth
check 'an unknown option is a usage error' 2 'usage:' -- "$runner" web auth --hosted
check 'an unknown flow is refused' 2 'no such flow' -- dry "$runner" web nothing_like_this
check 'a config naming another host is refused' 2 'other-host.json' -- \
  env E2E_MAESTRO_CONFIG="$WORK/other-host.json" "$runner" web auth
check 'analytics off' 0 'MAESTRO_CLI_NO_ANALYTICS=1' -- dry "$runner" web auth
check 'analysis notice off' 0 'MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true' -- dry "$runner" web auth
check 'update check off' 0 'MAESTRO_DISABLE_UPDATE_CHECK=true' -- dry "$runner" web auth
check 'selenium manager offline' 0 'SE_OFFLINE=true' -- dry "$runner" web auth
check 'all three accounts reach maestro' 0 'accounts: 6' -- dry "$runner" web auth
check 'web headless gets a 1400x900 window' 0 '--screen-size 1400x900' -- dry "$runner" web auth --headless
check 'android names the flow file' 0 'maestro/android/auth.yaml' -- dry "$runner" android auth
check 'a pass prints a PASS line' 0 'PASS web auth' -- dry "$runner" web auth
check 'a failing maestro fails the run' 1 'FAIL web auth' -- \
  env E2E_MAESTRO_SKIP_SETUP=1 MAESTRO_BIN=false E2E_MAESTRO_ENV_FILE="$WORK/env" "$runner" web auth

no_secret="$(dry "$runner" web auth 2>&1 | grep -c 'selftest-secret' || true)"
if [ "$no_secret" -eq 0 ]; then printf 'ok   no password in the runner output\n'
else printf 'FAIL a password was printed\n'; failures=$((failures + 1)); fi

check 'data: no run id is a usage error' 2 'usage:' -- "$data" up
check 'data: an unknown mode is a usage error' 2 'usage:' -- "$data" sideways 123
check 'data: a run id with other characters is refused' 2 'usage:' -- "$data" up '1;x'
check 'build: an unknown artefact is a usage error' 2 'usage:' -- "$build" ipa
# The runner must never reuse the APK an ordinary `flutter build apk` leaves
# (that one may point at a deployed API): its own copy has a path of its own.
check "build: the reusable APK is the runner's own copy" 0 '/build/maestro/app-debug.apk' -- "$build" path apk
check "build: the reusable web build is the runner's own" 0 '/build/web-maestro' -- "$build" path web
check 'a missing env file says how it comes to be' 1 'is written by the first run' -- \
  env E2E_MAESTRO_SKIP_SETUP=1 MAESTRO_BIN="$WORK/fake-maestro" E2E_MAESTRO_ENV_FILE="$WORK/none" "$runner" web auth

if [ "$failures" -eq 0 ]; then echo 'maestro-selftest: all checks passed'; exit 0; fi
echo "maestro-selftest: $failures check(s) failed"
exit 1
