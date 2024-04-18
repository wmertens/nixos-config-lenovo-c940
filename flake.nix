{
  description = "NixOS configuration with flakes";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  outputs = { self, nixpkgs, nixos-hardware }: {
    nixosConfigurations.wmertens-nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
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
      # extraArgs = {
      #   inherit (self) modulesPath;
      # };
    };
  };
}
