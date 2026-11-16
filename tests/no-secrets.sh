#!/bin/sh
# Fails if a tracked file under chezmoi/, tests/ or .github/ looks like it holds
# a secret value. Secrets are runtime-only (Bitwarden SSH agent, Infisical CLI);
# nothing is rendered into files. Names of env vars and public hostnames are fine.
set -eu

cd "$(dirname "$0")/.."

pattern='BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{32,}|(api[_-]?key|secret|token|passw(or)?d)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'$]{8,}'

# This script holds the pattern itself, so it is excluded.
hits=$(git ls-files chezmoi tests .github | grep -v '^tests/no-secrets.sh$' | xargs grep -nEi "$pattern" || true)
if [ -n "$hits" ]; then
  echo "possible secrets:" >&2
  echo "$hits" >&2
  exit 1
fi
echo "ok   no secret-looking values in chezmoi/, tests/, .github/"
