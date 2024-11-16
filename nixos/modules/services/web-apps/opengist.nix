{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    getExe
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optionalAttrs
    types
    ;

  defaultUser = "opengist";
  cfg = config.services.opengist;

  settingsFormat = pkgs.formats.yaml { };
  configFile =
    if cfg.settingsFile != null then
      cfg.settingsFile
    else
      settingsFormat.generate "opengist.yaml" cfg.settings;

  environmentFile = pkgs.writeText "opengist-environment" (
    lib.generators.toKeyValue { } cfg.environment
  );
  environmentFiles = [
    environmentFile
  ] ++ lib.optional (cfg.secretsFile != null) cfg.secretsFile ++ lib.optional notSqlite dbUriEnvFile;

  mysqlLocal = cfg.database.createLocally && cfg.database.type == "mysql";
  pgsqlLocal = cfg.database.createLocally && cfg.database.type == "postgresql";
  notSqlite = cfg.database.type != "sqlite";

  dbService = if notSqlite then "${cfg.database.type}.service" else "";
  dbUriEnvFile = "${cfg.opengist-home}/db_uri_env";

  opengist-db-postinit-script =
    cfg:
    pkgs.writeShellApplication {
      name = "opengist-db-postinit-script";
      runtimeInputs =
        [ pkgs.coreutils ]
        ++ lib.optional (cfg.database.type == "postgresql") config.services.postgresql.package
        ++ lib.optional (cfg.database.type == "mysql") config.services.mysql.package;
      text = ''
        ${
          if cfg.database.passwordFile != null then
            ''PW="$(cat "$CREDENTIALS_DIRECTORY/opengist_passwordFile")"''
          else if cfg.database.password != null then
            # This is ok, it is already exposed in the store
            ''PW="${cfg.database.password}"''
          else
            "exit 0"
        }

        role="${cfg.database.username}"
        host="${cfg.database.host}"
        port="${toString cfg.database.port}"
        db_name="${cfg.database.name}"
        db_uri="${cfg.database.type}://$role:$PW@$host:$port/$db_name"

        env_file="${dbUriEnvFile}"
        rm -rf "$env_file"
        echo OG_DB_URI="$db_uri" >"$env_file"
        chmod 0600 "$env_file"
        ${
          # taken from keycloak.nix
          # escape any single quotes by adding additional single
          # quotes after them, following the rules laid out here:
          # https://dev.mysql.com/doc/refman/8.0/en/string-literals.html
          # https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-CONSTANTS
          if pgsqlLocal then # bash
            ''
              PW="''${PW//\'/\'\'}"
              alter_role="$(mktemp)"
              trap 'rm -f "$alter_role"' EXIT
              PSQL="psql --port=$port"
              echo "ALTER ROLE $role WITH PASSWORD '$PW'" > "$alter_role"
              $PSQL -tAc "SELECT 1 FROM pg_roles WHERE rolname='$role'" | grep -q 1 || echo BAD BAD BAD
              $PSQL -tA --file="$alter_role"
            ''
          else if mysqlLocal then # bash
            ''
              PW="''${PW//\'/\'\'}"
              mysql --skip-column-names --execute \
                "ALTER USER '$role'@'$host' IDENTIFIED BY '$PW'; FLUSH PRIVILEGES;"
            ''
          else
            ""
        }
      '';
    };
in
{
  options.services.opengist = {
    enable = mkEnableOption "opengist" // {
      description = "Enable opengist.";
    };

    package = mkPackageOption pkgs "opengist" { };

    user = mkOption {
      default = defaultUser;
      type = types.str;
      description = "User account under which opengist runs.";
    };

    group = mkOption {
      default = defaultUser;
      type = types.str;
      example = "users";
      description = ''
        Group account under which opengist runs.

        ::: {.note}
        Use "users" along with `readonly-home` to have write access to the `opengist-home` directory.
        :::
      '';
    };

    opengist-home = mkOption {
      type = types.str;
      default = "/var/lib/opengist";
      description = ''
        The directory used to store all data for opengist.

        ::: {.note}
        Do not set `settings.opengist-home` set this.
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

    database = mkOption {
      description = "Database settings.";
      default = { };
      type = types.submodule {
        options = {
          createLocally = mkOption {
            type = types.bool;
            default = notSqlite;
            defaultText = lib.literalExpression ''cfg.database.type != "sqlite"'';
            description = ''
              Whether to setup a local database with provided engine.
              If `database.type` is not sqlite, all other `database.*` options must be provided.

              ::: {.note}
              Set this to false and then you can use `environment.OG_DB_URI` or set the `database.*` options.
              Or if you prefer to keep your database password secret, set OG_DB_URI in {option}`secretsFile`.
              :::
            '';
          };
          type = mkOption {
            type = types.enum [
              "sqlite"
              "postgresql"
              "mysql"
            ];
            default = "sqlite";
            description = ''
              Database engine to use.

              ::: {.note}
              If not using sqlite then you must set all the options, name, host, port, username, password.
              Or you can use OG_DB_URI in environment.
              Also see {option}`database.createLocally`.
              :::
            '';
          };
          name = mkOption {
            type = types.str;
            default = "opengist";
            description = "Database name. For sqlite, it will be `DB_NAME`.db.";
          };
          host = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "DB host";
          };
          port = mkOption {
            type = types.port;
            default = if cfg.database.type == "postgresql" then 5432 else 3306;
            defaultText = "5432 for postgresql, 3306 for mysql";
            description = "DB port";
          };
          username = mkOption {
            type = types.str;
            default = "opengist";
            description = "DB username";
          };
          # TODO consider removal
          password = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "DB password";
          };
          # TODO https://github.com/NixOS/nixpkgs/pull/326306
          # what about for mysql?
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
        See <https://github.com/thomiceli/opengist/blob/stable/config.yml>
      '';
    };

    settings = mkOption {
      description = ''
        Config for opengist.
        See <https://github.com/thomiceli/opengist/blob/stable/config.yml> for the default settings.
        Also <https://opengist.io/docs/configuration/cheat-sheet.html>

        :::{.note}
        Nix keys require double quotes when they have periods `.`
        eg. { "http.git-enabled" = false; }
        :::
      '';
      default = { };
      type = types.submodule {
        freeformType = settingsFormat.type;
        options = {
          "http.host" = mkOption {
            type = types.str;
            default = "0.0.0.0";
            description = "Host to bind to.";
          };

          "http.port" = mkOption {
            type = types.port;
            default = 6157;
            description = "Port the server will listen on.";
          };
        };
      };
      example = {
        "http.git-enabled" = true;
        "ssh.git-enabled" = false;
        "custom.logo" = "logo.png";
        "custom.favicon" = "logo.ico";
        "custom.static-links" = [
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

    environment = mkOption {
      description = ''
        Enviornment variables that opengist can access.
        See <https://opengist.io/docs/configuration/cheat-sheet.html> for the list of env vars.

        Environment variables override any config set in the yaml config i.e. {option}`settings` or {option}`settingsFile`.
      '';
      default = { };
      type = types.submodule {
        freeformType = types.attrsOf types.str;
        options = { };
      };
    };

    secretsFile = mkOption {
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

  config = mkIf cfg.enable {
    assertions = [
      /*
        TODO
        {
          assertion = cfg.settings != { } -> cfg.settingsFile == null;
          message = "Both settings and settingsFile are specified, only one can be set.";
        }
      */
      {
        assertion = pgsqlLocal -> config.services.postgresql.enable;
        message = "Postgresql must be enabled to create a local database.";
      }
      {
        assertion = mysqlLocal -> config.services.mysql.enable;
        message = "Mysql must be enabled to create a local database.";
      }
      {
        assertion = cfg.database.passwordFile != null -> cfg.database.password == null;
        message = "Both passwordFile and password are set, use only one.";
      }
      {
        assertion =
          cfg.database.host != null -> (cfg.database.password != null || cfg.database.passwordFile != null);
        message = "Database host is set but database password/passwordFile not set.";
      }
      {
        assertion = (cfg.database.createLocally || notSqlite) -> cfg.database.host != null;
        message = "Database host is null.";
      }
    ];

    services.opengist.settings = {
      opengist-home = mkIf (cfg.settingsFile == null) cfg.opengist-home;
      db-uri = mkIf (cfg.database.type == "sqlite") "${cfg.database.name}.db";
    };

    services.mysql = mkIf mysqlLocal {
      enable = mkDefault true;
      package = mkDefault pkgs.mariadb;
      ensureUsers = [
        {
          name = cfg.database.username;
          ensurePermissions = {
            "${cfg.database.name}.*" = "ALL PRIVILEGES";
            # password change for mysql requires this
            # from writefreely.nix
            "*.*" = "CREATE USER, RELOAD";
          };
        }
      ];
      ensureDatabases = [ cfg.database.name ];
    };

    services.postgresql = mkIf pgsqlLocal {
      enable = mkDefault true;
      ensureUsers = [
        {
          name = cfg.database.username;
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [ cfg.database.name ];
    };

    # taken from honk.nix
    # this is passwordFile logic, not dependent on createLocally
    systemd.services.opengist-postinit-db = mkIf notSqlite {
      description = "opengist server configure database ";
      requiredBy = [ "opengist.service" ];
      before = [ "opengist.service" ];
      requires = [ dbService ];
      after = [
        "systemd-tmpfiles-setup.service"
        dbService
      ];
      serviceConfig = {
        LoadCredential = mkIf (cfg.database.passwordFile != null) [
          "opengist_passwordFile:${cfg.database.passwordFile}"
        ];
        # https://github.com/NixOS/nixpkgs/issues/258371
        Type = "exec"; # oneshot
        DynamicUser = false;
        User = cfg.user;
        RemainAfterExit = true;
        ExecStart = lib.getExe (opengist-db-postinit-script cfg);
        PrivateTmp = true;
      };
    };

    systemd.services.opengist = {
      description = "Opengist service";
      wantedBy = [
        "multi-user.target"
      ];
      after = [
        "multi-user.target"
      ] ++ lib.optional notSqlite dbService;
      bindsTo = mkIf notSqlite [ "opengist-postinit-db.service" ];
      path = [
        pkgs.gitMinimal
        pkgs.openssh # ssh-keygen
      ];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        EnvironmentFile = environmentFiles;
        WorkingDirectory = cfg.opengist-home;
        ExecStart = "${getExe cfg.package} --config ${configFile}";
        Restart = "always";
      };
    };

    # if user specified, the user needs to create it themselves
    systemd.tmpfiles.settings.opengist = mkIf (cfg.opengist-home == "/var/lib/opengist") {
      "${cfg.opengist-home}".d = {
        inherit (cfg) user group;
        mode = if cfg.readonly-home then "0700" else "0770";
      };
    };

    # create service user
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
