{ lib, ... }:

{
  # Home Manager owns ~/.zshrc; bootstrap.sh makes /usr/bin/zsh the login shell.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
    autocd = true;

    history = {
      size = 50000;
      save = 50000;
      share = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      extended = true;
    };

    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      cat = "bat --paging=never";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
      rebuild = "~/.dotfiles/rebuild.sh";
    };

    initContent = lib.mkOrder 1000 ''
      # Arrow-key menu for completions, case-insensitive matching, coloured like ls.
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

      bindkey '^[[1;5C' forward-word    # Ctrl+Right
      bindkey '^[[1;5D' backward-word   # Ctrl+Left
      bindkey '^[[3~' delete-char       # Delete
    '';
  };

  programs.bash.enable = true;

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = lib.concatStrings [
        "$os"
        "$username"
        "$hostname"
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
      username.format = "[$user]($style)@";
      hostname.format = "[$hostname]($style) ";
      directory = {
        style = "bold #89b4fa";
        truncation_length = 4;
        truncate_to_repo = false;
      };
      git_branch = {
        symbol = " ";
        style = "bold #cba6f7";
      };
      git_status.style = "bold #f38ba8";
      python.symbol = " ";
      nodejs.symbol = " ";
      cmd_duration = {
        min_time = 2000;
        format = "took [$duration]($style) ";
      };
      character = {
        success_symbol = "[❯](bold #a6e3a1)";
        error_symbol = "[❯](bold #f38ba8)";
      };
    };
  };

  programs.fzf.enable = true;       # Ctrl+R history search, Ctrl+T file picker
  programs.zoxide.enable = true;    # `z <part-of-dir>` to jump around
  programs.bat.enable = true;
  programs.eza = {
    enable = true;                  # ls / ll / la / lt aliases
    icons = "auto";
    git = true;
  };
}
