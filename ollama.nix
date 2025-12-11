{ config, pkgs, options, lib, specialArgs, ... }: {
  services.ollama = {
    #enable = true;
    #acceleration = "cuda";
  };
  services.open-webui = {
    #enable = true;
    port = 4000;
    package = pkgs.open-webui;
  };
  #environment.systemPackages = with pkgs; [ ollama-cuda ffmpeg ];
  nixpkgs.config = {
    allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [ "cuda_cudart" ];
  };
}
