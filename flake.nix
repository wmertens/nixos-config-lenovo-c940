{
  description = "NixOS configuration with flakes";

  inputs = {
    nix.url = "github:NixOS/nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, nix-alien, nix, ...
    }@flakeInputs:
    let
      system = "x86_64-linux";
      username = "wmertens";
      homeDirectory = "/home/${username}";
      # use own overlays
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default nix-alien.overlays.default ];
      };
      # todo get the path programmatically. Needs to be the source, not the output path
      flakePath = "/home/wmertens/Projects/wout-config";

      hm = let realHM = home-manager.packages.${system}.default;
      in pkgs.writeScriptBin "home-manager" ''
        function getLink() {
          realpath /nix/var/nix/profiles/per-user/$USER/profile
        }
        prev=`getLink`
        # Use path: to include the secrets
        ${realHM}/bin/home-manager --flake path:${flakePath} "$@"
        exitcode=$?
        if [ $exitcode -eq 0 ]; then
          next=`getLink`
          if [ "$prev" != "$next" ]; then
            nix store diff-closures $prev $next
          fi
        fi
        exit $exitcode
      '';
      # todo secrets so we can use flake instead of path:
      nixos = pkgs.writeScriptBin "nixos" ''
        function getLink() {
          realpath /nix/var/nix/profiles/system
        }
        prev=`getLink`
        if [ -n "$1" ]; then
          action="$1"
          shift
        else
          action=switch
        fi
        set -x
        # Use path: to include the secrets
        sudo ${pkgs.nixos-rebuild}/bin/nixos-rebuild $action --flake path:${flakePath} "$@"
        exitcode=$?
        set +x
        if [ $exitcode -eq 0 ]; then
          next=`getLink`
          if [ "$prev" != "$next" ]; then
            nix store diff-closures $prev $next
          fi
        fi
        exit $exitcode
      '';
    in {
      # Our overlays
      overlays.default = (final: prev: {
        wout-scripts = final.callPackage ./home/wout-scripts.nix { };
        google-chrome = prev.google-chrome.override {
          commandLineArgs =
            "--enable-features=TouchpadOverscrollHistoryNavigation";
        };
        cursor = prev.cursor.override {
          commandLineArgs = "--ozone-platform-hint=wayland";
        };
        home-manager = hm;
        fortune = prev.fortune.override { withOffensive = true; };
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
          # add the helper scripts to the path
          { environment.systemPackages = [ hm nixos ]; }

          ./configuration.nix
        ];
      };

      # Home-manager
      homeConfigurations.wmertens = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit flakeInputs system; };
        modules = [
          {
            # home-manager config
            home = {
              inherit username homeDirectory;
              stateVersion = "22.05";
            };
            nix.registry.N = {
              from = {
                type = "indirect";
                id = "N";
              };
              flake = nixpkgs;
            };
          }

          ./home
        ];
      };

      packages.${system} = {
        # allow `nix run . switch` to work as home-manager with the current flake
        default = hm;
        home-manager = hm;
        inherit nixos;
      };
    };
}
