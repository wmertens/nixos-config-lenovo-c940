{ config, pkgs, lib, ... }: {
  
  services.beesd.filesystems = {
    store = {
      spec = "LABEL=root";
    };
  };
  
  systemd.timers = {
    btrfsBalance = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        AccuracySec = "1d";
        Persistent = true;
      };
    };
    # btrfsDedupe = {
    #   wantedBy = [ "timers.target" ];
    #   timerConfig = {
    #     OnCalendar = "daily";
    #     AccuracySec = "1d";
    #     Persistent = true;
    #   };
    # };
  };
  systemd.services = {
    # TODO scrub after boot and daily
    btrfsBalance = {
      serviceConfig = {
        Type = "exec";
        Nice = 19;
        IOSchedulingClass = "idle";
        ExecStart =
          "${pkgs.btrfs-progs}/bin/btrfs fi balance start -musage=50 -dusage=50 /";
      };
    };
  #   btrfsDedupe = {
  #     path = [ pkgs.utillinux ]; # Used to get # of CPUs
  #     serviceConfig = {
  #       Type = "exec";
  #       IOSchedulingClass = "idle";
  #       RuntimeMaxSec = 7200; # It can hang sometimes
  #       Restart = "on-failure";
  #       ExecStart =
  #         "${pkgs.duperemove}/bin/duperemove -rdhA -v --hashfile=/duperemove-hashes.db /";
  #     };
  #   };
  };
}
