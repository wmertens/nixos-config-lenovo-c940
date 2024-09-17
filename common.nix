{ config, pkgs, lib, ... }:

{
  nixpkgs.system = "x86_64-linux";
  nix.settings.auto-optimise-store = true;
  nix.settings.experimental-features = "nix-command flakes ca-derivations";

  # Use zram swapping
  zramSwap.enable = true;

  boot.tmp.cleanOnBoot = true;

  networking.resolvconf.extraConfig = ''
    name_servers_append="1.1.1.1"
  '';

  services.journald.extraConfig = ''
    RateLimitBurst=1500
    RateLimitIntervalSec=2
    SystemKeepFree=1.5G
  '';

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = lib.mkForce "without-password";
  };

  # SSH: set compression
  programs.ssh.extraConfig = ''
    Host * !localhost
      Compression yes
  '';

  environment.systemPackages = with pkgs; [
    vim
    git
    psmisc
    lsof
    screen
    tree
    file
    coreutils
    inetutils
    dig
  ];

  programs.bash.completion.enable = true;
}
