{ config, lib, pkgs, options, specialArgs, ... }:

# # https://github.com/NixOS/nixos-hardware/issues/179
# let
#   # nh = (builtins.getFlake (builtins.toString ./.)).outputs.nixos-hardware.nixosModules;
#   nh = nixos-hardware.nixosModules;
# in
let t = specialArgs.flakeInputs.nixos-hardware.nixosModules;
in {
  imports = [
    #t.lenovo-yoga-7-14ARH7.amdgpu
    #t.lenovo-yoga-7-14ARH7.nvidia
    # fixes white flashing
    t.common-cpu-amd-raphael-igpu
    # PRIME
    t.common-gpu-nvidia
    # hi res screen
    t.common-hidpi
    # enable pstate
    t.common-cpu-amd-pstate
  ];
  boot.kernelModules = [ "amdgpu" "kvm-amd" ];

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = true;
  systemd.enableEmergencyMode = true;
  boot.initrd.clevis.enable = true;
  # uses tpm2 to unlock, generate with `clevis encrypt tpm2`
  boot.initrd.clevis.devices.${config.fileSystems."/".device}.secretFile =
    ./disk-pw.jwe;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0ee58661-1e9f-4a10-9616-8350d5997c5f";
    fsType = "bcachefs";
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2FFA-D3E0";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  # active AMD pstate management
  services.auto-epp.enable = true;
  # Use PPD instead of TLP as recommended by AMD as claimed by FrameWork
  # https://community.frame.work/t/guide-fw13-ryzen-power-management/42988
  services.power-profiles-daemon.enable = true;

  # brightness sensor
  hardware.sensor.iio.enable = true;

  hardware.nvidia = {
    open = true;
    # temp to make it work again
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    #modesetting.enable = lib.mkDefault true;

    # This doesn't seem to do much and it causes a sleep attempt after wake
    #powerManagement.enable = lib.mkDefault true;

    prime = {
      #offload.enable = lib.mkForce false;
      amdgpuBusId = lib.mkDefault "PCI:64:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
}
