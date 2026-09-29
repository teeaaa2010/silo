#!/usr/bin/env bash
# Create the Epic-only bucket + user and store them in the Nomad variable epic/silo-test.
# Later jobs read them with: {{ with nomadVar "epic/silo-test" }} ... {{ end }}
source "$(dirname "$0")/lib.sh"
need nomad; need docker; need openssl
if nomad var get -out=json epic/silo-test >/dev/null 2>&1; then
  log "Nomad variable epic/silo-test already exists, skipping"; exit 0
fi
image="$(silo_image)"
export BUCKET="epic-test"
export TEST_USER="epic-tester"
TEST_PASS="$(openssl rand -base64 36 | tr -d '/+=\n' | cut -c1-32)"; export TEST_PASS
ADMIN_USER="$(nomad var get -item root_user nomad/jobs/silo)"; export ADMIN_USER
ADMIN_PASS="$(nomad var get -item root_password nomad/jobs/silo)"; export ADMIN_PASS

docker run --rm --network host \
  -e ADMIN_USER -e ADMIN_PASS -e TEST_USER -e TEST_PASS -e BUCKET \
  --entrypoint sh "$image" -c '
set -e
MC="$(command -v mc || command -v mcli)"
"$MC" alias set silo http://127.0.0.1:9000 "$ADMIN_USER" "$ADMIN_PASS" >/dev/null
"$MC" mb --ignore-existing "silo/$BUCKET"
cat > /tmp/policy.json <<POLICY
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:*"],
"Resource":["arn:aws:s3:::$BUCKET","arn:aws:s3:::$BUCKET/*"]}]}
POLICY
"$MC" admin policy create silo epic-test-rw /tmp/policy.json 2>/dev/null \
  || "$MC" admin policy add silo epic-test-rw /tmp/policy.json
"$MC" admin user add silo "$TEST_USER" "$TEST_PASS"
"$MC" admin policy attach silo epic-test-rw --user "$TEST_USER" 2>/dev/null \
  || "$MC" admin policy set silo epic-test-rw user="$TEST_USER"
'
printf '{"Items":{"endpoint":"http://127.0.0.1:9000","bucket":"%s","access_key":"%s","secret_key":"%s"}}' \
  "$BUCKET" "$TEST_USER" "$TEST_PASS" \
  | nomad var put -force -in=json -out=none epic/silo-test -
log "bucket '$BUCKET' and user '$TEST_USER' created; credentials stored in Nomad variable epic/silo-test"
