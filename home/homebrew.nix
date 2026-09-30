{
  # Homebrew formulae (https://formulae.brew.sh). Anything installed with
  # `brew install` that is not listed here is uninstalled on the next rebuild.
  # Casks are macOS-only; put GUI apps in ubuntu/apt-apps.sh instead.
  homebrew = {
    enable = true;
    cleanup = true;

    taps = [ ];

    formulae = [
      "nvm"
      "wget"
      "gh"
    ];
  };

  programs.zsh.initContent = ''
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]; then
      mkdir -p "$NVM_DIR"
      . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
    fi
  '';
}
