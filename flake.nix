{
  description = "NixOS configuration with flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien.url = "github:thiagokokada/nix-alien";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, nix-alien, ... } @ flakeInputs:
    let
      system = "x86_64-linux";
      username = "wmertens";
      homeDirectory = "/home/${username}";
      # use own overlays
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default nix-alien.overlays.default ];
      };
    in
    {
      # Our overlays
      overlays.default = (final: prev: {
        wout-scripts = final.callPackage ./home/wout-scripts.nix { };
        google-chrome = prev.google-chrome.override { commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation"; };
        home-manager = let hm = home-manager.packages.${system}.default; in prev.writeScriptBin "home-manager" ''${hm}/bin/home-manager --flake ${self.outPath} "$@"'';
      });

      # NixOS configuration
      nixosConfigurations.wmertens-nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit flakeInputs system; };
        modules = [
          # Use the flake path for the nix path
          {
            nix.nixPath = [
              # Point to a stable path so system updates immediately update
              "nixpkgs=/run/current-system/nixpkgs"
              # Allow using nixos-option to query current config
              "nixos-config=/run/current-system/flake/configuration.nix"
            ];
            system.extraSystemBuilderCmds = ''
              ln -s ${nixpkgs.outPath} $out/nixpkgs
              ln -s ${self.outPath} $out/flake
            '';
            nix.registry.nixpkgs.flake = self.inputs.nixpkgs;
          }

          ./configuration.nix
        ];
      };

      # Home-manager
      homeConfigurations.wmertens = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          {
            # home-manager config
            home = {
              inherit username homeDirectory;
              stateVersion = "22.05";
            };
            nix.registry.N =
              {
                from = { type = "indirect"; id = "N"; };
                flake = nixpkgs;
              };
          }

          ./home
        ];
      };

      # allow `nix run . switch` to work as home-manager with the current flake
      packages.${system}.default = pkgs.home-manager;
    };
}
