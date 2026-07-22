{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Tune font rendering like macOS
  environment.variables = {
    # Enable stem darkening
    FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
  };

  fonts = {
    fontconfig = {
      # no subpixel tricks, we're HiDPI
      subpixel = {
        lcdfilter = "none";
        rgba = "none";
      };
      # slight hinting and antialiasing
      hinting.style = "slight";
      antialias = true;

      # fontconfig 2.18 lets generic fallbacks outrank these exact family names.
      confPackages = [
        (pkgs.writeTextDir "etc/fonts/conf.d/99-ms-corefonts.conf" ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            ${lib.concatMapStrings
              (family: ''
                <match target="pattern">
                  <test qual="first" name="family" compare="eq"><string>${family}</string></test>
                  <edit name="family" mode="assign"><string>${family}</string></edit>
                  <edit name="genericfamily" mode="delete"/>
                </match>
              '')
              [
                "Arial"
                "Arial Black"
                "Courier New"
                "Georgia"
                "Impact"
                "Tahoma"
                "Times New Roman"
                "Trebuchet MS"
                "Verdana"
                "Webdings"
              ]
            }
          </fontconfig>
        '')
      ];

      #   localConf = ''
      #     <?xml version="1.0"?>
      #     <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      #     <fontconfig>
      #       <alias binding="weak">
      #         <family>monospace</family>
      #         <prefer>
      #           <family>emoji</family>
      #         </prefer>
      #       </alias>
      #       <alias binding="weak">
      #         <family>sans-serif</family>
      #         <prefer>
      #           <family>emoji</family>
      #         </prefer>
      #       </alias>
      #       <alias binding="weak">
      #         <family>serif</family>
      #         <prefer>
      #           <family>emoji</family>
      #         </prefer>
      #       </alias>
      #     </fontconfig>
      #           '';
      #   defaultFonts = {
      #     emoji = [ "Noto Color Emoji" ];
      #     monospace = [ "FreeMono" ];
      #     sansSerif = [ "FreeSans" ];
      #     serif = [ "FreeSerif" ];
      #   };
    };
    packages = with pkgs; [
      noto-fonts-color-emoji

      agave
      cascadia-code
      corefonts
      creep
      fantasque-sans-mono
      fira-code
      hack-font
      intel-one-mono
      monaspace
    ];
  };

}
