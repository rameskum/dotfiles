# Set the directory we want to store the zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source Zinit
source "$ZINIT_HOME/zinit.zsh"

#
eval "$(/opt/homebrew/bin/brew shellenv)"

# aliases
alias c=clear
alias grep='grep --color=auto'
# alias python=/opt/homebrew/bin/python3
# alias py=python
alias ls="lsd"
alias ls="ls -h --color=auto"
alias tom_start="brew services start tomcat"
alias tom_stop="brew services stop tomcat"

export PATH="/opt/homebrew/sbin:$PATH"

# VARIABLES
export EDITOR="vim"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="~/Oracle/instantclient10_1:$PATH"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="$PATH:/Users/rameskum/Development/flutter/bin"
export PATH="$PATH":"$HOME/.pub-cache/bin"

# RUBY
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  export PATH=`gem environment gemdir`/bin:$PATH
fi

# SETUP PYTHON
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi
alias python='python3'

# SETUP JAVA
export JAVA_21_HOME=$(/usr/libexec/java_home -v21)
export JAVA_17_HOME=$(/usr/libexec/java_home -v17)
export JAVA_11_HOME=$(/usr/libexec/java_home -v11)
export JAVA_8_HOME=$(/usr/libexec/java_home -v1.8)
export JAVA_7_HOME=$(/usr/libexec/java_home -v1.7)

# SETUP JAVA ALIASES
alias java21='export JAVA_HOME=$JAVA_21_HOME'
alias java17='export JAVA_HOME=$JAVA_17_HOME'
alias java11='export JAVA_HOME=$JAVA_11_HOME'
alias java8='export JAVA_HOME=$JAVA_8_HOME'
alias java7='export JAVA_HOME=$JAVA_7_HOME'

# SET DEFAULT JDK
java17

# node
PATH="/opt/homebrew/opt/node@20/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/node@20/lib"
export CPPFLAGS="-I/opt/homebrew/opt/node@20/include"


# zsh-z
# https://github.com/agkozak/zsh-z.git
# source ~/extensions/zsh-z/zsh-z.plugin.zsh
# autoload -U compinit; compinit
# zstyle ':completion:*' menu select

# autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# ---- FZF -----
# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# -- Use fd instead of fzf --

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# --- setup fzf theme ---
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#d0d0d0,fg+:#d0d0d0,bg:#121212,bg+:#262626
  --color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00
  --color=prompt:#d7005f,spinner:#af5fff,pointer:#af5fff,header:#87afaf
  --color=border:#262626,label:#aeaeae,query:#d9d9d9
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
  --marker=">" --pointer="◆" --separator="─" --scrollbar="│"'

# ----- Bat (better cat) -----

export BAT_THEME=tokyonight_night

# bun completions
[ -s "/Users/rameskum/.bun/_bun" ] && source "/Users/rameskum/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
