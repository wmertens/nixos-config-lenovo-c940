# TODO add keyd group + palm rejection in nixpkgs; add support in stage1
{
  # make palm rejection work with keyd
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Serial Keyboards]
    MatchUdevType=keyboard
    MatchName=keyd virtual keyboard
    AttrKeyboardIntegration=internal
  '';

  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        # https://github.com/rvaiya/keyd/blob/master/docs/keyd.scdoc
        # play with it by
        # sudo bash -c 'cd /etc/keyd; cp -H default.conf t;mv -f t default.conf; chown wmertens default.conf'
        # and then edit /etc/keyd/default.conf + restart keyd
        # (be sure to retain the ids section at the top!)
        extraConfig = builtins.readFile ./keyd.conf;
      };
    };
  };
}
