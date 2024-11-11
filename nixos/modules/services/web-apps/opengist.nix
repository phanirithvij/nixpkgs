{
  config,
  lib,
  options,
  pkgs,
  ...
}:

# adapted from healthchecks service
# TODO side note: use healthchecks, healthchecks.io for systemd service failures? (my system, not this module)
# https://discourse.nixos.org/t/how-to-setup-a-notification-in-case-of-systemd-service-failure/51706/5

let
  inherit (pkgs) writeText writeShellApplication;
  inherit (lib)
    concatMapStringsSep
    getExe
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    optionalAttrs
    types
    ;

  defaultUser = "opengist";
  cfg = config.services.opengist;
  opt = options.services.opengist;

  # version is solely for documentation links
  # if cfg.package is overriden it is not necessary to override this
  version = "1.8.1"; # managed by opengist update script

  settingsFormat = pkgs.formats.yaml { };
  configFile =
    if cfg.settingsFile != null then
      cfg.settingsFile
    else
      settingsFormat.generate "opengist.yaml" cfg.settings;

  environmentFile = writeText "opengist-environment" (lib.generators.toKeyValue { } cfg.environment);
  environmentFiles = [
    environmentFile
  ] ++ lib.optional (cfg.environment.SECRETS_FILE != null) cfg.environment.SECRETS_FILE;

  userWrapper = writeShellApplication {
    name = "opengist";
    text = ''
      ${concatMapStringsSep "\n" (f: ''export "$(xargs < "${f}")"'') environmentFiles}
      ${getExe cfg.package} "$@" --config ${configFile}
    '';
  };

  mysqlLocal = cfg.database.createLocally && cfg.database.type == "mysql";
  pgsqlLocal = cfg.database.createLocally && cfg.database.type == "postgres";

  dbUri =
    if cfg.database.type == "sqlite" then
      "${cfg.database.name}.db"
    else
      "${cfg.database.type}://"
      + "${cfg.database.username}:${cfg.database.password}@"
      + "${cfg.database.host}:${cfg.database.port}/${cfg.database.name}";
  dbService = if cfg.database.type == "sqlite" then "" else "${cfg.database.type}.service";
