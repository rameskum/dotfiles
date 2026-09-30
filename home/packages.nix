{ pkgs, ... }:

{
  # Command-line tools from nixpkgs. Search: https://search.nixos.org/packages
  home.packages = with pkgs; [
    git
    ripgrep   # fast search
    fd        # fast find
    jq        # json on the command line
    htop
    uv
    nerd-fonts.hack
  ];

  fonts.fontconfig.enable = true;
}
