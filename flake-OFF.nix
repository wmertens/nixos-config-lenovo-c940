{
  description = "NixOS configuration with flakes";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  outputs = { self, nixpkgs, nixos-hardware }: {
    nixosConfigurations.wmertens-nixos = nixpkgs.lib.nixosSystem {
      modules = [
        # ...
        # add your model from this list: https://github.com/NixOS/nixos-hardware/blob/flakes/flake.nix
        nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
      ];
    };
  };
}
