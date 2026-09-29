#!/usr/bin/env bash
# Prints the evidence needed for the acceptance criteria. Paste the output into the write-up.
source "$(dirname "$0")/lib.sh"
need nomad; need docker
echo "== date ==";              date -u +%FT%TZ
echo "== nomad version ==";     nomad version
echo "== docker version ==";    docker --version
echo "== pinned Silo image =="; silo_image
echo "== nodes ==";             nomad node status
echo "== silo job ==";          nomad job status silo
echo "== privileged check (proves allow_privileged = true on each client) =="
nomad job run -detach -var "image=${BUSYBOX_IMAGE}" "$ROOT/nomad/jobs/privileged-check.nomad.hcl" >/dev/null
alloc_states() { nomad job allocs -t '{{range .}}{{.ID}} {{.ClientStatus}}{{"\n"}}{{end}}' privileged-check; }
done_check() { alloc_states | awk 'NF{n++; if($2=="complete")c++} END{exit !(n>=2 && n==c)}'; }
wait_for "privileged-check on both clients" 120 done_check
alloc_states | awk 'NF{print $1}' | while read -r id; do
  echo "-- alloc $id"; nomad alloc logs "$id"
done
nomad job stop -purge privileged-check >/dev/null
echo "== mc put/get =="; "$ROOT/scripts/smoke-test.sh"
