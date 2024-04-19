{ pkgs }: {

  #useChroot = true;
  allowUnfree = true;
  #allowBroken = true;
  allowUnsupportedSystem = true;

  #replaceStdenv = { pkgs }: pkgs.ccacheStdenv;
  packageOverrides = pkgs: rec {
    #chromiumDev = pkgs.chromiumDev.override { useOzone = true; };
    /* ccacheWrapper = pkgs.ccacheWrapper.override {
       			extraConfig = ''
       				export CCACHE_COMPRESS=1 CCACHE_DIR=/nix/var/ccache CCACHE_UMASK=002
       			'';
       		};
    */
    # duperemove = pkgs.callPackage ./duperemove.nix { };
    wout-scripts = pkgs.callPackage ./wout-scripts.nix { };
    z = pkgs.callPackage ./z.nix { };
    # afsctool = pkgs.callPackage ./afsctool.nix {
    #   inherit (pkgs.darwin.apple_sdk.frameworks) CoreServices;
    # };
    #	rethinkdb = pkgs.callPackage ./rethinkdb.nix {};
    #watchman = pkgs.callPackage ./watchman.nix {
    #inherit (pkgs.darwin) CF_new;
    #};
    # wkhtmltopdf = pkgs.callPackage ./wkhtmltopdf.nix {
    #   overrideDerivation = pkgs.lib.overrideDerivation;
    # };

    /* v8_3_30_33_16 = pkgs.callPackage <nixpkgs/pkgs/development/libraries/v8/generic.nix> {
       			inherit (pkgs.pythonPackages) gyp;
       			version = "3.30.33.16";
       			sha256 = "1azf1b36gqj4z5x0k9wq2dkp99zfyhwb0d6i2cl5fjm3k6js7l45";
       		};
    */
  };
}
