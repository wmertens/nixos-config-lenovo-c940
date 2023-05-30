# Lenovo C940 specific settings
# Everything works except for the fingerprint scanner - it doesn't have an OSS driver,
# it's a Synaptics device with Match-On-Host recognition so unlikely to ever work with Linux

{ config, lib, pkgs, options, nixos-hardware, ... }:

# # https://github.com/NixOS/nixos-hardware/issues/179
# let
#   # nh = (builtins.getFlake (builtins.toString ./.)).outputs.nixos-hardware.nixosModules;
#   nh = nixos-hardware.nixosModules;
# in
{
  imports = [
    # nixos-hardware configurations
    # (nh + "/common/cpu/intel")
    # (nh + "/common/pc/ssd")
    # (nh + "/common/pc/laptop")
    # (nh + "/common/pc/laptop/acpi_call.nix")

    # disabled due to flakes
    # <nixos-hardware/common/cpu/intel>
    # <nixos-hardware/common/pc/ssd>
    # <nixos-hardware/common/pc/laptop>
    # <nixos-hardware/common/pc/laptop/acpi_call.nix>
  ];

  # Rotation support for tablet modes
  # TODO figure out disabling keyboard/trackpad
  hardware.sensor.iio.enable = true;

  hardware.video.hidpi.enable = true;
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";

  # Audio
  boot.blacklistedKernelModules = [ "snd_hda_intel" "snd_soc_skl" ];

  # platform api
  services.udev.extraRules = ''
    DRIVERS=="ideapad_acpi", GROUP="wheel", MODE="0664"
  '';

  # This can be removed when PulseAudio is at least version 14
  # https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_X1_Carbon_(Gen_7)#Audio
  hardware.pulseaudio.extraConfig = ''
    load-module module-alsa-sink   device=hw:0,0 channels=4
    load-module module-alsa-source device=hw:0,6 channels=4
  '';
}
