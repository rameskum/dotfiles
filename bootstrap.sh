#!/usr/bin/env bash
# Takes a fresh Ubuntu machine to a fully applied config.
# Run this once. After it finishes, use ./rebuild.sh for every later change.
# Safe to re-run: every step skips itself when already done.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [ "$(id -u)" = 0 ]; then
  echo "Run this as your normal user, not root. It calls sudo when it needs to."
  exit 1
fi

echo "==> Step 1: apt prerequisites (curl, git, zsh, Homebrew build deps)"
sudo apt-get update
# If Nix is already installed it owns /etc/zsh/zshrc; keep that file rather
# than stopping at dpkg's "configuration file modified" prompt.
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold \
  curl git gpg zsh build-essential procps file

echo "==> Step 2: Determinate Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "==> Step 3: symlink this repo to ~/.dotfiles"
# home.nix resolves its mkOutOfStoreSymlink paths through ~/.dotfiles, so this
# has to exist before the first switch or the build will fail to find them.
ln -sfn "$DIR" ~/.dotfiles

echo "==> Step 4: personalize the configured username"
REAL_USER="$(whoami)"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ -z "$FLAKE_USER" ]; then
  echo "    Could not find the 'user = \"...\";' line in flake.nix."
  echo "    Edit flake.nix yourself before continuing."
  exit 1
elif [ "$FLAKE_USER" != "$REAL_USER" ]; then
  echo "    flake.nix is configured for user \"$FLAKE_USER\", but you are \"$REAL_USER\"."
  read -r -p "    Rewrite flake.nix's user to \"$REAL_USER\"? [y/N] " REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    sed -i -E "s/^([[:space:]]*user = \")[^\"]+(\";.*)/\1${REAL_USER}\2/" "$DIR/flake.nix"
    echo "    Updated. Review the change with: git diff flake.nix"
  else
    echo "    Skipped. Edit the user line in flake.nix yourself before continuing."
    exit 1
  fi
else
  echo "    flake.nix already matches \"$REAL_USER\", nothing to do."
fi

echo "==> Step 5: Homebrew"
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  echo "    brew already installed, skipping"
else
  # The installer needs sudo to create /home/linuxbrew; refresh the cached
  # credentials so its non-interactive sudo calls succeed.
  sudo true
  NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "==> Step 6: first switch"
"$DIR/rebuild.sh"

echo "==> Step 7: make zsh the login shell"
ZSH_PATH=/usr/bin/zsh
if [ "$(getent passwd "$REAL_USER" | cut -d: -f7)" = "$ZSH_PATH" ]; then
  echo "    already using $ZSH_PATH"
else
  sudo chsh -s "$ZSH_PATH" "$REAL_USER"
fi

echo "==> Done. Log out and back in, then use ./rebuild.sh for future changes."
