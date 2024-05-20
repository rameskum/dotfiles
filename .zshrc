# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set the directory we want to store the zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source Zinit
source "$ZINIT_HOME/zinit.zsh"

# Install zsh plugins

## Installing Powerlevel10k prompt
zinit ice depth=1; zinit light romkatv/powerlevel10k

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# source the powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

zinit ice depth=1; zinit light zsh-users/zsh-syntax-highlighting      ## Installing zsh-syntax-highlighting
zinit ice depth=1; zinit light zsh-users/zsh-completions              ## Installing zsh-completions
zinit ice depth=1; zinit light zsh-users/zsh-autosuggestions          ## Installing zsh-autosuggestions


# Load completions
autoload -U compinit && compinit

# Key bindings, setting to emacs mode
# ^a moves to beginning of line
# ^e moves to end of line
# ^w deletes word before cursor
# ^f moves forward one character
# ^b moves backward one character
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward


# Completion styling, enable case insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
#
eval "$(/opt/homebrew/bin/brew shellenv)"

# aliases
alias c=clear
alias grep='grep --color=auto'
alias ls="ls --color=auto"
alias ll="ls -l"
alias tom_start="brew services start tomcat"
alias tom_stop="brew services stop tomcat"

export PATH="/opt/homebrew/sbin:$PATH"

# VARIABLES
export EDITOR="vim"
export PATH="/opt/homebrew/bin:$PATH"

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
