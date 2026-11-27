#!/usr/bin/env bash
# Runs every e2e file of the POS app against one target, under one run id,
# and prints a summary.
#
#   tools/e2e/run-all.sh local    the local stack (started and seeded if needed)
#   tools/e2e/run-all.sh hosted   the hosted API; run by the owner only
#
# Order: auth, navigation, customer, stock_in, selling, stock_count,
# product_edit, then any other *_test.dart alphabetically. Exits non-zero if
# any file failed.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
E2E_DIR="$(cd "$SCRIPT_DIR/../../packages/applications/pos/e2e" && pwd)"
HOSTED_API="https://api.devper.app"
FIRST_FILES="auth_test.dart navigation_test.dart customer_test.dart stock_in_test.dart selling_test.dart stock_count_test.dart product_edit_test.dart"

usage() { printf 'usage: %s <local|hosted>\n' "$0" >&2; exit 2; }

[ "$#" -eq 1 ] || usage
target="$1"
case "$target" in
  local) ;;
  hosted)
    printf 'run-all: target API %s — run by the owner\n' "$HOSTED_API"
    printf 'run-all: the API allows 5 sign-ins a minute per address, possibly shared with every user behind the gateway;\n'
    printf 'run-all: the suite paces its 12 sign-ins to at most 3 a minute, which adds up to about 3 minutes to a run\n'
    [ -f "$E2E_DIR/../.env.e2e" ] || {
      printf 'run-all: %s is missing (copy .env.e2e.example and fill it in)\n' "$(cd "$E2E_DIR/.." && pwd)/.env.e2e" >&2
      exit 2
    }
    ;;
  *) usage ;;
esac

# The fixed order first, then whatever else exists, alphabetically.
files() {
  for f in $FIRST_FILES; do [ -f "$E2E_DIR/$f" ] && printf '%s\n' "$f"; done
  for path in "$E2E_DIR"/*_test.dart; do
    f="$(basename "$path")"
    case " $FIRST_FILES " in *" $f "*) ;; *) printf '%s\n' "$f" ;; esac
  done
}

# "passed P, skipped S, failed F" from the runner's last progress line.
counts() {
  tr '\r' '\n' < "$1" | grep -E '^[0-9]+:[0-9]+ \+[0-9]+' | tail -1 | awk '{
    p = 0; s = 0; f = 0
    for (i = 1; i <= NF; i++) {
      t = $i; sub(/:$/, "", t)
      if (t ~ /^\+[0-9]+$/) p = substr(t, 2)
      else if (t ~ /^~[0-9]+$/) s = substr(t, 2)
      else if (t ~ /^-[0-9]+$/) f = substr(t, 2)
    }
    printf "passed %d, skipped %d, failed %d", p, s, f
  }'
}

sign_ins() {
  n="$(tr '\r' '\n' < "$1" | sed -n 's/^E2E: sign-ins this file: \([0-9]*\).*/\1/p' | tail -1)"
  printf '%s' "${n:-?}"
}

export E2E_RUN_ID="$(date +%Y%m%d%H%M%S)-$$"
LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pos-e2e-run-all.XXXXXX")"
export E2E_STOP_FILE="$LOG_DIR/stop"
summary=""
failed=0
for f in $(files); do
  if [ -e "$E2E_STOP_FILE" ]; then
    summary="$summary$(printf 'SKIP %-24s the run was stopped: the target refused the credentials — check .env.e2e' "$f")
"
    continue
  fi
  log="$LOG_DIR/${f%.dart}.log"
  printf 'run-all: %s …\n' "$f"
  if "$SCRIPT_DIR/run.sh" "$target" "$f" > "$log" 2>&1; then result=PASS
  else result=FAIL; failed=$((failed + 1)); fi
  summary="$summary$(printf '%-4s %-24s %s, sign-ins %s' "$result" "$f" "$(counts "$log")" "$(sign_ins "$log")")
"
done

printf '\n== E2E run %s (%s) — logs in %s\n' "$E2E_RUN_ID" "$target" "$LOG_DIR"
printf '%s' "$summary"
printf '\n== Leftovers\n'
for log in "$LOG_DIR"/*.log; do
  tr '\r' '\n' < "$log" | grep -E '^E2E leftovers:' | sed "s|^|$(basename "$log" .log): |" || true
done
printf '\n== Findings (skipped tests)\n'
cat "$LOG_DIR"/*.log | tr '\r' '\n' | sed -n 's/^ *Skip: \(FINDING: .*\)$/\1/p' | sort -u
if [ -e "$E2E_STOP_FILE" ]; then
  printf '\nrun-all: STOPPED — the target refused the suite'"'"'s credentials; check .env.e2e before running again\n'
  exit 1
fi
[ "$failed" -eq 0 ] || { printf '\nrun-all: %s file(s) failed\n' "$failed"; exit 1; }
