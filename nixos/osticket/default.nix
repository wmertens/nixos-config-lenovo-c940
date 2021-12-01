# TODO plugins
{ config, lib, pkgs, ... }:

let
  version = "1.15.2";
  sha256 = "1kh8w1ydp048i9y0i8fjrzm7amfy5c44v842qhzj13yz0x8q6ag8";
  user = "osticket";
  stateDir = "/var/lib/${user}";

  inherit (lib) mkDefault mkEnableOption mkForce mkIf mkMerge mkOption;
  inherit (lib)
    concatStringsSep literalExample mapAttrsToList optional optionals
    optionalString types;
  inherit (pkgs) fetchFromGitHub;

  cfg = config.services.osticket;

in {
  # interface
  options = {
    services.osticket = {
      enable = mkEnableOption "osTicket";

      withSetup = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Include the setup wizard. Set this to false after setup.
        '';
      };

      favicon = mkOption {
        type = with types; nullOr path;
        default = null;
        description = ''
          Path to custom favicon PNG image. This will be added to the page <HEAD> sections.
        '';
      };

      plugins = mkOption {
        type = with types; attrsOf path;
        default = { };
        description = ''
          Paths to plugins
        '';
      };

      pollInterval = mkOption {
        type = types.str;
        default = "*:0/5";
        description = ''
          How often to run email polling. Set to "" to turn off.

          The format is described in systemd.time(7).
        '';
      };

      poolConfig = mkOption {
        type = with types; attrsOf (oneOf [ str int bool ]);
        default = {
          "pm" = "dynamic";
          "pm.max_children" = 32;
          "pm.start_servers" = 1;
          "pm.min_spare_servers" = 1;
          "pm.max_spare_servers" = 2;
          "pm.max_requests" = 500;
          "php_value[date.timezone]" = "UTC";
          "php_value[upload_max_filesize]" = "10M";
          # Redirect worker stdout and stderr into main error log. If not set, stdout and
          # stderr will be redirected to /dev/null according to FastCGI specs.
          # Default Value: no
          "catch_workers_output" = true;
          "clear_env" = false;
          "env[\"SHELL_VERBOSITY\"]" = 3;
        };
        description = ''
          Options for the osTicket PHP pool. See the documentation on <literal>php-fpm.conf</literal>
          for details on configuration directives.
        '';
      };

      virtualHost = mkOption {
        type = types.submodule (import
          <nixpkgs/nixos/modules/services/web-servers/nginx/vhost-options.nix>);
        example = literalExample ''
          {
            serverName = "osticket.example.org";
            forceSSL = true;
            enableACME = true;
          }
        '';
        description = ''
          Nginx configuration can be done by adapting <option>services.nginx.virtualHosts</option>.
          See <xref linkend="opt-services.nginx.virtualHosts"/> for further information.
        '';
      };

    };
  };

  # implementation
  config = mkIf cfg.enable (let
    group = config.services.nginx.group;
    fpm = config.services.phpfpm.pools.${user};

    myPhp = pkgs.php.buildEnv {
      extensions = { enabled, all }:
        enabled ++ (with all; [
          apcu
          gd
          gettext
          imap
          json
          mysqli
          mbstring
          # required but already in enabled
          # xml
          # Needed for Slack plugin
          # TODO extract requirements from plugins
          curl
        ]);
      # extraConfig = "memory_limit=256M";
    };

    pkg = pkgs.stdenv.mkDerivation rec {
      inherit version;
      pname = "osTicket";

      src = fetchFromGitHub {
        inherit sha256;
        owner = "osTicket";
        repo = "osTicket";
        rev = "v${version}";
      };

      # Provide php for patch-shebangs
      buildInputs = [ myPhp ];

      patchPhase = ''
        # Patch the location of the config file
        sed -i "s|INCLUDE_DIR.'ost-config.php'|'${stateDir}/ost-config.php'|" bootstrap.php
        sed -i "s|../include|${stateDir}|" setup/install.php

        # Pre-populate the database settings for setup.
        # The password is not used but required.
        sed -i "s|'dbhost'=>'localhost'|'dbhost'=>'localhost','dbuser'=>'${user}','dbpass'=>'${user}','dbname'=>'${user}'|" setup/inc/install.inc.php

        # Add script header for cron
        sed -i '1i\#!/usr/bin/env php' api/cron.php
      '' + optionalString (cfg.favicon != null) ''
        cp ${cfg.favicon} images/favicon.png
        # Savings for 16x16 are tiny, just remove
        sed -i -e '/16x16/d' -e 's/oscar-favicon-32x32.png/favicon.png/'-e 's/ sizes="32x32"//' include/client/header.inc.php include/staff/header.inc.php 
      '';

      installPhase = ''
        mkdir -p $out/public
        php manage.php deploy ${
          optionalString cfg.withSetup "--setup"
        } -i $out/include $out/public
        chmod a+x $out/public/manage.php $out/public/api/cron.php $out/public/api/pipe.php
        mkdir -p $out/bin
        ln -s ../public/manage.php $out/bin/osticket_manage
        ln -s ../public/api/cron.php $out/bin/osticket_cron
        ln -s ../public/api/pipe.php $out/bin/osticket_pipe
      '' + (concatStringsSep "\n" (mapAttrsToList
        (name: path: "ln -s ${path} $out/include/plugins/${name}")
        cfg.plugins));

      meta = with pkgs.lib; {
        homepage = "https://osticket.com/";
        platforms = platforms.linux;
        maintainers = [ maintainers.wmertens ];
        license = licenses.gpl2;
      };
    };

  in {
    users.users.${user} = {
      group = group;
      useDefaultShell = true;
      isSystemUser = true;
      packages = [ myPhp pkg pkgs.mariadb ];
    };

    systemd.tmpfiles.rules = [
      "d '${stateDir}' 0750 ${user} ${group} - -"
      "C '${stateDir}/ost-config.php' ${
        if cfg.withSetup then "0640" else "0440"
      } ${user} ${group} - ${pkg}/include/ost-sampleconfig.php"
    ];

    systemd.services."${user}-cron" = {
      description = "Runs osTicket email polling etc";
      script = "${pkg}/bin/osticket_cron";
      startAt = cfg.pollInterval;
      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = group;
      };
    };

    services.phpfpm.pools.${user} = {
      inherit user group;
      phpPackage = myPhp;
      settings = {
        "listen.owner" = config.services.nginx.user;
        "listen.group" = config.services.nginx.group;
      } // cfg.poolConfig;
    };

    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      ensureDatabases = [ "osticket" ];
      ensureUsers = [{
        name = "osticket";
        ensurePermissions = { "osticket.*" = "ALL PRIVILEGES"; };
      }];
    };

    services.nginx = {
      enable = true;

      recommendedGzipSettings = mkDefault true;
      recommendedOptimisation = mkDefault true;
      recommendedProxySettings = mkDefault true;
      recommendedTlsSettings = mkDefault true;

      virtualHosts.${cfg.virtualHost.serverName} = mkMerge [
        cfg.virtualHost
        {
          root = mkForce "${pkg}/public";

          extraConfig = ''
            set $path_info "";

            # Requests to /api/* need their PATH_INFO set, this does that
            if ($request_uri ~ "^/api(/[^\?]+)") {
              set $path_info $1 ;
            }
            # /scp/ajax.php needs PATH_INFO too, possibly more files need it hence the .*\.php
            if ($request_uri ~ "^/scp/.*\.php(/[^\?]+)") {
              set $path_info $1 ;
            }

          '';

          locations = {
            "/" = { index = "index.php"; };

            # Deny access to apache .ht* files (nginx doesn't use these)
            "~ /.ht" = { return = "403"; };

            # /api/*.* should be handled by /api/http.php if the requested file does not exist
            "~ ^/api/(tickets|tasks)(.*)$" = {
              tryFiles = "$uri $uri/ /api/http.php$is_args$args";
            };

            # Make sure requests to /scp/ajax.php/some/path get handled by ajax.php
            "~ ^/scp/ajax.php/(.*)$" = {
              tryFiles = "$uri $uri/ /scp/ajax.php$is_args$args";
            };

            # Make sure requests to /ajax.php/some/path get handled by ajax.php
            "~ ^/ajax.php/(.*)$" = {
              tryFiles = "$uri $uri/ /ajax.php$is_args$args";
            };

            "~ .php$" = {
              tryFiles = "$uri =404";
              extraConfig = ''
                fastcgi_index index.php;
                fastcgi_pass unix:${fpm.socket};
                fastcgi_split_path_info ^(.+\.php)(/.*)$;
                include ${pkgs.nginx}/conf/fastcgi_params;
                fastcgi_intercept_errors off;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_param PATH_INFO $path_info;
              '';
            };
          };
        }
      ];

    };
  });
}
