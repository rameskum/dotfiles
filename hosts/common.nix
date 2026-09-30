{ config, pkgs, username, gitName, gitEmail, isMac, ... }:

{
  home.username = username;
  home.homeDirectory = if isMac then "/Users/${username}" else "/home/${username}";
  home.stateVersion = "26.05";

  # Pure Nix CLI packages
  home.packages = with pkgs; [
    git
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    htop      
    uv
    zsh
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nano";

  # ----------------------------------------------------
  # Homebrew Configurations (Managed via home-manager-brew)
  # ----------------------------------------------------
  homebrew = {
    enable = true;
    
    # Automatically clean up packages not declared here (Optional: set to false if preferred)
    cleanup = true; 

    # Command-line packages via Brew (Works on Linux & Mac)
    formulae = [
      "nvm"
      "wget"
      "gh"
    ];

    # GUI Applications via Casks 
    # (Note: On Linux, Homebrew handles casks gracefully or skips safely)
    casks = [
      "visual-studio-code"
    ] ++ (if isMac then [
	"alfred"
    ] else []);
  };

  # Git Configuration
  programs.git = {
    enable = true;
    settings = {
      user.name = gitName;
      user.email = gitEmail;
    };
  };

  # Zsh Shell Configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.home-manager.enable = true;
}
