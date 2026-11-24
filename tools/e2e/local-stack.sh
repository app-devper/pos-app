#!/usr/bin/env bash
# The local backend the POS e2e suite runs against: MongoDB (a one-node
# replica set, for pos-api's Stock transactions), Redis, um-api and pos-api,
# on ports that keep clear of a developer's own services. All state (data,
# binaries, logs, pid files) lives under ${TMPDIR:-/tmp}/pos-e2e-stack.
#
#   local-stack.sh start         start what is not running, seed UM, wait for /health
#   local-stack.sh stop          stop only the processes this script started
#   local-stack.sh status        say what is running
#   local-stack.sh reset-limits  forget um-api's sign-in rate-limit counters
#
# Sibling checkouts default to ../../UM/um-api and ../../Devper/pos-api next to
# this repo's parent; override with UM_API_DIR and POS_API_DIR.
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKSPACE="${E2E_WORKSPACE:-/Users/admin/ProjectPos}"
UM_API_DIR="${UM_API_DIR:-$WORKSPACE/UM/um-api}"
POS_API_DIR="${POS_API_DIR:-$WORKSPACE/Devper/pos-api}"
ENV_FILE="$REPO_ROOT/packages/applications/pos/.env.e2e.local"

TMP_ROOT="${TMPDIR:-/tmp}"
STATE="${TMP_ROOT%/}/pos-e2e-stack"
MONGO_PORT=27719
REDIS_PORT=6390
UM_PORT=8585
POS_PORT=8586
REPLICA_SET=rs0
MONGO_URI="mongodb://127.0.0.1:$MONGO_PORT/?replicaSet=$REPLICA_SET"
REDIS_URL="redis://127.0.0.1:$REDIS_PORT"
UM_DB=e2e_um
POS_DB=e2e_pos
HEALTH_TIMEOUT_SEC=90

log() { printf 'local-stack: %s\n' "$*"; }
die() { printf 'local-stack: %s\n' "$*" >&2; exit 1; }

pid_alive() {
  [ -f "$STATE/pids/$1.pid" ] && kill -0 "$(cat "$STATE/pids/$1.pid")" 2>/dev/null
}

port_busy() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN -t >/dev/null 2>&1
}

# A port someone else holds is an error, not a cue to pick another one.
require_free_port() {
  name="$1"; port="$2"
  if pid_alive "$name"; then return 0; fi
  if port_busy "$port"; then
    die "port $port (for $name) is already in use by another process; free it and retry"
  fi
}

wait_until() {
  what="$1"; shift
  waited=0
  until "$@" >/dev/null 2>&1; do
    waited=$((waited + 1))
    [ "$waited" -le "$HEALTH_TIMEOUT_SEC" ] || die "$what did not come up in ${HEALTH_TIMEOUT_SEC}s (logs: $STATE/logs)"
    sleep 1
  done
}

secret_key() {
  if [ ! -f "$STATE/secret_key" ]; then
    (umask 077 && openssl rand -hex 32 > "$STATE/secret_key")
  fi
  cat "$STATE/secret_key"
}

start_mongo() {
  if pid_alive mongod; then return 0; fi
  mkdir -p "$STATE/mongo"
  mongod --replSet "$REPLICA_SET" --port "$MONGO_PORT" --bind_ip 127.0.0.1 \
    --dbpath "$STATE/mongo" --logpath "$STATE/logs/mongod.log" --logappend \
    --pidfilepath "$STATE/pids/mongod.pid" --fork >/dev/null
  wait_until "mongod" mongosh --quiet --port "$MONGO_PORT" --eval 'db.runCommand({ping:1}).ok'
  mongosh --quiet --port "$MONGO_PORT" --eval "
    try { rs.status().ok } catch (e) {
      rs.initiate({_id: '$REPLICA_SET', members: [{_id: 0, host: '127.0.0.1:$MONGO_PORT'}]}).ok
    }" >/dev/null
  wait_until "the replica set primary" mongosh --quiet --port "$MONGO_PORT" \
    --eval 'if (!db.hello().isWritablePrimary) { quit(1) }'
}

