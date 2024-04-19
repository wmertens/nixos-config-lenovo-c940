{ stdenv, lib, pkgs, writeScript }:

let
  # Run screensaver on desktop
  ssdesk = writeScript "ssdesk" ''
    /System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine -background
  '';

  # convert ts
  ts = writeScript "ts" ''
    #!/usr/bin/env node
    const ts = +process.argv[2]
    console.log(new Date(ts > 1000000000000 ? ts : ts * 1000))
  '';

  # open in vscode
  code = writeScript "code" ''
    #!/bin/sh
    open -a 'visual studio code' --touch-events "$@"
  '';

  # open a new terminal window in current dir
  term = writeScript "term" ''
    #!/bin/sh
    open -a iTerm .
  '';

  cdp-listen = writeScript "cdp-listen" ''
    #!/bin/sh
    if [ -n "$1" ]; then
      PORT="-i $1"
      echo Using interface $1
    fi
    echo Looking for CDP signals, this can take a little while...
    tcpdump $PORT -nn -v -s 1500 -c 1 'ether[20:2] == 0x2000'
  '';

  fl = writeScript "fl" ''
    #!/bin/sh
    # Find large files in current directory or given path
    # wmertens 17 Mar 2003

    if [ "$1" = "" ]
    then
      echo "Usage: $0 <directory> [size]" 1>&2
      echo "Finds files over 1MB and prints them, sorted to size" 1>&2
      exit 1
    fi

    ${pkgs.findutils}/bin/find "$1" -mount -type f -size +''${2:-1000000c} -printf "%10s %p\n" \
      | ${pkgs.coreutils}/bin/sort -n \
      | ${pkgs.gawk}/bin/awk '{s=$1/1024/1024;$1="";printf("%6.1fMB  %s\n",s,$0)}'
  '';

  slack-notify = writeScript "slack" ''
    #!${pkgs.bash}

    SLACK_URL=https://hooks.slack.com/services/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

    function post_to_slack () {
      if [ $# -lt 1 ]; then
        exec 2>&1
        echo "Usage:"
        echo
        echo "$0 \"message\" [INFO|WARN|ERROR] [#channel|@who]"
        echo
        echo "the env variable SLACK_CHANNEL can also be used"
        exit 1
      fi
      local channel=$SLACK_CHANNEL
      local icon

      # format message as a code block ```msg```
      local message="\`\`\`$1\`\`\`"

      case "$2" in
        ""|INFO)
          icon=
          ;;
        WARN)
          icon=':warning: '
          ;;
        ERROR)
          icon=':bangbang: <@channel> '
          ;;
        *)
          exec 2>&1
          echo "Unknown priority $2, use INFO, WARN, ERROR"
          exit 1
          ;;
      esac
      
      if [ -n "$3" ]; then
        channel="$3"
      fi
      
      if [ -n "$channel" ]; then
        channel="\"channel\": \"$channel\","
      fi

      curl -X POST --data "payload={$channel\"text\": \"$icon$who$message\",\"attachments\":[{\"fallback\":\"fromwhere\",\"fields\":[{\"title\":\"who\",\"value\":\"`whoami`\",\"short\":true},{\"title\":\"who\",\"value\":\"`hostname`\",\"short\":true}]}]}" $SLACK_URL
    }

    post_to_slack "$@"
  '';

  newKonsole = writeScript "newKonsole" ''
    #!/bin/sh
    t=`pidof -s konsole`

    if [ -n "$t" ]; then
    	exec ${pkgs.kdePackages.qttools}/bin/qdbus org.kde.konsole-$t /konsole/MainWindow_1 org.kde.KMainWindow.activateAction new-window
    else
    	exec konsole
    fi
  '';

in
stdenv.mkDerivation rec {
  name = "wout-scripts-${version}";
  version = "1.0.0";
  phases = "installPhase";

  # macOS only
  # cp ${code} code
  # cp ${term} term
  # cp ${ssdesk} ssdesk

  # cp ${cdp-listen} cdp-listen
  # cp ${slack-notify} slack-notify
  buildInputs = with pkgs; [ bashInteractive perl ];
  installPhase = ''
    mkdir -p $out/bin
    cd $out/bin
    cp ${fl} find-large-files
    cp ${ts} ts
    cp ${newKonsole} new-konsole
    cp ${./tracefile.pl} tracefile
    chmod +x tracefile
  '';

  meta = with lib; {
    description = "My scripts";
    maintainers = with maintainers; [ wmertens ];
    platforms = with platforms; linux ++ darwin;
    license = licenses.mit;
  };
}
