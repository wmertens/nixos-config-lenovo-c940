{ ... }:
{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      # onboarding (module defaults)
      "default_config"
      "met"
      "esphome"
      # Somfy Connectivity Kit (192.168.1.34) pairs locally over HomeKit
      "homekit_controller"
    ];
    config = {
      default_config = { };
      # Only reachable from this machine: http://localhost:8123
      http.server_host = [
        "127.0.0.1"
        "::1"
      ];
    };
  };
}
