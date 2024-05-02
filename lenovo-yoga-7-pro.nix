{ config, lib, pkgs, options, specialArgs, ... }:

# # https://github.com/NixOS/nixos-hardware/issues/179
# let
#   # nh = (builtins.getFlake (builtins.toString ./.)).outputs.nixos-hardware.nixosModules;
#   nh = nixos-hardware.nixosModules;
# in
let t = specialArgs.flakeInputs.nixos-hardware.nixosModules; in
{
  imports = [
    t.lenovo-yoga-7-14ARH7.amdgpu
    # # fixes white flashing
    t.common-cpu-amd-raphael-igpu
    # # PRIME
    t.common-gpu-nvidia
    # hi res screen
    t.common-hidpi
  ];

  # maybe not needed, for brightness sensor?
  hardware.sensor.iio.enable = true;

  hardware.nvidia = {
    modesetting.enable = lib.mkDefault true;
    powerManagement.enable = lib.mkDefault true;

    prime = {
      amdgpuBusId = lib.mkDefault "PCI:64:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
}
