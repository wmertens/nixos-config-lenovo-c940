{ config, pkgs, options, ... }:

{
  # Don't kill BT on rebuild switch
  systemd.services.bluetooth.unitConfig.X-RestartIfChanged = false;

  imports = [
    # Customisations over default nixpkgs tree
    ./nixos/default.nix
    ./nixpkgs/default.nix

    # own configurations
    ./lenovo-c940.nix
    ./hardware-configuration.nix
    ./common.nix
    ./laptop.nix
    ./btrfs.nix
    ./fonts.nix
    ./sound.nix
    ./gui.nix
  ];

  # todo nice boot screen with windows selection
  # todo cpufreq governor GUI

  # Use flakes
  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # test screen
  # boot.kernelParams = [ "drm.debug=0xe" ];

  services.fwupd.enable = true;

  networking.hostName = "wmertens-nixos"; # Define your hostname.

  # Select internationalisation properties.
  #i18n = {
  #defaultLocale = "en_US.UTF-8";
  #};
  console.keyMap = "us";

  # Set your time zone.
  time.timeZone = "Europe/Brussels";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    binutils-unwrapped # strings etc

    # ntfs3g
    # libguestfs
    # libguestfs-appliance

    eid-mw

    # chromecast
    (google-chrome.override {
      # Chromecast
      commandLineArgs = "--load-media-router-component-extension=1";
    })
  ];

  # EID
  services.pcscd.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  security.pam.enableSSHAgentAuth = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  networking.firewall.allowedTCPPorts = [
    # web
    80
    443
    # sonos and upnp
    1400
    3400
    3401
    3500
    40151
  ];
  networking.firewall.allowedUDPPorts = [ 136 137 138 139 1900 1901 6969 ];
  # Chromecast
  services.avahi.enable = true;

  networking.firewall.extraPackages = [ pkgs.conntrack_tools ];
  networking.firewall.autoLoadConntrackHelpers = true;
  networking.firewall.extraCommands = ''
    nfct add helper ssdp inet udp
    iptables --verbose -I OUTPUT -t raw -p udp --dport 1900 -j CT --helper ssdp
  '';
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  networking.extraHosts = "127.0.0.1 cordeel-sync.stratokit.io";

  # Home Assistant
  services.home-assistant.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.jane = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };
  users.users.wmertens = {
    description = "Wout Mertens";
    uid = 1000;
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMy/AItxfpvrKf+bS9CK3rMwv4vhHEGhU3toAMqE+WQWebSVrEZvKIE3hE+o8ysVmTleKmU5in1h1yubVmUUfjY= /home/wmertens/.ssh/id_ecdsa"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}

