{
  description = "Ubuntu dotfiles managed with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
  let
    system = "x86_64-linux";

    # bootstrap.sh rewrites the `username = "...";` line, so keep it on one line.
    username = "rameskum";
    gitName = "Ramesh Kumar";
    gitEmail = "rameskum.ms@outlook.com";
  in {
    homeConfigurations."ubuntu" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = { inherit username gitName gitEmail; };
      modules = [ ./home ];
    };

    # `nix run .` gives the home-manager CLI pinned by flake.lock, which
    # rebuild.sh uses before home-manager itself is installed.
    packages.${system}.default = home-manager.packages.${system}.default;
  };
}
