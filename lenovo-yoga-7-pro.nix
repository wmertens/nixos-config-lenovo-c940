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

  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";

}
