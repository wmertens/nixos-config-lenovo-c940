{ config, pkgs, ... }:

{
  fonts = {
    # fontconfig = {
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
    # };
    fonts = with pkgs; [
      noto-fonts-emoji

      cascadia-code
      corefonts
      creep
      fantasque-sans-mono
      fira-code
      hack-font
      #intel-one-mono
    ];
  };

}
