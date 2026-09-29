#!/usr/bin/env bash
# Resolve the digest of the pinned Silo tag and record it in versions.env.
# Needs internet + docker. Re-run only when deliberately bumping SILO_TAG.
source "$(dirname "$0")/lib.sh"
need docker
ref="${SILO_IMAGE_REPO}:${SILO_TAG}"
log "pulling $ref"
docker pull "$ref"
digest="$(docker inspect --format '{{index .RepoDigests 0}}' "$ref" | sed 's/.*@//')"
[[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]] || die "could not read digest (got: $digest)"
sed -i "s|^SILO_DIGEST=.*|SILO_DIGEST=${digest}|" "$ROOT/versions.env"
log "pinned $ref@$digest"
