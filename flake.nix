{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      # The one username line to change if this isn't your machine.
      # bootstrap.sh offers to rewrite this for you if your Linux username differs.
      user = "rameskum";
      gitName = "Ramesh Kumar";
      gitEmail = "rameskum.ms@outlook.com";
    in
    {
      homeConfigurations."ubuntu" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit user gitName gitEmail; };
        modules = [ ./home.nix ];
      };

      # `nix run .` is the home-manager CLI pinned by flake.lock; rebuild.sh uses it.
      packages.${system}.default = home-manager.packages.${system}.default;
    };
}
