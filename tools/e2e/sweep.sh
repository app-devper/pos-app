#!/usr/bin/env bash
# Cleans up what an interrupted e2e run left: standing bills made only of
# suite products, active `E2E-` products (stock zeroed, then deleted),
# run-named customers (local only) and draft receipts with a run-id
# reference. Touches nothing without the suite's prefix. See
# packages/applications/pos/e2e/maintenance/sweep_earlier_runs.dart.
#
#   tools/e2e/sweep.sh local    the local stack
#   tools/e2e/sweep.sh hosted   the hosted API; run by the owner only
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() { printf 'usage: %s <local|hosted>\n' "$0" >&2; exit 2; }
[ "$#" -eq 1 ] || usage
case "$1" in local|hosted) ;; *) usage ;; esac

# run.sh prints the hosted API and "run by the owner", and refuses without
# .env.e2e, exactly as for a test file.
log="$(mktemp "${TMPDIR:-/tmp}/pos-e2e-sweep.XXXXXX")"
set +e
"$SCRIPT_DIR/run.sh" "$1" maintenance/sweep_earlier_runs.dart > "$log" 2>&1
code=$?
set -e
tr '\r' '\n' < "$log" | grep -E '^(run.sh:|local-stack:|E2E sweep|  - |E2E: sign-ins)' || true
if [ "$code" -ne 0 ]; then
  printf 'sweep: FAILED (exit %s); full log in %s\n' "$code" "$log" >&2
  exit "$code"
fi
printf 'sweep: done; full log in %s\n' "$log"
