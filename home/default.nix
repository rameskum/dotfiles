{ username, ... }:

{
  imports = [
    ../modules/homebrew.nix
    ./packages.nix
    ./homebrew.nix
    ./git.nix
    ./shell.nix
    ./wezterm.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  # Sources Nix in login shells and exposes Nix apps to the desktop.
  targets.genericLinux.enable = true;
  # GUI apps come from apt (see ubuntu/apt-apps.sh), so Nix never needs the GPU.
  targets.genericLinux.gpu.enable = false;

  home.sessionVariables.EDITOR = "nano";

  programs.home-manager.enable = true;
}
