{ config, pkgs, options, lib, ... }:
let
  goConf = pkgs.runCommand "goConf" { }
    ''
      mkdir -p $out
      cp ${pkgs.netdata}/lib/netdata/conf.d/go.d.conf $out
      cp ${pkgs.netdata}/lib/netdata/conf.d/go.d/* $out
      chmod +w $out/*
      ${pkgs.yq-go}/bin/yq -Pi e '.modules.mysql = false' $out/go.d.conf
      ${pkgs.yq-go}/bin/yq -Pi e '.jobs += {"name": "agent", "url": "http://127.0.0.1:3001/metrics"}' $out/prometheus.conf
    '';
in
{
  # Don't kill BT on rebuild switch
  systemd.services.bluetooth.unitConfig.X-RestartIfChanged = false;

  systemd.services.netdata.serviceConfig.Type = "forking";
  systemd.services.netdata.serviceConfig.ExecStart = lib.mkForce
    "${pkgs.netdata}/bin/netdata -P /run/netdata/netdata.pid -d -c /etc/netdata/netdata.conf";

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

  # Use all the Nix goodness
  # hmm, maybe later
  # nixpkgs.config.contentAddressedByDefault = true;
  # nix-direnv assist
  nix.settings.keep-outputs = true;
  nix.settings.keep-derivations = true;
  # nix.extraOptions = ''
  #   # cache for CA builds
  #   substituters = https://cache.ngi0.nixos.org/
  #   trusted-public-keys = cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=
  # '';
  nix.settings.trusted-users = [ "root" "wmertens" ];

  # test screen
  # boot.kernelParams = [ "drm.debug=0xe" ];

  # Support NTFS
  boot.supportedFilesystems = [ "ntfs" ];

  services.sshguard.enable = true;
  services.fwupd.enable = true;
  services.netdata.enable = true;
  services.netdata.config = {
    global = {
      "debug log" = "syslog";
      "access log" = "syslog";
      "error log" = "syslog";
      "memory mode" = "dbengine";
      "page cache size" = 16;
      "dbengine multihost disk space" = 512;
    };
    "plugin:go.d" = {
      "command options" = "-c ${goConf}";
    };
  };
  services.nginx.virtualHosts.localhost = {
    # Make sure we don't accidentally serve wrong virtualhosts
    default = lib.mkForce true;
    # Serve /nginx_status, only on localhost
    locations = {
      "^~ /nginx_status" = {
        extraConfig = ''
          stub_status on;
          access_log off;
          allow 127.0.0.1;
          allow ::1;
          deny all;
        '';
      };
    };
  };
  services.nginx.enableReload = true;

  programs.droidcam.enable = true;
 
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

    # EID
    eid-mw

    # Printer
    gutenprint
    cnijfilter2

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
    # Sonos
    1400
  ];
  # mDNS support for Chromecast and Canon printing
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  # support SSDP https://serverfault.com/a/911286/9166
  networking.firewall.extraPackages = [ pkgs.ipset ];
  networking.firewall.extraCommands = ''
    if ! ipset --quiet list upnp; then
      ipset create upnp hash:ip,port timeout 3
    fi
    iptables -A OUTPUT -d 239.255.255.250/32 -p udp -m udp --dport 1900 -j SET --add-set upnp src,src --exist
    iptables -A nixos-fw -p udp -m set --match-set upnp dst,dst -j nixos-fw-accept
  '';

  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  networking.extraHosts = if builtins.pathExists ./extraHosts.conf then builtins.readFile ./extraHosts.conf else "";

  networking.networkmanager.plugins = [ pkgs.networkmanager-openconnect ];
  # services.osticket.enable = true;
  # services.osticket.withSetup = false;
  # services.osticket.virtualHost = { serverName = "localhost"; };
  # services.osticket.plugins = {
  #   inherit (pkgs.callPackage ./nixos/osticket/plugins.nix { }) slack;
  # };

  # # VirtualBox
  # virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.enableExtensionPack = true;
  # users.extraGroups.vboxusers.members = [ "wmertens" ];

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.allowedBridges = [ "all" ];
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /home/wmertens 192.168.122.0/24(rw,insecure,all_squash,anonuid=${toString config.users.extraUsers.wmertens.uid})
  '';

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

