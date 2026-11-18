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
  boot.kernelParams = [ "resume=${(builtins.head config.swapDevices).device}" ];
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
        PRIMARY_SWAP=${(builtins.head config.swapDevices).device}

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
  # ponytail: hcitool is deprecated; an open PAN (tethering) link keeps the phone from dropping the connection
  # requires "Bluetooth tethering" on in the phone
  # NM ignores the raw bnep interface (udev renames it too); it tethers via its own bluetooth device type.
  # phone-link: IP-less link held by the phone-lock service. phone-tether: never auto-activated;
  # `nmcli connection up phone-tether` (or the GNOME button) switches to it, metric 900 > wifi 600.
  # Both must go through NM: a raw BlueZ Network1.Connect would make NM's own connect fail ("in progress").
  networking.networkmanager.ensureProfiles.profiles.phone-link = {
    connection = { id = "phone-link"; type = "bluetooth"; autoconnect = false; };
    bluetooth = { bdaddr = "64:9D:38:E5:5E:44"; type = "panu"; };
    ipv4.method = "disabled";
    ipv6.method = "disabled";
  };
  networking.networkmanager.ensureProfiles.profiles.phone-tether = {
    connection = { id = "phone-tether"; type = "bluetooth"; metered = 1; autoconnect = false; };
    bluetooth = { bdaddr = "64:9D:38:E5:5E:44"; type = "panu"; };
    ipv4 = { method = "auto"; route-metric = 900; };
    ipv6.method = "disabled";
  };
  systemd.user.services.phone-lock = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.bluez pkgs.gawk pkgs.glib pkgs.networkmanager ];
    script = ''
      MAC=64:9D:38:E5:5E:44
      T=-13 # tune: run `hcitool rssi $MAC` at the distance you want to lock
      n=0
      # hold the link: when NM's phone device is idle (30 = disconnected), bring up the IP-less profile.
      # Does nothing while tethering (phone-tether active) or while the phone is away (fails harmlessly).
      while :; do
        case $(nmcli -t -g GENERAL.STATE device show $MAC 2>/dev/null) in 30*) nmcli connection up phone-link >/dev/null 2>&1 || true;; esac
        sleep 5
      done &
      while sleep 2; do
        r=$(hcitool rssi $MAC 2>/dev/null | awk '{print $NF}')
        if [ -z "$r" ] || [ "$r" -lt "$T" ]; then n=$((n+1)); else n=0; fi
        if [ $n -eq 5 ]; then # 5x2s = 10s, rides out the phone's 60s link reset (~5s gap)
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

  # Allow access to XReal S1
  # ponytail: must be <73 (not extraRules/99-local) or uaccess ACLs aren't applied
  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/rules.d/70-xreal.rules" ''
      KERNEL=="hidraw*", ATTRS{idVendor}=="3318", TAG+="uaccess"
    '')
  ];

  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    iw
    lm_sensors
    powertop
  ];
}
