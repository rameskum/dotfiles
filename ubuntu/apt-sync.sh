#!/usr/bin/env bash
# Makes the apt packages on this machine match ubuntu/apt-apps.sh:
#   - adds each app's vendor repo and signing key, then installs the app
#   - purges apps that were installed by this script but are no longer listed,
#     and deletes their repo + key
# Packages you installed yourself with `apt install` are never touched.
# Only asks for sudo when something actually needs to change.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
STATE_FILE="$STATE_DIR/apt-apps.tsv"
SOURCES_DIR=/etc/apt/sources.list.d
ARCH="$(dpkg --print-architecture)"

PKGS=() KEYS=() KEYRINGS=() SOURCES=() REPOS=()

app() {
  local pkg="$1" key="" keyring="" source="" repo=""
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --key) key="$2" ;;
      --keyring) keyring="$2" ;;
      --source) source="$2" ;;
      --repo) repo="$2" ;;
      *) echo "apt-apps.sh: unknown option '$1' for app $pkg" >&2; exit 1 ;;
    esac
    shift 2
  done
  if [ -n "$repo$key$keyring$source" ] &&
     { [ -z "$repo" ] || [ -z "$key" ] || [ -z "$keyring" ] || [ -z "$source" ]; }; then
    echo "apt-apps.sh: app $pkg needs all of --key, --keyring, --source and --repo" >&2
    exit 1
  fi
  PKGS+=("$pkg") KEYS+=("$key") KEYRINGS+=("$keyring") SOURCES+=("$source") REPOS+=("$repo")
}

# shellcheck source=apt-apps.sh
. "$DIR/apt-apps.sh"

is_installed() {
  [ "$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null)" = "installed" ]
}

contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

deb_line() {
  echo "deb [arch=$ARCH signed-by=$1] $2"
}

need_update=0

# 1. Remove apps that were managed before but are no longer listed.
if [ -f "$STATE_FILE" ]; then
  while IFS=$'\t' read -r pkg keyring source; do
    contains "$pkg" "${PKGS[@]}" && continue
    if is_installed "$pkg"; then
      echo "==> apt: removing $pkg"
      sudo apt-get purge -y --autoremove "$pkg"
    fi
    if [ -n "$source" ] && ! contains "$source" "${SOURCES[@]}"; then
      sudo rm -f "$SOURCES_DIR/$source" "$keyring"
      need_update=1
    fi
  done < "$STATE_FILE"
fi

# 2. Add missing or changed vendor repos.
for i in "${!PKGS[@]}"; do
  [ -n "${SOURCES[$i]}" ] || continue
  keyring="${KEYRINGS[$i]}"
  source_path="$SOURCES_DIR/${SOURCES[$i]}"
  line="$(deb_line "$keyring" "${REPOS[$i]}")"

  if [ ! -s "$keyring" ]; then
    echo "==> apt: adding signing key for ${PKGS[$i]}"
    tmp="$(mktemp)"
    curl -fsSL "${KEYS[$i]}" -o "$tmp"
    if grep -q -- "-----BEGIN PGP" "$tmp"; then
      gpg --dearmor --yes -o "$tmp.gpg" "$tmp"
      mv "$tmp.gpg" "$tmp"
    fi
    sudo install -D -m 0644 "$tmp" "$keyring"
    rm -f "$tmp"
    need_update=1
  fi

  if [ "$(cat "$source_path" 2>/dev/null)" != "$line" ]; then
    echo "==> apt: writing $source_path"
    echo "$line" | sudo tee "$source_path" >/dev/null
    need_update=1
  fi
done

# 3. Install anything that is listed but not installed.
missing=()
for pkg in "${PKGS[@]}"; do
  is_installed "$pkg" || missing+=("$pkg")
done

if [ ${#missing[@]} -gt 0 ]; then
  need_update=1
fi
if [ "$need_update" = 1 ]; then
  sudo apt-get update
fi
if [ ${#missing[@]} -gt 0 ]; then
  echo "==> apt: installing ${missing[*]}"
  sudo apt-get install -y "${missing[@]}"
fi

# 4. Remember what we manage so removals work next time.
mkdir -p "$STATE_DIR"
: > "$STATE_FILE"
for i in "${!PKGS[@]}"; do
  printf '%s\t%s\t%s\n' "${PKGS[$i]}" "${KEYRINGS[$i]}" "${SOURCES[$i]}" >> "$STATE_FILE"
done

echo "==> apt: ${#PKGS[@]} app(s) in sync"
