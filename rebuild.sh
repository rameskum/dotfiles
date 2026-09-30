#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles

# `nix run ~/.dotfiles` is the home-manager CLI pinned by flake.lock.
nix run ~/.dotfiles -- switch --flake ~/.dotfiles#ubuntu "$@"

# Nix GUI apps (WezTerm) need /run/opengl-driver to point at the Mesa drivers
# from this nixpkgs. Home Manager ships the setup script; rerun it whenever
# the link is missing or a flake update moved the drivers.
gpu_setup="$(readlink -f ~/.nix-profile/bin/non-nixos-gpu-setup)"
want="$(awk '$2 == "/run/opengl-driver" { print $NF }' "${gpu_setup%/bin/*}/lib/tmpfiles.d/non-nixos-gpu.conf")"
if [ "$(readlink /run/opengl-driver || true)" != "$want" ]; then
  echo "==> Linking GPU drivers for Nix apps (needs sudo)"
  sudo "$gpu_setup"
fi
