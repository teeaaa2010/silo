#!/usr/bin/env bash
# Install the pinned Nomad version from releases.hashicorp.com with checksum verification.
source "$(dirname "$0")/lib.sh"
need curl; need unzip; need sha256sum; need sudo
arch="$(uname -m)"
case "$arch" in x86_64) arch=amd64 ;; aarch64) arch=arm64 ;; *) die "unsupported arch $arch" ;; esac
base="https://releases.hashicorp.com/nomad/${NOMAD_VERSION}"
zip="nomad_${NOMAD_VERSION}_linux_${arch}.zip"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/$zip" "$base/$zip"
curl -fsSL -o "$tmp/SHA256SUMS" "$base/nomad_${NOMAD_VERSION}_SHA256SUMS"
(cd "$tmp" && grep " $zip\$" SHA256SUMS | sha256sum -c -)
unzip -o -q "$tmp/$zip" -d "$tmp"
sudo install -m 0755 "$tmp/nomad" /usr/local/bin/nomad
nomad version
