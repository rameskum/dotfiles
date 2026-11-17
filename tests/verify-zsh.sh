#!/bin/sh
# Checks an applied zsh setup (macOS, Linux, WSL). Run it after
# `chezmoi init --apply`, with HOME pointing at the applied home:
#
#   HOME=/tmp/home tests/verify-zsh.sh
#
# DOTFILES_SRC is the chezmoi source checkout (default: this repo).
# The zsh snippets are single-quoted on purpose (zsh expands them, not sh), and
# `A && pass || fail` is fine because pass cannot fail.
# shellcheck disable=SC2016,SC2015,SC1091
set -eu

SRC=${DOTFILES_SRC:-$(cd "$(dirname "$0")/.." && pwd)}
TAB=$(printf '\t')
failures=0

pass() { echo "ok   $*"; }
fail() { echo "FAIL $*" >&2; failures=$((failures + 1)); }

# Runs one zsh snippet in an interactive shell that loads ~/.zshrc.
zsh_i() { zsh -i -c "$1" 2>&1; }

[ -f "$HOME/.zshrc" ] || { echo "FAIL $HOME/.zshrc missing" >&2; exit 1; }

# The OS logo the shared starship.toml puts in the prompt. The os module is off
# in starship's defaults, so this glyph proves the config took effect.
if [ "$(uname -s)" = Darwin ]; then
  os_symbol=$(printf '\357\205\271') # U+F179
elif [ "$(. /etc/os-release && echo "$ID")" = ubuntu ]; then
  os_symbol=$(printf '\357\214\233') # U+F31B
else
  echo "FAIL no expected starship OS symbol for this OS (macOS and Ubuntu only)" >&2
  exit 1
fi

# Files: same bytes as the source, so every OS gets the same terminal and prompt.
cmp -s "$SRC/chezmoi/dot_wezterm.lua" "$HOME/.wezterm.lua" \
  && pass ".wezterm.lua matches source" || fail ".wezterm.lua differs from source"
cmp -s "$SRC/chezmoi/dot_config/starship.toml" "$HOME/.config/starship.toml" \
  && pass "starship.toml matches source" || fail "starship.toml differs from source"
[ -f "$HOME/.agents/.skill-lock.json" ] && pass "skill lockfile present" || fail "skill lockfile missing"

# A real interactive session in a pseudo-terminal: clean startup, the prompt is
# drawn, Tab completes, an earlier command comes back as a suggestion.
python3 "$SRC/tests/shell-pty.py" "$os_symbol" || failures=$((failures + 1))

# Aliases: every alias that applies here (and whose command exists) is defined.
# Rendered first so a chezmoi failure fails the check instead of feeding the
# loop an empty list.
if ! aliases=$(chezmoi --source "$SRC" execute-template <"$SRC/tests/aliases.tmpl") || [ -z "$aliases" ]; then
  fail "could not render the alias list with chezmoi"
fi
printf '%s\n' "$aliases" | while IFS=$TAB read -r name requires; do
  [ -n "$name" ] || continue
  if [ -n "$requires" ] && ! zsh_i "(( \$+commands[$requires] ))" >/dev/null; then
    echo "skip alias $name ($requires not installed)"
    continue
  fi
  if zsh_i "alias -- $name" | grep -q .; then
    echo "ok   alias $name"
  else
    echo "FAIL alias $name not defined" >&2
    exit 1
  fi
done || failures=$((failures + 1))

# Completion, suggestions, highlighting, fzf, zoxide, prompt.
check() { # description, zsh snippet that must print "yes"
  if [ "$(zsh_i "$2" | tail -n 1)" = yes ]; then pass "$1"; else fail "$1"; fi
}
check "completion loaded (compinit)" '(( $+functions[compdef] )) && echo yes'
check "case-insensitive completion matcher" 'zstyle -s :completion: matcher-list m && [[ $m == *a-zA-Z* ]] && echo yes'
if zsh_i '(( $+commands[starship] ))' >/dev/null; then
  prompt=$(zsh_i "cd '$SRC' && STARSHIP_SHELL=zsh starship prompt")
  case $prompt in *"$os_symbol"*) pass "starship prompt uses starship.toml (OS symbol)" ;; *) fail "starship prompt has no OS symbol from starship.toml: $prompt" ;; esac
else
  fail "starship not installed"
fi
if zsh_i '[[ -n ${HOMEBREW_PREFIX:-} ]]' >/dev/null; then
  check "autosuggestions loaded" '(( $+functions[_zsh_autosuggest_start] )) && echo yes'
  check "syntax highlighting loaded" '(( ${+ZSH_HIGHLIGHT_VERSION} )) && echo yes'
  check "history substring search loaded" '(( $+functions[history-substring-search-up] )) && echo yes'
  check "Ctrl+F accepts the suggestion" '[[ $(bindkey "^f") == *autosuggest-accept ]] && echo yes'
else
  fail "Homebrew not found: zsh plugins cannot be loaded"
fi
if zsh_i '(( $+commands[fzf] ))' >/dev/null; then
  check "fzf Ctrl+R widget" '[[ $(bindkey "^r") == *fzf-history-widget ]] && echo yes'
else
  fail "fzf not installed"
fi
if zsh_i '(( $+commands[zoxide] ))' >/dev/null; then
  check "zoxide z command" '(( $+functions[z] )) && echo yes'
else
  fail "zoxide not installed"
fi

if [ "$failures" -ne 0 ]; then
  echo "$failures check(s) failed" >&2
  exit 1
fi
echo "all zsh checks passed"
