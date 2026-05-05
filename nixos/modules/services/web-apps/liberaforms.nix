{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.liberaforms;

  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    mkPackageOption
    types
    optional
    hasPrefix
    ;
in
{
  options.services.liberaforms = {
    enable = mkEnableOption "Liberaforms";

    package = mkPackageOption pkgs "liberaforms" { };

    domain = mkOption {
      type = types.str;
      example = "forms.example.org";
      description = "The domain name of the Liberaforms instance.";
    };

    useHTTPS = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use HTTPS for the BASE_URL.";
    };

    rootUser = mkOption {
      type = types.str;
      description = "The email address of the root user.";
    };

    database = {
      host = mkOption {
        type = types.str;
        default = "/run/postgresql";
        description = "PostgreSQL host.";
      };
      name = mkOption {
        type = types.str;
        default = "liberaforms";
        description = "PostgreSQL database name.";
      };
      user = mkOption {
        type = types.str;
        default = "liberaforms";
        description = "PostgreSQL user.";
      };
      port = mkOption {
        type = types.port;
        default = 5432;
        description = "PostgreSQL port.";
      };
    };

    secretKeyFile = mkOption {
      type = types.path;
      description = "File containing the SECRET_KEY and DB_PASSWORD.";
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf types.str;
        options = {
          SESSION_TYPE = mkOption {
            type = types.enum [
              "filesystem"
              "sqlalchemy"
              "memcached"
            ];
            default = "filesystem";
            description = "Session storage type.";
          };
          TOKEN_EXPIRATION = mkOption {
            type = types.str;
            default = "3600";
            description = "Token expiration time in seconds.";
          };
          DEFAULT_TIMEZONE = mkOption {
            type = types.str;
            default = "UTC";
            description = "Default timezone.";
          };
          TOTAL_UPLOADS_LIMIT = mkOption {
            type = types.str;
            default = "10G";
            description = "Total uploads limit.";
          };
          DEFAULT_USER_UPLOADS_LIMIT = mkOption {
            type = types.str;
            default = "100M";
            description = "Default user uploads limit.";
          };
          ENABLE_REMOTE_STORAGE = mkOption {
            type = types.enum [
              "True"
              "False"
            ];
            default = "False";
            description = "Enable remote storage.";
          };
          MAX_MEDIA_SIZE = mkOption {
            type = types.str;
            default = "2000000";
            description = "Max media size in bytes.";
          };
          MAX_ATTACHMENT_SIZE = mkOption {
            type = types.str;
            default = "2000000";
            description = "Max attachment size in bytes.";
          };
          ENABLE_PROMETHEUS_METRICS = mkOption {
            type = types.enum [
              "True"
              "False"
            ];
            default = "False";
            description = "Enable Prometheus metrics.";
          };
          ENABLE_RSS_FEED = mkOption {
            type = types.enum [
              "True"
              "False"
            ];
            default = "True";
            description = "Enable RSS feed.";
          };
          ENABLE_LDAP = mkOption {
            type = types.enum [
              "True"
              "False"
            ];
            default = "False";
            description = "Enable LDAP authentication.";
          };
          TMP_DIR = mkOption {
            type = types.str;
            default = "/tmp";
            description = "Temporary directory.";
          };
        };
      };
      default = { };
      description = "Configuration settings for Liberaforms.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Environment file for additional configuration.";
    };

    extraConfig = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Extra environment variables for Liberaforms.";
    };
  };

  config = mkIf cfg.enable {
    users.users.liberaforms = {
      isSystemUser = true;
      group = "liberaforms";
    };
    users.groups.liberaforms = { };

    systemd.services.liberaforms = {
      description = "Liberaforms server";
      after = [
        "network.target"
        "postgresql.service"
      ];
      requires = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        BASE_URL = "${if cfg.useHTTPS then "https" else "http"}://${cfg.domain}";
        ROOT_USER = cfg.rootUser;
        FQDN = cfg.domain;
        # Database connection URI for SQLAlchemy
        SQLALCHEMY_DATABASE_URI =
          if hasPrefix "/" cfg.database.host then
            "postgresql+psycopg2://${cfg.database.user}@/${cfg.database.name}?host=${cfg.database.host}"
          else
            "postgresql+psycopg2://${cfg.database.user}@${cfg.database.host}:${toString cfg.database.port}/${cfg.database.name}";
        DB_HOST = cfg.database.host;
        DB_NAME = cfg.database.name;
        DB_USER = cfg.database.user;
        DB_PORT = toString cfg.database.port;
        DB_PASSWORD = ""; # Explicitly empty for peer auth
        UPLOADS_DIR = "/var/lib/liberaforms/uploads";
        SESSION_FILE_DIR = "/var/lib/liberaforms/sessions";
        LOG_DIR = "/var/log/liberaforms";
        ASSETS_DIR = "${cfg.package}/lib/liberaforms/assets";
        ASSETS_CACHE = "/var/cache/liberaforms/webassets";
        FLASK_CONFIG = "production";
        FLASK_ENV = "production";
        DEFAULT_LANGUAGE = "en";
        # Mandatory variables from settings submodule
        SESSION_TYPE = cfg.settings.SESSION_TYPE;
        TOKEN_EXPIRATION = cfg.settings.TOKEN_EXPIRATION;
        DEFAULT_TIMEZONE = cfg.settings.DEFAULT_TIMEZONE;
        TOTAL_UPLOADS_LIMIT = cfg.settings.TOTAL_UPLOADS_LIMIT;
        DEFAULT_USER_UPLOADS_LIMIT = cfg.settings.DEFAULT_USER_UPLOADS_LIMIT;
        ENABLE_REMOTE_STORAGE = cfg.settings.ENABLE_REMOTE_STORAGE;
        MAX_MEDIA_SIZE = cfg.settings.MAX_MEDIA_SIZE;
        MAX_ATTACHMENT_SIZE = cfg.settings.MAX_ATTACHMENT_SIZE;
        ENABLE_PROMETHEUS_METRICS = cfg.settings.ENABLE_PROMETHEUS_METRICS;
        ENABLE_RSS_FEED = cfg.settings.ENABLE_RSS_FEED;
        ENABLE_LDAP = cfg.settings.ENABLE_LDAP;
        TMP_DIR = cfg.settings.TMP_DIR;
      }
      // cfg.extraConfig;

      preStart = ''
        mkdir -p /var/lib/liberaforms/uploads/media/brand
        mkdir -p /var/lib/liberaforms/sessions
        mkdir -p /var/cache/liberaforms/webassets
        chown -R liberaforms:liberaforms /var/cache/liberaforms

        # Copy default assets if missing
        for f in logo.png logo-default.png favicon.ico favicon-default.ico; do
          if [ ! -f /var/lib/liberaforms/uploads/media/brand/$f ]; then
            cp ${cfg.package}/lib/liberaforms/assets/brand/$f /var/lib/liberaforms/uploads/media/brand/
          fi
        done

        # Run migrations
        ${cfg.package}/bin/liberaforms-manage db upgrade
      '';

      serviceConfig = {
        User = "liberaforms";
        Group = "liberaforms";
        StateDirectory = "liberaforms";
        LogsDirectory = "liberaforms";
        CacheDirectory = "liberaforms";
        EnvironmentFile = [
          cfg.secretKeyFile
        ]
        ++ optional (cfg.environmentFile != null) cfg.environmentFile;
        ExecStart = "${cfg.package}/bin/liberaforms-gunicorn --bind 127.0.0.1:5000 wsgi:app";
        Restart = "always";
      };
    };
  };
}
