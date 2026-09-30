#!/usr/bin/env bash
# Applies this repo to the machine. Run it after every change.
#   1. Home Manager: Nix packages, dotfiles, zsh, Homebrew formulae
#   2. apt: GUI apps listed in ubuntu/apt-apps.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [ "$DIR" != "$(cd "$HOME/.dotfiles" 2>/dev/null && pwd -P)" ]; then
  ln -sfn "$DIR" "$HOME/.dotfiles"
fi

echo "==> Home Manager"
# `nix run "$DIR"` is the home-manager CLI pinned by flake.lock. Existing
# dotfiles it would overwrite (e.g. Ubuntu's default ~/.bashrc) are renamed
# to *.hm-backup instead of aborting the switch.
nix run "$DIR" -- switch --flake "$DIR#ubuntu" -b hm-backup "$@"

echo "==> apt apps"
"$DIR/ubuntu/apt-sync.sh"
