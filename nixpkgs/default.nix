# Nixpkgs configuration

{ config, pkgs, options, ... }:

{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: rec {
    swapspace = pkgs.callPackage ./swapspace/default.nix { };
    #    gnome3.sushi = pkgs.callPackage ./sushi/default.nix { };
    # pam_ssh_agent_auth = pkgs.callPackage
    #   /home/wmertens/Projects/nixpkgs/pkgs/os-specific/linux/pam_ssh_agent_auth/default.nix
    #   { };
  };
}
