#!/bin/sh
set -eu
ops_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
env_file="$ops_dir/local/edge.env"
[ -f "$env_file" ] || { echo 'ERROR: Create ops/local/edge.env using ops/config/edge.env.example.' >&2; exit 1; }
case "${1:-start}" in
  start) docker compose --env-file "$env_file" -f "$ops_dir/compose.edge.yml" up -d --build --wait ;;
  stop) docker compose --env-file "$env_file" -f "$ops_dir/compose.edge.yml" stop ;;
  logs) docker compose --env-file "$env_file" -f "$ops_dir/compose.edge.yml" logs --tail 100 module-d ;;
  *) echo 'Usage: sh ops/edge.sh [start|stop|logs]' >&2; exit 2 ;;
esac
