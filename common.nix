{ config, pkgs, lib, ... }:

{
  nixpkgs.system = "x86_64-linux";
  nix.autoOptimiseStore = true;
  nix.extraOptions = ''
    experimental-features = nix-command
  '';

  # Use zram swapping
  zramSwap.enable = true;

  boot.cleanTmpDir = true;

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
    permitRootLogin = lib.mkForce "without-password";
  };

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

  programs.bash.enableCompletion = true;
}
