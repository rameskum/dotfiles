{
  description = "dotfiles";

  inputs = {
    # Strictly locked to Nixpkgs stable release 26.05
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Cross-platform Homebrew module for Home Manager (works on Linux & macOS)
    homebrew-nix = {
      url = "github:koalalorenzo/home-manager-brew";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, homebrew-nix, ... }@inputs:
  let
    # ==========================================================
    # SINGLE SOURCE OF TRUTH (Common Variables)
    # ==========================================================
    username = "rameskum";
    gitName = "Ramesh Kumar";
    gitEmail = "rameskum.ms@outlook.com";
  in {
    
    # ----------------------------------------------------
    # 1. macOS System Configuration (nix-darwin)
    # ----------------------------------------------------
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin"; # Use "x86_64-darwin" for Intel Macs
      modules = [
        ./hosts/darwin.nix
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          
          home-manager.extraSpecialArgs = {
            inherit username gitName gitEmail;
            isMac = true;
          };

          home-manager.users.${username} = {
            imports = [ 
              ./hosts/common.nix
	      homebrew-nix.homeManagerModules.default
            ];
          };
        }
      ];
    };

    # ----------------------------------------------------
    # 2. Ubuntu / Linux System Configuration (Standalone HM)
    # ----------------------------------------------------
    homeConfigurations."ubuntu" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      
      extraSpecialArgs = {
        inherit username gitName gitEmail;
        isMac = false;
      };

      modules = [
        ./hosts/common.nix
	homebrew-nix.homeManagerModules.default
      ];
    };
  };
}
