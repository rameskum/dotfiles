{ config, pkgs, username, ... }:

{
  nix.enable = false;

  nixpkgs.config.allowUnfree = true; 

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  system.stateVersion = 6;
}
