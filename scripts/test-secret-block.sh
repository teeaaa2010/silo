#!/usr/bin/env bash
# Proves the pre-commit hook blocks a secret. The fake token is generated at runtime,
# so no secret-looking string is ever committed. Take your screenshot of this output.
source "$(dirname "$0")/lib.sh"
need git; need pre-commit
cd "$ROOT"
pre-commit install >/dev/null
f="$ROOT/leak-test.txt"
echo "github_token = ghp_$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 36)" > "$f"
git add "$f"
if git commit -m "test: fake secret (should be blocked)"; then
  git reset --soft HEAD~1 >/dev/null; git reset -q "$f"; rm -f "$f"
  die "commit was NOT blocked. Check the pre-commit setup."
fi
git reset -q "$f"; rm -f "$f"
log "commit was blocked as expected"
