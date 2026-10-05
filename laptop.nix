{
  config,
  pkgs,
  options,
  ...
}:

{
  services.swapspace.enable = true;
  services.swapspace.settings = {
    cooldown = 50;
    max_swapsize = "500M";
  };
  system.activationScripts.bcachefs-swapspace-compression = {
    deps = [ "stdio" ];
    text = ''
      # 1. Ensure the swapspace directory exists
      mkdir -p /var/lib/swapspace
      chmod 700 /var/lib/swapspace

      # 2. Check if bcachefs-tools are present and enforce foreground compression
      if [ -x "/run/current-system/sw/bin/bcachefs" ]; then
        /run/current-system/sw/bin/bcachefs set-file-option --compression=zstd /var/lib/swapspace
      fi
    '';
  };
  systemd.services.prepare-hibernation-swap = {
    description = "Evacuate primary swap partition to bcachefs swapspace files before hibernation";
    before = [ "systemd-hibernate.service" ];
    wantedBy = [ "systemd-hibernate.service" ];

    # Ensure bcachefs-tools are available to the service environment
    path = [
      pkgs.util-linux
    ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "prep-swap" ''
        set -e

        # 2. Force the kernel to aggressively compress the hibernation image
        echo 0 > /sys/power/image_size

        # 3. Safely drop memory caches to prevent OOM spikes during page movement
        echo 3 > /proc/sys/vm/drop_caches

        # 4. Find the first active partition-type swap device
        PRIMARY_SWAP=$(awk '$2 == "partition" {print $1; exit}' /proc/swaps)

        if [ -n "$PRIMARY_SWAP" ]; then
          echo "Evacuating active data from primary swap device: $PRIMARY_SWAP"
          # This will block and wait until evacuation is 100% complete
          swapoff "$PRIMARY_SWAP"
          # Reactivate the freshly emptied partition so it's ready for hibernation
          swapon "$PRIMARY_SWAP"
        else
          echo "No raw swap partition found in /proc/swaps. Skipping evacuation."
        fi
      '';
    };
  };

  hardware.bluetooth.enable = true;

  # Lock the screen when the phone walks away (RSSI offset below threshold, or unreachable)
  # ponytail: hcitool is deprecated; a looping l2ping holds the link up so no audio profile is needed
  security.wrappers.l2ping = {
    source = "${pkgs.bluez}/bin/l2ping";
    capabilities = "cap_net_raw+ep";
    owner = "root";
    group = "root";
  };
  systemd.user.services.phone-lock = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.bluez pkgs.gawk pkgs.glib ];
    script = ''
      MAC=64:9D:38:E5:5E:44
      T=-8 # tune: run `hcitool rssi $MAC` at the distance you want to lock
      n=0
      # keeps the link up; exits when the phone is unreachable, so retry
      while :; do /run/wrappers/bin/l2ping -d 5 $MAC >/dev/null || true; sleep 1; done &
      while sleep 5; do
        r=$(hcitool rssi $MAC 2>/dev/null | awk '{print $NF}')
        if [ -z "$r" ] || [ "$r" -lt "$T" ]; then n=$((n+1)); else n=0; fi
        if [ $n -eq 2 ]; then
          gdbus call --session --dest org.gnome.ScreenSaver --object-path /org/gnome/ScreenSaver \
            --method org.gnome.ScreenSaver.Lock || true
        fi
      done
    '';
    serviceConfig.Restart = "always";
  };

  networking.networkmanager.enable = true;

  # Screen orientation
  hardware.sensor.iio.enable = true;

  # Auto tune performance
  powerManagement.powertop.enable = true;

  # Use the power daemon thingie in Gnome
  # services.tlp.enable = false;
  # services.tlp.settings = {
  #   CPU_SCALING_GOVERNOR_ON_AC = "powersave";
  #   CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

  #   # # The following prevents the battery from charging fully to
  #   # # preserve lifetime. Run `tlp fullcharge` to temporarily force
  #   # # full charge.
  #   # # https://linrunner.de/tlp/faq/battery.html#how-to-choose-good-battery-charge-thresholds
  #   # START_CHARGE_THRESH_BAT0 = 40;
  #   # STOP_CHARGE_THRESH_BAT0 = 50;

  #   # CPU_MAX_PERF_ON_AC = 100;
  #   # CPU_MAX_PERF_ON_BAT = 60;
  # };

  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    iw
    lm_sensors
    powertop
  ];
}
