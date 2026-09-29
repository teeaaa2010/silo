#!/usr/bin/env bash
# Generate Silo root credentials once and store them as the Nomad variable nomad/jobs/silo.
source "$(dirname "$0")/lib.sh"
need nomad; need openssl
if nomad var get -out=json nomad/jobs/silo >/dev/null 2>&1; then
  log "Nomad variable nomad/jobs/silo already exists, leaving it alone"; exit 0
fi
user="silo-admin"
pass="$(openssl rand -base64 36 | tr -d '/+=\n' | cut -c1-32)"
printf '{"Items":{"root_user":"%s","root_password":"%s"}}' "$user" "$pass" \
  | nomad var put -force -in=json -out=none nomad/jobs/silo -
log "stored root credentials in Nomad variable nomad/jobs/silo"
