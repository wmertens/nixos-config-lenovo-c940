{ config, lib, pkgs, options, specialArgs, ... }:

# # https://github.com/NixOS/nixos-hardware/issues/179
# let
#   # nh = (builtins.getFlake (builtins.toString ./.)).outputs.nixos-hardware.nixosModules;
#   nh = nixos-hardware.nixosModules;
# in
let t = specialArgs.flakeInputs.nixos-hardware.nixosModules; in
{
  imports = [
    # t.lenovo-yoga-7-14ARH7.amdgpu
    # t.lenovo-yoga-7-14ARH7.nvidia
    # fixes white flashing
    t.common-cpu-amd-raphael-igpu
    # PRIME
    # t.common-gpu-nvidia
    # hi res screen
    t.common-hidpi
    # enable pstate
    t.common-cpu-amd-pstate
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  # active AMD pstate management
  services.auto-epp.enable = true;
  # Use PPD instead of TLP as recommended by AMD as claimed by FrameWork
  # https://community.frame.work/t/guide-fw13-ryzen-power-management/42988
  services.power-profiles-daemon.enable = true;

  # brightness sensor
  hardware.sensor.iio.enable = true;

  #hardware.nvidia = {
    #open = true;
    #modesetting.enable = lib.mkDefault true;
    #powerManagement.enable = lib.mkDefault true;

    #prime = {
      #offload.enable = lib.mkForce false;
      #amdgpuBusId = lib.mkDefault "PCI:64:0:0";
      #nvidiaBusId = "PCI:1:0:0";
    #};
  #};

  # console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";

  services.ollama.acceleration = "cuda";
}
