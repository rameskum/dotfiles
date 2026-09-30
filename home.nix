{ config, lib, pkgs, user, gitName, gitEmail, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
{
  imports = [ ./modules/homebrew.nix ];

  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "26.05";

  # Ubuntu, not NixOS: puts Nix apps in the app launcher, sources Nix in login
  # shells, and provides the GPU driver link that system/sync.sh installs.
  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    # cli i use constantly
    git
    ripgrep   # fast search
    fd        # fast find
    jq        # json on the command line
    htop
    uv
    # apps
    brave
    wezterm
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nano";

  # Formulae only: casks are macOS-only. Anything installed with
  # `brew install` that isn't listed here is uninstalled on the next rebuild.
  homebrew = {
    enable = true;
    cleanup = true;
    formulae = [
      "nvm"
      "wget"
      "gh"
    ];
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = gitName;
      user.email = gitEmail;
      init.defaultBranch = "main";
    };
  };

  # bootstrap.sh makes /usr/bin/zsh the login shell; this owns ~/.zshrc.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    historySubstringSearch.enable = true;
    autocd = true;
    history = {
      size = 50000;
      save = 50000;
      share = true;
      ignoreAllDups = true;
      ignoreSpace = true;
    };
    shellAliases = {
      ".." = "cd ..";
      cat = "bat --paging=never";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
      rebuild = "~/.dotfiles/rebuild.sh";
    };
    initContent = ''
      bindkey '^f' autosuggest-accept

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"

      export NVM_DIR="$HOME/.nvm"
      if [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]; then
        mkdir -p "$NVM_DIR"
        . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
      fi
    '';
  };
  programs.bash.enable = true;

  programs.starship = {
    enable = true;
    settings = {
      format = lib.concatStrings [
        "$os"
        "$directory"
        "$git_branch"
        "$git_status"
        "$python"
        "$nodejs"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];
      os = {
        disabled = false;
        style = "bold #e95420";
        symbols.Ubuntu = " ";
      };
      directory.style = "bold #89b4fa";
      git_branch = {
        symbol = " ";
        style = "bold #cba6f7";
      };
      git_status.style = "bold #f38ba8";
      python.symbol = " ";
      nodejs.symbol = " ";
      cmd_duration.format = "took [$duration]($style) ";
      character = {
        success_symbol = "[❯](bold #a6e3a1)";
        error_symbol = "[❯](bold #f38ba8)";
      };
    };
  };

  programs.fzf.enable = true;       # Ctrl+R history, Ctrl+T files
  programs.zoxide.enable = true;    # `z <part-of-dir>`
  programs.bat.enable = true;
  programs.eza = {
    enable = true;                  # ls / ll / la / lt
    icons = "auto";
    git = true;
  };

  # Edit-in-place: the real file stays in this repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
}
