# Silo on Nomad: storage network evaluation

> **This is an evaluation project.** It is a learning and testing exercise, not a production deployment.

## Purpose

Evaluate how a self-hosted S3 backend ([Silo](https://github.com/pgsty/silo), a community-maintained MinIO fork) behaves when run and consumed on a small Nomad cluster. This repo builds a reproducible local test bed (Nomad server plus two clients, and a single-node Silo instance) that later sub-tasks build on.

## Links

- Jira Epic: `<JIRA_EPIC_URL>`
- Project board: `<GITHUB_PROJECT_BOARD_URL>` (columns: Backlog, In Progress, Documenting, Done)

## Status

| # | Sub-task | Status | Write-up |
|---|----------|--------|----------|
| 1 | Repo, local Nomad environment and Silo backend | In progress | [docs/01-repo-nomad-and-silo-backend](docs/01-repo-nomad-and-silo-backend/README.md) |

## Quick start (Linux)

Requirements: Docker (usable without sudo), `sudo`, `curl`, `openssl`, `unzip`, and [`pre-commit`](https://pre-commit.com).

```bash
scripts/install-nomad.sh   # installs the Nomad version pinned in versions.env
scripts/pin-silo.sh        # one-off: records the image digest of the pinned Silo tag
scripts/nomad-up           # agents, Silo job, test bucket and key, put/get smoke test
scripts/verify.sh          # prints the evidence used in the write-up
scripts/nomad-down         # stop everything, keep data
scripts/nomad-reset        # destroy everything (agents, Nomad state, Silo data)
```

## Layout

| Path | Contents |
|------|----------|
| `versions.env` | Pinned Nomad version, Silo tag and digest |
| `nomad/agents/` | `main.hcl` (server + client 1) and `client2.hcl` (client 2) |
| `nomad/jobs/` | `silo.nomad.hcl`, `privileged-check.nomad.hcl` |
| `scripts/` | Lifecycle, credential and verification scripts |
| `docs/` | One folder per sub-task with its write-up and evidence |

## Secrets

No secrets are committed. Silo root credentials and the Epic test key live in Nomad variables (`nomad/jobs/silo` and `epic/silo-test`) and are generated at bring-up. Secret scanning runs in three places: GitHub secret scanning with push protection, a `gitleaks` pre-commit hook (`pre-commit install`), and a CI workflow.
