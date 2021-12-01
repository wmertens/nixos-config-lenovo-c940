{ config, pkgs, options, lib, ... }:

{
  # External brightness
  boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
  boot.kernelModules = [ "ddcci" ];
  # i915 settings
  boot.extraModprobeConfig = "options i915 modeset=1 enable_fbc=1 fastboot=1";

  environment.systemPackages = with pkgs; [
    gnome3.gnome-tweak-tool
    gnome3.dconf-editor
    # appimage-run
    # Wayland
    wl-clipboard
    wlr-randr
    # Make ibus work on Chrome, maybe?
    #    ibus-qt
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "gnome3";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  services.xserver.libinput.enable = true;
  # Enable synthetic input
  hardware.uinput.enable = true;
  i18n.inputMethod.enabled = "ibus";
  # i18n.inputMethod.ibus.engines = with pkgs.ibus-engines; [
  #   typing-booster
  #   uniemoji
  # ];

  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.gnome.chrome-gnome-shell.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  services.flatpak.enable = true;
}

