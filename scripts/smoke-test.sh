#!/usr/bin/env bash
# Put and get an object with mc (run from a container), using the Epic test credentials.
source "$(dirname "$0")/lib.sh"
need nomad; need docker
image="$(silo_image)"
ACCESS_KEY="$(nomad var get -item access_key epic/silo-test)"; export ACCESS_KEY
SECRET_KEY="$(nomad var get -item secret_key epic/silo-test)"; export SECRET_KEY
BUCKET="$(nomad var get -item bucket epic/silo-test)"; export BUCKET
docker run --rm --network host -e ACCESS_KEY -e SECRET_KEY -e BUCKET \
  --entrypoint sh "$image" -c '
set -e
MC="$(command -v mc || command -v mcli)"
"$MC" alias set silo http://127.0.0.1:9000 "$ACCESS_KEY" "$SECRET_KEY" >/dev/null
echo "silo smoke test $(date -u +%FT%TZ)" > /tmp/put.txt
"$MC" cp /tmp/put.txt "silo/$BUCKET/smoke/put.txt"
"$MC" cat "silo/$BUCKET/smoke/put.txt" > /tmp/get.txt
cmp /tmp/put.txt /tmp/get.txt && echo "PUT/GET OK"
"$MC" ls "silo/$BUCKET/smoke/"
'
