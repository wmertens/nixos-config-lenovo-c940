{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.swapspace;
in {
  ###### interface

  options = {

    services.swapspace = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to create swapfiles dynamically using the SwapSpace manager.
          Files will be added and removed based on current memory usage.
        '';
      };

      path = mkOption {
        type = types.path;
        default = "/var/lib/swap";
        description = ''
          Location of the swap files. This directory will be restrticted to root.
        '';
      };

      cooldown = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Cooldown period between changes.
          SwapSpace will wait at least this many seconds before an action,
          like removing a swapfile after adding one.
        '';
      };

      minSwapSize = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Minimum size of a swapfile.
        '';
      };

      maxSwapSize = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Maximum size of a swapfile.
        '';
      };

      extraArgs = mkOption {
        type = types.str;
        default = "";
        description = ''
          Any extra arguments to pass to SwapSpace.
        '';
        example = "-P -v -u 5";
      };
    };
  };

  ###### implementation

  config = mkIf cfg.enable {
    systemd.services.swapspace = with pkgs; {
      description = "SwapSpace Daemon";
      preStart = ''
        set -e
        p="${cfg.path}"
        if [ ! -e "$p" ]; then
          mkdir -p "$p"
          # Test if btrfs fs, don't load the dependency
          if btrfs fi df "$p" >/dev/null 2>&1; then
            rmdir "$p"
            # Make a separate subvol so noCOW does not inhibit snapshots
            btrfs subvol create "$p"
          fi
        fi
        chmod 700 "$p"
      '';
      serviceConfig = {
        Type = "simple";
        ExecStart =
          ''${pkgs.swapspace}/sbin/swapspace --swappath="${cfg.path}"''
          + optionalString (cfg.cooldown != null)
          " --cooldown=${toString cfg.cooldown}"
          + optionalString (cfg.minSwapSize != null)
          " --min_swapsize=${toString cfg.minSwapSize}"
          + optionalString (cfg.maxSwapSize != null)
          " --max_swapsize=${toString cfg.maxSwapSize}" + " ${cfg.extraArgs}";
        Restart = "always";
        RestartSec = 30;
      };
      after = [ "local-fs.target" "systemd-udev-settle.service" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
