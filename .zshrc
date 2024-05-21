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
zinit ice depth=1; zinit light romkatv/powerlevel10k                  ## Installing Powerlevel10k
zinit ice depth=1; zinit light zsh-users/zsh-syntax-highlighting      ## Installing zsh-syntax-highlighting
zinit ice depth=1; zinit light zsh-users/zsh-completions              ## Installing zsh-completions
zinit ice depth=1; zinit light zsh-users/zsh-autosuggestions          ## Installing zsh-autosuggestions
zinit ice depth=1; zinit light Aloxaf/fzf-tab                         ## Installing fzf-tab

# Installing Ad-In Snippets
zinit snippet OMZP::git                                               ## Installing OMZP::git  https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git

# Load completions
autoload -U compinit && compinit

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# source the powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

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
# enable color to auto suggest completions
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# disable default completion
zstyle ':completion:*' menu no
# fzf-preview
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

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

# export brew shellenv
eval "$(/opt/homebrew/bin/brew shellenv)"


# ---- FZF -----
# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# aliases
alias c=clear
alias grep='grep --color=auto'
alias ls="ls --color"
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

# ----- Bat (better cat) -----
export BAT_THEME=tokyonight_night

# bun completions
[ -s "/Users/rameskum/.bun/_bun" ] && source "/Users/rameskum/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
