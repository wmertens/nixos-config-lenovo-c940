{
  description = "NixOS configuration with flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, ... }:
    let
      system = "x86_64-linux";
      username = "wmertens";
      homeDirectory = "/home/${username}";
      # use own overlays
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    {
      # NixOS configuration
      nixosConfigurations.wmertens-nixos = nixpkgs.lib.nixosSystem {
        inherit system;
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

            # module._args = {
            #   inherit (self) modulesPath;            
            # };
          }

          ./configuration.nix
          # moved from c940 config
          nixos-hardware.nixosModules.common-cpu-amd
          nixos-hardware.nixosModules.common-pc-ssd
          nixos-hardware.nixosModules.common-pc-laptop
          nixos-hardware.nixosModules.common-pc-laptop-acpi_call
        ];
      };

      # Home-manager
      homeConfigurations = {
        wmertens = home-manager.lib.homeManagerConfiguration {
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
      };

      # allow `nix run . switch` to work as home-manager
      packages.x86_64-linux.default = home-manager.packages.x86_64-linux.default;
    };
}
