{ config, lib, pkgs, ... }:

let

  inherit (lib) mkDefault mkEnableOption mkForce mkIf mkMerge mkOption;
  inherit (lib)
    concatStringsSep literalExample mapAttrsToList optional optionals
    optionalString types;

  user = "uvdesk";
  cfg = config.services.uvdesk;

  group = config.services.nginx.group;
  fpm = config.services.phpfpm.pools.${user};
  stateDir = "/var/lib/${user}";
  dbFile = "${stateDir}/db.sqlite3";

  myPhp = pkgs.php.buildEnv {
    extensions = { enabled, all }: enabled ++ [ all.mailparse ];
    # extraConfig = "memory_limit=256M";
  };

  pkg = pkgs.stdenv.mkDerivation rec {
    pname = "uvdesk";
    version = "1.0.13";

    src = pkgs.fetchurl {
      # unfortunately there are no versioned links
      # TODO build from git, requires vendor packages
      url =
        "https://cdn.uvdesk.com/uvdesk/downloads/opensource/uvdesk-community-current-stable.zip";
      sha256 = "1bg7fi3kh4516046s5p9hjry8sl8ff5xhfv132xdadldfqz455bp";
    };

    nativeBuildInputs = [ pkgs.unzip ];

    patches = [ ./symfony-var.patch ./fix-sqlite.patch ];
    # Provide php for patch-shebangs
    buildInputs = [ myPhp ];

    installPhase = ''
      mkdir -p $out
      cp -r apps bin config public src templates translations vendor composer.json $out/
      # Symfony uses config from install dir so link to state
      mv $out/config/packages $out/config/packages-default
      ln -s ${stateDir}/config $out/config/packages
      cat > $out/.env <<EOF
      APP_CACHE_DIR=${stateDir}/cache
      APP_LOG_DIR=${stateDir}/log
      DATABASE_URL=sqlite:///${dbFile}
      EOF
      echo '{"migrations_directory": "${stateDir}/migrations","migrations_namespace":"DoctrineMigrations"}' > $out/migrations.json
    '';

    meta = with pkgs.lib; {
      homepage = "https://uvdesk.com/";
      platforms = platforms.linux;
      maintainers = [ maintainers.wmertens ];
      license = licenses.mit;
    };
  };

in {
  # interface
  options = {
    services.uvdesk = {
      enable = mkEnableOption "UVDesk";

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
          Options for the UVDesk PHP pool. See the documentation on <literal>php-fpm.conf</literal>
          for details on configuration directives.
        '';
      };

      virtualHost = mkOption {
        type = types.submodule (import
          <nixpkgs/nixos/modules/services/web-servers/nginx/vhost-options.nix>);
        example = literalExample ''
          {
            serverName = "uvdesk.example.org";
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
  config = mkIf cfg.enable {
    users.users.${user} = {
      group = group;
      useDefaultShell = true;
      isSystemUser = true;
      packages = [ myPhp pkg pkgs.sqlite-interactive ];
    };
    systemd.tmpfiles.rules = [
      "d '${stateDir}' 0750 ${user} ${group} - -"
      "d '${stateDir}/migrations' 0750 ${user} ${group} - -"
      "d '${stateDir}/config' 0750 ${user} ${group} - -"
    ];

    services.phpfpm.pools.${user} = {
      inherit user group;
      phpPackage = myPhp;
      settings = {
        "listen.owner" = config.services.nginx.user;
        "listen.group" = config.services.nginx.group;
      } // cfg.poolConfig;
    };

    systemd.services."${user}-init" = {
      wantedBy = [ "multi-user.target" ];
      before = [ "phpfpm-${user}.service" ];
      script = ''
        cd ${pkg}
        # initialize sqlite
        if [ ! -e "${dbFile}" ]; then
          ${pkgs.sqlite}/bin/sqlite3 "${dbFile}" 'PRAGMA journal_mode = "wal"'
          ${pkg}/bin/console uvdesk_wizard:database:migrate
          exit $?
        fi
        # create or update config
        if [ ! -e "${stateDir}/config/uvdesk.yaml" ] || [ "${stateDir}/config/uvdesk.yaml" -ot "${pkg}/config/packages-default/uvdesk.yaml" ]; then
          cp -a "${pkg}/config/packages-default/." "${stateDir}/config"
          chown -R ${user}:${group} "${stateDir}/config"
          chmod -R u+w "${stateDir}/config"
        fi
      '';

      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = group;
      };
    };

    services.nginx = {
      enable = true;
      # TODO make these low prio
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts.${cfg.virtualHost.serverName} = mkMerge [
        cfg.virtualHost
        {
          root = mkForce "${pkg}/public";
          locations = {
            "/" = {
              # try to serve file directly, fallback to index.php
              tryFiles = "$uri /index.php$is_args$args";
            };
            # Allow custom favicon
            "/favicon.ico" = {
              tryFiles = "${stateDir}/assets/favicon.ico $uri";
            };
            "~ ^/index.php(/|$)" = {
              extraConfig = ''
                fastcgi_pass unix:${fpm.socket};
                fastcgi_split_path_info ^(.+\.php)(/.*)$;
                include ${pkgs.nginx}/conf/fastcgi_params;
                fastcgi_intercept_errors off;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                # Prevents URIs that include the front controller. This will 404:
                # http://domain.tld/index.php/some-path
                # Remove the internal directive to allow URIs like this
                internal;
              '';
            };
            # return 404 for all other php files not matching the front controller
            # this prevents access to other php files you don't want to be accessible.
            #"~ .php$" = { return = "404"; };
          };
        }
      ];

    };
  };
}
