{ config, pkgs, options, ... }:

{
  # # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;
  # hardware.pulseaudio.support32Bit = true;
  # hardware.pulseaudio.package = pkgs.pulseaudioFull;
  # hardware.pulseaudio.extraModules = [ pkgs.pulseaudio-modules-bt ];

  #  hardware.bluetooth.hsphfpd.enable = true;

  users.extraUsers.wmertens.extraGroups = [ "audio" ];

  # Pipewire config
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
    wireplumber.enable = true;
    # Better Bluetooth calls
    # media-session.config.bluez-monitor.rules = [
    #   {
    #     # Matches all cards
    #     matches = [{ "device.name" = "~bluez_card.*"; }];
    #     actions = {
    #       "update-props" = {
    #         "bluez5.auto-connect" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
    #       };
    #     };
    #   }
    # {
    #   matches = [
    #     # Matches all sources
    #     { "node.name" = "~bluez_input.*"; }
    #     # Matches all outputs
    #     { "node.name" = "~bluez_output.*"; }
    #   ];
    #   actions = {
    #     "node.pause-on-idle" = false;
    #   };
    # }

    # {
    # # Allow a phone etc to use this computer as a bluetooth "speaker"
    #  matches = [ { "device.name" = "bluez_card.PHONE_MAC_HERE"; } ];
    #    actions = {
    #      "update-props" = {
    #       "bluez5.auto-connect" = [ "hfp_ag" "hsp_ag" "a2dp_source" ];
    #       "bluez5.a2dp-source-role" = "input";
    #     };
    #  };
    #}
    # ];
  };
}
