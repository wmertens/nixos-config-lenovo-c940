{ config, pkgs, ... }:

{
  #console.font = "Lat2-Terminus16";

  # don't include dejavu which has mono emoji glyphs
  #  fonts.enableDefaultFonts = false;
  fonts.fonts = with pkgs; [
    # fonts
    cascadia-code
    corefonts
    creep
    fantasque-sans-mono
    fira-code
    hack-font
    # defaults minus dejavu
    #    pkgs.xorg.fontbhlucidatypewriter100dpi
    #    pkgs.xorg.fontbhlucidatypewriter75dpi
    #    pkgs.dejavu_fonts
    #    pkgs.freefont_ttf
    #    pkgs.gyre-fonts # TrueType substitutes for standard PostScript fonts
    #    pkgs.liberation_ttf
    #    pkgs.xorg.fontbh100dpi
    #    pkgs.xorg.fontmiscmisc
    #    pkgs.xorg.fontcursormisc
    #    pkgs.unifont
    #    pkgs.noto-fonts-emoji
  ];

  fonts.fontconfig.defaultFonts = {
    monospace = [ "FreeMono" ];
    sansSerif = [ "FreeSans" ];
    serif = [ "FreeSerif" ];
  };

  fonts.fontconfig.localConf = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>

        <!-- Add generic family. -->
        <match target="pattern">
            <test qual="any" name="family"><string>emoji</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <!-- This adds Noto Color Emoji as a final fallback font for the default font families. -->
        <match target="pattern">
            <test name="family"><string>sans</string></test>
            <edit name="family" mode="append"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test name="family"><string>serif</string></test>
            <edit name="family" mode="append"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test name="family"><string>sans-serif</string></test>
            <edit name="family" mode="append"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test name="family"><string>monospace</string></test>
            <edit name="family" mode="append"><string>Noto Color Emoji</string></edit>
        </match>

        <!-- Block Symbola and DejaVu from the list of fallback fonts. -->
        <selectfont>
            <rejectfont>
                <pattern>
                    <patelt name="family">
                        <string>Symbola</string>
                    </patelt>
                </pattern>
            </rejectfont>
        </selectfont>

        <selectfont>
            <rejectfont>
                <pattern>
                    <patelt name="family">
                        <string>DejaVu</string>
                    </patelt>
                </pattern>
            </rejectfont>
        </selectfont>

        <!-- Use Noto Color Emoji when other popular fonts are being specifically requested. -->
        <match target="pattern">
            <test qual="any" name="family"><string>Apple Color Emoji</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test qual="any" name="family"><string>Segoe UI Emoji</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test qual="any" name="family"><string>Segoe UI Symbol</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test qual="any" name="family"><string>Android Emoji</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test qual="any" name="family"><string>Twitter Color Emoji</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test qual="any" name="family"><string>Twemoji</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test qual="any" name="family"><string>Twemoji Mozilla</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test qual="any" name="family"><string>TwemojiMozilla</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test qual="any" name="family"><string>EmojiTwo</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test qual="any" name="family"><string>Emoji Two</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test qual="any" name="family"><string>EmojiSymbols</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test qual="any" name="family"><string>Symbola</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>
        <match target="pattern">
            <test qual="any" name="family"><string>EmojiOne</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>

        <match target="pattern">
            <test qual="any" name="family"><string>EmojiOne Color</string></test>
            <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>
    </fontconfig>
  '';
}
