#!/usr/bin/env bash
# Applies this repo to the machine. Run it after every change that isn't just
# a symlinked file under home/.
#   1. Home Manager: packages, apps, zsh, dotfiles, Homebrew formulae
#   2. system/sync.sh: apt apps, GPU drivers, AppArmor (asks for sudo if needed)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# home.nix resolves its mkOutOfStoreSymlink paths through ~/.dotfiles.
if [ "$DIR" != "$(cd "$HOME/.dotfiles" 2>/dev/null && pwd -P)" ]; then
  ln -sfn "$DIR" "$HOME/.dotfiles"
fi

echo "==> Home Manager"
# Existing dotfiles it would overwrite (e.g. Ubuntu's default ~/.bashrc) are
# renamed to *.hm-backup instead of aborting the switch.
nix run "$DIR" -- switch --flake "$DIR#ubuntu" -b hm-backup "$@"

echo "==> System"
"$DIR/system/sync.sh"