start_redis() {
  if pid_alive redis; then return 0; fi
  mkdir -p "$STATE/redis"
  redis-server --port "$REDIS_PORT" --bind 127.0.0.1 --dir "$STATE/redis" \
    --save '' --appendonly no --daemonize yes \
    --pidfile "$STATE/pids/redis.pid" --logfile "$STATE/logs/redis.log"
  wait_until "redis" redis-cli -p "$REDIS_PORT" ping
}

seed() {
  (cd "$SCRIPT_DIR/seed-local" && go run . -mongo "$MONGO_URI" -db "$UM_DB" \
    -pos-host "http://127.0.0.1:$POS_PORT" -env-file "$ENV_FILE")
}

# Builds the service and runs the binary itself, so the pid file names the
# process that listens (a `go run` parent would leave its child behind).
start_service() {
  name="$1"; src="$2"; port="$3"; shift 3
  if pid_alive "$name"; then return 0; fi
  [ -d "$src" ] || die "$name checkout not found at $src"
  (cd "$src" && go build -o "$STATE/bin/$name" .)
  # Run from the state dir: both services load a ./.env if one is there.
  # The job is one simple command, so $! is the service's own pid (env and
  # nohup exec into it).
  (
    cd "$STATE"
    env "$@" PORT="$port" nohup "$STATE/bin/$name" >"$STATE/logs/$name.log" 2>&1 &
    echo "$!" > "$STATE/pids/$name.pid"
  )
  wait_until "$name /health" curl -fsS "http://127.0.0.1:$port/health"
}

start() {
  mkdir -p "$STATE/pids" "$STATE/logs" "$STATE/bin"
  require_free_port mongod "$MONGO_PORT"
  require_free_port redis "$REDIS_PORT"
  require_free_port um-api "$UM_PORT"
  require_free_port pos-api "$POS_PORT"
  start_mongo
  start_redis
  seed
  key="$(secret_key)"
  start_service um-api "$UM_API_DIR" "$UM_PORT" \
    MONGO_HOST="$MONGO_URI" MONGO_UM_DB_NAME="$UM_DB" REDIS_HOST="$REDIS_URL" SECRET_KEY="$key"
  start_service pos-api "$POS_API_DIR" "$POS_PORT" \
    MONGO_HOST="$MONGO_URI" MONGO_POS_DB_NAME="$POS_DB" REDIS_HOST="$REDIS_URL" SECRET_KEY="$key" \
    CLIENT_ID=000 SYSTEM=POS
  log "up: um-api :$UM_PORT, pos-api :$POS_PORT, mongod :$MONGO_PORT, redis :$REDIS_PORT (state $STATE)"
}

stop_one() {
  name="$1"
  if ! pid_alive "$name"; then rm -f "$STATE/pids/$name.pid"; return 0; fi
  pid="$(cat "$STATE/pids/$name.pid")"
  kill "$pid"
  waited=0
  while kill -0 "$pid" 2>/dev/null; do
    waited=$((waited + 1))
    [ "$waited" -le 30 ] || die "$name (pid $pid) did not stop"
    sleep 1
  done
  rm -f "$STATE/pids/$name.pid"
  log "stopped $name"
}

stop() {
  for name in pos-api um-api redis mongod; do stop_one "$name"; done
}

status() {
  for name in mongod redis um-api pos-api; do
    if pid_alive "$name"; then log "$name running (pid $(cat "$STATE/pids/$name.pid"))"
    else log "$name stopped"; fi
  done
}

reset_limits() {
  pid_alive redis || die "redis is not running"
  redis-cli -p "$REDIS_PORT" --scan --pattern 'rate_limit:*' \
    | while read -r key; do redis-cli -p "$REDIS_PORT" del "$key" >/dev/null; done
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  status) status ;;
  reset-limits) reset_limits ;;
  *) die "usage: $0 start|stop|status|reset-limits" ;;
esac