in
# TODO
# get http, ssh vals, from nixos options
# custom.static-links (outside in extraConfig makes sense)
#   use that as the example (a link and pkg.writeText with static file into custom?)
#   caddy.enable/nginx.enable? lemmy.nix
# psql mysql
{
  options.services.opengist = {
    enable = mkEnableOption "opengist" // {
      description = "Enable opengist.";
    };

    package = mkPackageOption pkgs "opengist" { };

    user = mkOption {
      default = defaultUser;
      type = types.str;
      description = ''
        User account under which opengist runs.

        ::: {.note}
        If left as the default value this user will automatically be created
        on system activation, otherwise you are responsible for
        ensuring the user exists before the opengist service starts.
        :::
      '';
    };

    group = mkOption {
      default = defaultUser;
      type = types.str;
      description = ''
        Group account under which opengist runs.

        ::: {.note}
        If left as the default value this group will automatically be created
        on system activation, otherwise you are responsible for
        ensuring the group exists before the opengist service starts.
        :::
      '';
    };

    opengist-home = mkOption {
      type = types.str;
      default = "/var/lib/opengist";
      description = ''
        The directory used to store all data for opengist.

        ::: {.note}
        If left as the default value this directory will automatically be created before
        the opengist server starts, otherwise you are responsible for ensuring the
        directory exists with appropriate ownership and permissions.
        :::
      '';
    };

    readonly-home = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether the created default opengist-home needs to be readonly.

        ::: {.note}
        Only applies to /var/lib/opengist
        :::
      '';
    };

    customDirGroup = mkOption {
      default = defaultUser;
      type = types.str;
      example = "users";
      description = ''
        A group of users who can modify the `opengist-home/custom` directory contents.
      '';
    };

    # taken from misskey.nix
    reverseProxy = {
      enable = mkEnableOption "a HTTP reverse proxy for opengist";
      webserver = mkOption {
        description = "The webserver to use as the reverse proxy.";
        type = types.attrTag {
          nginx = mkOption {
            type = types.submodule (import ../web-servers/nginx/vhost-options.nix);
            default = { };
            description = ''
              Extra configuration for the nginx virtual host of opengist.
              Set to `{ }` to use the default configuration.
            '';
          };
          caddy = mkOption {
            type = types.submodule (
              import ../web-servers/caddy/vhost-options.nix { cfg = config.services.caddy; }
            );
            default = { };
            description = ''
              Extra configuration for the caddy virtual host of opengist.
              Set to `{ }` to use the default configuration.
            '';
          };
        };
      };
      host = mkOption {
        type = types.nullOr types.str;
        description = ''
          The fully qualified domain name to bind to. Sets `settings.external-url` only if not using `settingsFile`.

          This is required when using `services.opengist.reverseProxy.enable = true`.
          If using `settingsFile` and configuring manually
          need to set `external-url` yourself in the yaml config like `http://<reverseProxy.host>`
        '';
        example = "opengist.example.com";
        default = null;
      };
    };

    database = mkOption {
      description = "Database settings.";
      default = { };
      type = types.submodule {
        options = {
          createLocally = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether to setup a local database with provided engine.
              If `database.type` is not sqlite, all other `database.*` options must be provided.

              ::: {.note}
              Set this to false and then you can use `environment.OG_DB_URI` or set the `database.*` options.
              Or if you prefer to keep your database password secret, set OG_DB_URI in `settings.SECRETS_FILE`.
              :::
            '';
          };
          type = mkOption {
            type = types.enum [
              "sqlite"
              "postgres"
              "mysql"
            ];
            default = "sqlite";
            description = ''
              Database engine to use.

              ::: {.note}
              If not using sqlite then you must set all the options, name, host, port, username, password.
              Also see {option}`database.createLocally`.
              :::
            '';
          };
          name = mkOption {
            type = types.str;
            default = "opengist";
            description = "Database name. For sqlite, it will be `DB_NAME`.db.";
          };
          # If host:port are specified then we set it as the db-uri in yaml
          # else assume uri comes from environment var (open or secret)
          host = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "DB host";
          };
          port = mkOption {
            type = types.nullOr types.port;
            default = null;
            description = "DB port";
          };
          username = mkOption {
            type = types.str;
            default = "opengist";
            description = "DB username";
          };
          password = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "DB password";
          };
          # TODO think more
          # TODO assert
          passwordFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "DB password file";
          };
        };
      };
    };

    settingsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Set a custom yaml config for opengist and manage it outside the nixos module.
        See <https://github.com/thomiceli/opengist/blob/v${version}/config.yml>
      '';
    };

    settings = mkOption {
      description = ''
        Config for opengist.
        See <https://github.com/thomiceli/opengist/blob/v${version}/config.yml> for the default settings.
        Also <https://github.com/thomiceli/opengist/blob/v${version}/docs/configuration/cheat-sheet.md>
      '';
      default = { };
      type = types.submodule {
        freeformType = settingsFormat.type;
        options = {
          host = mkOption {
            type = types.str;
            default = "0.0.0.0";
            description = "Host to bind to.";
          };

          port = mkOption {
            type = types.port;
            default = 6157;
            description = "Port the server will listen on.";
          };
        };
      };
      example = {
        http.git-enabled = true;
        ssh.git-enabled = false;
        custom = {
          logo = "logo.png";
          favicon = "logo.ico";
          static-links = [
            {
              name = "Gitea";
              path = "https://gitea.com";
            }
            {
              name = "Legal notices";
              path = "legal.html";
            }
          ];
        };
      };
    };

    environment = mkOption {
      description = ''
        Enviornment variables that opengist can access.
        See <https://github.com/thomiceli/opengist/blob/v${version}/docs/configuration/cheat-sheet.md> for the list of env vars.

        Environment variables override any config set in the yaml config i.e. {option}`settings` or {option}`settingsFile`.
      '';
      default = { };
      type = types.submodule {
        freeformType = types.attrsOf types.str;
        options = {
          SECRETS_FILE = mkOption {
            type = types.nullOr types.path;
            description = ''
              Path to a file containing the secret key in the format
              ```
              OG_SECRET_KEY=<key>
              ```

              ::: {.note}
              Secret key used for session store & encrypt MFA data on database.
              Will use a random 32-byte key if not set.

              Can set additional secret environment variables that opengist can read.
              eg. OG_DB_URI=postgres://user:<super_secret_password>@...
              :::
            '';
            example = "/run/secrets/sops_opengist_passfile";
            default = null;
          };
        };
      };
    };

    installWrapper = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to install a wrapper around `opengist` cli to simplify administration of the
        opengist instance.
      '';
    };
  };

  config =
    let
      proxyExternalUrl =
        if (cfg.settings ? external-url || cfg.settingsFile == null) then
          cfg.settings.external-url
        else
          "http://${cfg.reverseProxy.host}";
    in
    mkIf cfg.installWrapper {
      environment.systemPackages = [ userWrapper ];
    }
    // mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.database.host != null -> cfg.database.password != null;
          message = "If database host isn't null, database password needs to be set.";
        }
        {
          assertion = cfg.settingsFile != null -> cfg.settings != { };
          message = "Both settings and settingsFile are specified, only one can be set.";
        }
        {
          assertion = cfg.reverseProxy.enable -> cfg.reverseProxy.host != null;
          message = "Host unspecified for reverseProxy";
        }
      ];

      services.opengist.settings = mkIf (cfg.settingsFile == null) {
        db-uri = dbUri;
        inherit (cfg) opengist-home;
        # no settingsFile and reverse proxy enabled
        external-url = mkIf (cfg.reverseProxy.host != null) "http://${cfg.reverseProxy.host}";
      };

      services.caddy = mkIf (cfg.reverseProxy.enable && cfg.reverseProxy.webserver ? caddy) {
        enable = true;
        virtualHosts.${proxyExternalUrl} = mkMerge [
          cfg.reverseProxy.webserver.caddy
          {
            hostName = mkDefault proxyExternalUrl;
            extraConfig = ''
              reverse_proxy localhost:${toString cfg.settings.port}
            '';
          }
        ];
      };

      services.nginx = mkIf (cfg.reverseProxy.enable && cfg.reverseProxy.webserver ? nginx) {
        enable = true;
        virtualHosts.${cfg.reverseProxy.host} = mkMerge [
          cfg.reverseProxy.webserver.nginx
          {
            locations."/" = {
              proxyPass = mkDefault "http://localhost:${toString cfg.settings.port}";
              proxyWebsockets = mkDefault true;
              recommendedProxySettings = mkDefault true;
            };
          }
        ];
      };

      systemd.services.opengist = {
        description = "Opengist service";
        wantedBy = [
          "multi-user.target"
        ];
        after = [
          "multi-user.target"
        ] ++ lib.optional (cfg.database.createLocally && dbService != "") dbService;
        path = [
          pkgs.gitMinimal
          pkgs.openssh # ssh-keygen
        ];
        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          EnvironmentFile = environmentFiles;
          StateDirectory = mkIf (cfg.opengist-home == "/var/lib/opengist") "opengist";
          StateDirectoryMode = mkIf (cfg.opengist-home == "/var/lib/opengist") (
            if cfg.readonly-home then "0750" else "0770"
          );
          WorkingDirectory = cfg.opengist-home;
          ExecStart = "${getExe cfg.package} --config ${configFile}";
          Restart = "always";
        };
      };

      systemd.tmpfiles.settings.opengist = mkIf (cfg.opengist-home == "/var/lib/opengist") {
        "${cfg.opengist-home}/custom".d = {
          inherit (cfg) user;
          group = cfg.customDirGroup;
          mode = "0770";
        };
      };

      users.users = optionalAttrs (cfg.user == defaultUser) {
        ${defaultUser} = {
          description = "opengist service owner";
          isSystemUser = true;
          group = defaultUser;
        };
      };
      users.groups = optionalAttrs (cfg.user == defaultUser) {
        ${defaultUser} = {
          members = [ defaultUser ];
        };
      };
    };
}
