{ config, pkgs, ... }:

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
