#!/usr/bin/env bash
# Shared helpers. Source, do not execute.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/versions.env"
export NOMAD_ADDR="${NOMAD_ADDR:-http://127.0.0.1:4646}"
RUN_DIR="$ROOT/.run"
BASE_DIR=/opt/silo-nomad
SILO_API="http://127.0.0.1:9000"

log() { printf '\033[1;34m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
die() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

silo_image() {
  [ -n "${SILO_DIGEST:-}" ] || die "SILO_DIGEST is empty in versions.env. Run scripts/pin-silo.sh first."
  echo "${SILO_IMAGE_REPO}:${SILO_TAG}@${SILO_DIGEST}"
}

# wait_for <description> <timeout-seconds> <command...>
wait_for() {
  local desc=$1 timeout=$2 i=0
  shift 2
  until "$@" >/dev/null 2>&1; do
    i=$((i + 1))
    [ "$i" -ge "$timeout" ] && die "timed out waiting for: $desc"
    sleep 1
  done
}

agent_running() {
  local pidf="$RUN_DIR/$1.pid"
  [ -f "$pidf" ] && sudo kill -0 "$(cat "$pidf")" 2>/dev/null
}

start_agent() { # name config
  local name=$1 cfg=$2 nomad_bin
  nomad_bin="$(command -v nomad)"
  if agent_running "$name"; then log "agent $name already running"; return 0; fi
  log "starting agent $name"
  sudo bash -c "nohup '$nomad_bin' agent -config='$cfg' >'$RUN_DIR/$name.log' 2>&1 & echo \$! >'$RUN_DIR/$name.pid'"
}

stop_agent() { # name
  local name=$1 pid i
  agent_running "$name" || { log "agent $name not running"; return 0; }
  pid="$(cat "$RUN_DIR/$name.pid")"
  log "stopping agent $name (pid $pid)"
  sudo kill -INT "$pid" || true
  for i in $(seq 1 30); do
    sudo kill -0 "$pid" 2>/dev/null || { rm -f "$RUN_DIR/$name.pid"; return 0; }
    sleep 1
  done
  log "agent $name did not exit in 30s, sending SIGKILL"
  sudo kill -KILL "$pid" || true
  rm -f "$RUN_DIR/$name.pid"
}

two_clients_ready() { [ "$(nomad node status 2>/dev/null | grep -cw ready)" -ge 2 ]; }
silo_live() { curl -fsS "$SILO_API/minio/health/live"; }
