{
  pkgs,
  lib,
  flakeInputs,
  ...
}:

let
  user = "wmertens";
  mainHost = "wmertens-nixos";
in
rec {
  imports = [ flakeInputs.pnpm-nix-provider.homeManagerModules.default ];

  # pnpm materializes node_modules from the Nix store; impure host-builds
  # whatever the sandbox can't (network postinstalls), transparently.
  programs.pnpm-nix-provider = {
    enable = true;
    impure = true;
  };

  nixpkgs.config = {
    # permittedInsecurePackages = [ "electron-11.5.0" ];
    allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "google-chrome"
        "slack"
        "vscode-extension-ms-vsliveshare-vsliveshare"
        "vscode"
        "cursor"
        "cuda_cudart"
        "antigravity"
        "claude-code"
        "codex"
      ];
  };

  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;

  #wayland.windowManager.hyprland.enable = true; # enable Hyprland

  #services.pulseeffects.enable = true;

  # we use the one from the flake
  # programs.home-manager.enable = true;

  #  programs.go.enable = true;

  # Uses quite a lot of cpu for an idle service
  # services.keybase.enable = true;
  # services.kbfs.enable = true;

  # eID
  xdg.configFile."chromium/NativeMessagingHosts/eu.webeid.json".source =
    "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";
  xdg.configFile."google-chrome/NativeMessagingHosts/eu.webeid.json".source =
    "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";

  programs.vscode = {
    enable = true;
    profiles.default.extensions = with pkgs.vscode-extensions; [ ms-vsliveshare.vsliveshare ];
  };

  programs.autojump.enable = true;

  programs.direnv.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "Wout.Mertens@gmail.com";
        name = "Wout Mertens";
      };
      merge.ff = "false";
      pull.ff = "only";
      #commit.gpgsign = true;
      init.defaultBranch = "main";
    };
  };
  #// ssh
  #  //

  home.file.".inputrc".source = ./inputrc;
  home.file.".screenrc".source = ./screenrc;
  home.file.".vimrc".source = ./vimrc;
  home.file.".ssh/config" = {
    target = ".ssh/config_source";
    onChange = "cp -f ~/.ssh/config_source ~/.ssh/config && chmod 400 ~/.ssh/config";
    text =
      let
        base = builtins.readFile ./ssh_config;
        extra =
          if builtins.pathExists ./secrets/ssh_config then builtins.readFile ./secrets/ssh_config else "";
      in
      ''
        # managed by home-manager
        ${base}
        ${extra}'';
  };

  # run-or-raise gnome extension
  home.file.".config/run-or-raise/shortcuts.conf".text = ''
    # managed by home-manager
    # The shortcuts may be defined in two ways:
    #
    # 1. Run-or-raise form: shortcut,launch-command,[wm_class],[title]
    #        * wm_class and title are optional and case sensitive
    #        * if none is set, lowercased launch-command is compared with lowercased windows wm_classes and titles
    #
    # 2. Run only form: shortcut,calculate 
    #
    # How to know wm_class? Alt+f2, lg, "windows" tab (at least on gnome)

    # This line cycles any firefox window (matched by "firefox" in the window title) OR if not found, launches new firefox instance.
    # <Super>f,firefox,,
    # This line cycles any open gnome-terminal (matched by wm_class = Gnome-terminal on Ubuntu 17.10) OR if not found, launches new one.
    #<Super>r,gnome-terminal,Gnome-terminal,

    # You may use regular expression in title or wm_class.
    # Just put the regular expression between slashes. 
    # E.g. to jump to pidgin conversation window you may use this line
    # (that means any windows of wm_class Pidgin, not containing the title Buddy List)"
    # <Super>KP_1,pidgin,Pidgin,/^((?!Buddy List).)*$/

    # Have the mail always at numpad-click.
    # <Super>KP_2,chromium-browser --app=https://mail.google.com/mail/u/0/#inbox

    <Super><Ctrl><Alt><Shift>Q,sqlitebrowser,,SQLite
    <Super><Ctrl><Alt><Shift>K,code,code,,
    # <Super><Ctrl><Alt><Shift>K,cursor,cursor,,
    <Super><Ctrl><Alt><Shift>A,gnome-system-monitor,,
    # <Super><Ctrl><Alt><Shift>T,konsole,org.kde.konsole,
    <Super><Ctrl><Alt><Shift>T,ghostty,com.mitchellh.ghostty,
    # <Super><Ctrl><Alt><Shift>T,kitty,kitty

    # =============
    # Run only form
    # =============

    # open a konsole window
    # <Super><Ctrl><Alt><Shift>D,${pkgs.wout-scripts}/bin/new-konsole
    # open devdocs.io in a new chrome app window (should only open one but can't find how to do that)
    <Super><Ctrl><Alt><Shift>D,${pkgs.google-chrome}/bin/google-chrome-stable --profile-directory=Default --app-id=ahiigpfcghkbjfcibpojancebdfjmoop,chrome-ahiigpfcghkbjfcibpojancebdfjmoop-Default,DevDocs
    # --app=https://devdocs.io

    # Blank lines are allowed. Line starting with "#" means a comment.
    # Now delete these shortcuts and put here yours.
    # How to know wm_class? Alt+f2, lg, "windows" tab (at least on Ubuntu 17.10)
  '';

  home.sessionVariables = {
    #ibus
    GTK_IM_MODULE = "ibus"; # Fix for Chrome
    QT_IM_MODULE = "ibus"; # Not sure if this works or not, but whatever
    XMODIFIERS = "@im=ibus";
  };

  dconf.settings."org/gnome/desktop/peripherals/touchpad" = {
    middle-click-emulation = true;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    gtk-enable-primary-paste = true;
  };

  home.packages = with pkgs; [
    wout-scripts
    bashInteractive

    keyd

    # fun
    fortune
    neo-cowsay
    # if you want rainbow fortunes
    #lolcat

    bup
    par2cmdline # for bup
    zip
    unzip

    # TODO make this only for desktop use
    # broken due to libsoup2 dep
    #ulauncher
    # uses way too much cpu
    #keybase-gui
    brightnessctl
    lguf-brightness
    google-chrome
    firefox
    sqlitebrowser
    wmctrl
    nixpkgs-fmt
    nixfmt
    pavucontrol
    wireshark
    signal-desktop
    kdePackages.konsole
    ghostty
    kitty
    vorta
    # for qdbus
    #libsForQt5.full

    # code-cursor
    # antigravity

    claude-code
    codex

    # flakeInputs.ghostty.packages.x86_64-linux.default

    # Vitals extension
    lm_sensors
    libgtop

    jdupes
    file
    findutils
    git
    git-crypt
    gh
    gnupg
    gnused
    highlight
    jq
    less
    lsof
    mtr
    pv

    nodejs_24
    # pnpm itself comes from programs.pnpm-nix-provider (provider-aware
    # build); corepack would shadow it with the stock shim.
    (pkgs.writeShellScriptBin "pnpm-orig" ''exec ${pkgs.pnpm}/bin/pnpm "$@"'')

    android-tools

    nil

    openssh
    openssl
    pstree
    rsync
    sqlite-interactive
    tree
    wget

    vim

    # Claude wants this for voice
    sox

    python3
    # php
    # php
    # phpPackages.php-cs-fixer

    # for Go
    #dep

    # Ember
    #watchman

    flakeInputs.determinate.packages.x86_64-linux.default
  ];

  programs.bash = {
    enable = true;
    historySize = 1000000;
    historyFileSize = 1000000000;
    historyControl = [
      "ignoredups"
      "ignorespace"
    ];
    shellAliases = {
      which = "builtin type -p";
      where = "builtin type -ap";
      pico = "pico -z -w";
      grep = "grep --colour=auto";
      l = "ls -FGb";
      ll = "ls -FGbl";
      lL = "ls -FGblL";
      tree = "tree -CF";
      status = "sudo /run/current-system/sw/bin/systemctl status";
      stop = "sudo /run/current-system/sw/bin/systemctl stop";
      restart = "sudo /run/current-system/sw/bin/systemctl restart";
      log = "/run/current-system/sw/bin/journalctl";
    };
    bashrcExtra =
      builtins.replaceStrings
        [ "@user@" "@mainHost@" "@sudo-wrap@" ]
        [ user mainHost "${./sudo-wrap.bash}" ]
        (builtins.readFile ./bashrc);
  };
}
