{ pkgs, lib, specialArgs, ... }:

let
  user = "wmertens";
  mainHost = "wmertens-nixos";
in rec {
  nixpkgs.config = {
    # permittedInsecurePackages = [ "electron-11.5.0" ];
    allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "google-chrome"
        "slack"
        "vscode-extension-ms-vsliveshare-vsliveshare"
        "vscode"
        "cursor"
        "cuda_cudart"
      ];
  };

  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;

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
    profiles.default.extensions = with pkgs.vscode-extensions;
      [ ms-vsliveshare.vsliveshare ];
  };

  programs.autojump.enable = true;

  programs.direnv.enable = true;

  programs.git = {
    enable = true;
    userEmail = "Wout.Mertens@gmail.com";
    userName = "Wout Mertens";
    extraConfig = {
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
    onChange =
      "cp -f ~/.ssh/config_source ~/.ssh/config && chmod 400 ~/.ssh/config";
    text = let
      base = builtins.readFile ./ssh_config;
      extra = if builtins.pathExists ./secrets/ssh_config then
        builtins.readFile ./secrets/ssh_config
      else
        "";
    in ''
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
    #<Super><Ctrl><Alt><Shift>K,code,code-url-handler,,
    <Super><Ctrl><Alt><Shift>K,cursor,cursor,,
    <Super><Ctrl><Alt><Shift>A,gnome-system-monitor,,
    # <Super><Ctrl><Alt><Shift>T,konsole,org.kde.konsole,
    <Super><Ctrl><Alt><Shift>T,ghostty,com.mitchellh.ghostty,

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

  home.packages = with pkgs; [
    wout-scripts
    bashInteractive

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
    ulauncher
    # keybase-gui
    brightnessctl
    lguf-brightness
    google-chrome
    sqlitebrowser
    wmctrl
    nixpkgs-fmt
    nixfmt-classic
    #teams
    #skype
    #zoom-us
    #slack
    pavucontrol
    wireshark
    signal-desktop
    kdePackages.konsole
    ghostty
    vorta
    # for qdbus
    #libsForQt5.full
    code-cursor

    # specialArgs.flakeInputs.ghostty.packages.x86_64-linux.default

    # Vitals extension
    lm_sensors
    libgtop

    jdupes
    file
    findutils
    git
    git-crypt
    gnupg
    gnused
    highlight
    jq
    less
    lsof
    mtr
    # broken build
    #bfr

    nodejs_20
    corepack_20

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

    # php
    # php
    # phpPackages.php-cs-fixer

    # for Go
    #dep

    # Ember
    #watchman

    # nixVersions.latest
    # temp
    specialArgs.flakeInputs.nix.packages.x86_64-linux.nix
  ];

  programs.bash = {
    enable = true;
    historySize = 1000000;
    historyFileSize = 1000000000;
    historyControl = [ "ignoredups" "ignorespace" ];
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
    bashrcExtra = ''
      # Node and own scripts
      export PATH=~/bin/node_modules/.bin:~/bin:$PATH:/usr/local/bin

      function _checkSshSock() {
        local s=~/.ssh/socket
        # Make sure we own ~/.ssh before doing anything else
        # Not perfect security but better than nothing
        # Bash should have a "writeable only by me" test
        if [ -w ~/.ssh ] && [ -O ~/.ssh ] && { [ -z "$SSH_AUTH_SOCK" ] || [ "$SSH_AUTH_SOCK" != $s ]; }; then
          export SSH_AUTH_SOCK
          for i in "$s"* /tmp/ssh*/*; do
            if [ -S "$i" ] && [ -O "$i" ]; then
              SSH_AUTH_SOCK="$i" timeout 0.5 ssh-add -l >/dev/null 2>&1
              if [ $? -le 1 ]; then
                [ "$i" != $s ] && ln -f -s "$i" $s
                SSH_AUTH_SOCK=$s
                break
              fi
              # Clean up socket?
            fi
          done
          # Only create a new agent if not logging in remotely or sudoing
          if [ -z "$SSH_AUTH_SOCK$SUDO_USER$SSH_CLIENT$SSH2_CLIENT" ]; then
            SSH_AUTH_SOCK=$s
            [ -e "$SSH_AUTH_SOCK" ] && rm "$SSH_AUTH_SOCK"
            eval "$(ssh-agent -a "$SSH_AUTH_SOCK" -s)"
          fi
        fi
      }
      _checkSshSock

      if [ "$XDG_SESSION_TYPE" = wayland ]; then
        export QT_QPA_PLATFORM=wayland
      fi

      # Not in session vars because they don't get loaded for regular shells
      export LC_COLLATE="C"
      export LANG="C"
      export EDITOR="vi"
      export PAGER="less -XF"
      export LESS="-j5 -R"
      export LESSCHARSET="utf-8"
    '';
    initExtra = ''
      # entertain me while we load
      if type -p fortune >/dev/null; then
        f=$(fortune -c -s computers cookie debian definitions drugs education fortunes goedel humorists law linux literature love magic medicine miscellaneous news off/art off/astrology off/atheism off/black-humor off/cookie off/debian off/definitions off/drugs off/fortunes off/linux off/miscellaneous off/politics off/privates off/racism off/religion off/riddles off/sex off/songs-poems off/vulgarity paradoxum people pets platitudes politics riddles science songs-poems startrek translate-me wisdom work | sed -e 's/(\/nix\/.*\//(/' -e 's/^%//')
        if type -p cowsay >/dev/null; then
          # # original cowsay doesn't have --random
          # function qotd() {
          #   # read -a cows < <(cowsay -l | sed 1d)
          #   local cows=(beavis.zen blowfish bong bud-frogs bunny cower daemon default dragon dragon-and-cow elephant eyes flaming-sheep ghostbusters hellokitty kitty koala llama luke-koala meow milk moofasa moose mutilated ren satanic sheep skeleton small stegosaurus stimpy supermilker surgery three-eyes turkey turtle tux udder vader vader-koala www)
          #   f=$(cowsay -f ''${cows[$(($RANDOM*(''${#cows[*]})/32768))]} <<<"$f")
          # }
          # qotd
          f=$(cowsay -W 80 --random --aurora <<<"$f")
        fi

        unset f
      fi

      # shortcuts
      export SK="stratokit.io" SSK="sync.stratokit.io"

      # Automatically run missing commands
      export NIX_AUTO_RUN=1

      # sudo
      source ${./sudo-wrap.bash}
      alias sudo=sudowrap

      # useful functions
      function schreen() {
        # we load .bashrc to update ssh agent sock
        ssh "$@" -A -t 'source ~/.bashrc; exec screen -xRR -A -e^Zz -U -O'
      }
      function d() { mkdir -p "$1" && cd "$1"; }
      # do not override on macos
      if ! type open >&/dev/null; then
        alias open=xdg-open
      fi
      function duk () { du -k "$@" | sort -n; }
      function sduk () { sudo du -k "$@" | sort -n; }
      # see the strings of a command
      function stmore () { strings -a `type -p "$1"` | less; }
      # see the source of a command
      function whmore () { less `type -p "$1"`; }
      # set the x window title
      function xtitle () { setPS1; echo -e "\033]2;$*\007\c"; }
      # Highlight a regexp
      function hl () { sed 's/'"$*"'/'`tput rev`'&'`tput rmso`'/g'; }

      ###-begin-nps.js-completions-###
      # from `nps completion` and escape the interpolations and fix the nps path
      _yargs_completions()
      {
          local cur_word args type_list

          cur_word="''${COMP_WORDS[COMP_CWORD]}"
          args=("''${COMP_WORDS[@]}")

          # ask yargs to generate completions.
          type_list=$(nps --get-yargs-completions "''${args[@]}")

          COMPREPLY=( $(compgen -W "''${type_list}" -- ''${cur_word}) )

          # if no match was found, fall back to filename completion
          if [ ''${#COMPREPLY[@]} -eq 0 ]; then
            COMPREPLY=()
          fi

          return 0
      }
      complete -o default -F _yargs_completions nps
      ###-end-nps.js-completions-###

      # prompt
      if tput setaf 1 &> /dev/null; then
        tput sgr0
        if [[ $(tput colors) -ge 256 ]] 2>/dev/null; then
          MAGENTA=$(tput setaf 9)
          ORANGE=$(tput setaf 172)
          GREEN=$(tput setaf 190)
          PURPLE=$(tput setaf 141)
          WHITE=$(tput setaf 256)
        else
          MAGENTA=$(tput setaf 5)
          ORANGE=$(tput setaf 4)
          GREEN=$(tput setaf 2)
          PURPLE=$(tput setaf 1)
          WHITE=$(tput setaf 7)
        fi
        BOLD=$(tput bold)
        RESET=$(tput sgr0)
      else
        MAGENTA="\033[1;31m"
        ORANGE="\033[1;33m"
        GREEN="\033[1;32m"
        PURPLE="\033[1;35m"
        WHITE="\033[1;37m"
        BOLD=""
        RESET="\033[m"
      fi

      # Fastest possible way to check if repo is dirty. a savior for the WebKit repo.
      function parse_git_dirty() {
        git diff --quiet --ignore-submodules HEAD 2>/dev/null || echo '*'
      }

      function parse_git_branch() {
        local e=$?
        git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1$(parse_git_dirty)/" -e 's/^/ on /'
        return $e
      }

      # setPS1 [xtitle]
      function _err() {
        local e=$?
        if [ $e -ne 0 ]; then
          echo "😢  ERR $e "
        fi
        return $e
      }
      function setPS1 () {
        local extra x
        if [ "$USER" != ${user} ]; then
          extra="\[$PURPLE\]$USER@\[$WHITE\]"
          if [ "$USER" = root ]; then
            export TMOUT=180
          fi
        fi
        if [ "$HOSTNAME" != ${mainHost} ]; then
          extra="$extra\[$ORANGE\]$HOSTNAME\[$WHITE\] "
        fi
        case "$TERM" in
          vt320|xterm*)
            if [ "$HOSTNAME" != ${mainHost} ]; then
              x='\[\e]0;\h:\w\a\]'
            else
              x='\[\e]0;\w\a\]'
            fi
            ;;
          screen)
            x='\[\ek\h\e\\\]'
            ;;
        esac
        PS1="$x"'🍀 🐚 \[$WHITE\] \d \t \[$MAGENTA\]$(_err)\[$WHITE\]'"$extra"'\[$ORANGE\]\w\[$PURPLE\]$(parse_git_branch)\[$WHITE\]\n\! \$ \[$RESET\]'
        #export PS1="$x$BOLD=== \d \t\$(_err) \w\n=== \! $extra\h\['`tput sgr0`'\] \W'$git' \$ "
      }

      setPS1
    '';
  };
}
