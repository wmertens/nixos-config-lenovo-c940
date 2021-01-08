{ config, pkgs, options, ... }:

{
  # audio support
  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.pulseaudio.extraModules = [ pkgs.pulseaudio-modules-bt ];
}
