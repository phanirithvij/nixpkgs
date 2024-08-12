{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.teldrive;
  isPostgresUnixSocket = lib.hasPrefix "/" cfg.database.host;
  # TODO: https://github.com/jvanbruegge/nixpkgs/pull/1
  # maybe wait till immich module gets merged before following its footsteps
  postgresEnv =
    if isPostgresUnixSocket then
      { DB_URL = "socket://${cfg.database.host}?dbname=${cfg.database.name}"; }
    else
      {
        DB_HOSTNAME = cfg.database.host;
        DB_PORT = toString cfg.database.port;
        DB_DATABASE_NAME = cfg.database.name;
        DB_USERNAME = cfg.database.user;
      };
  commonServiceConfig = {
    Type = "simple";
    Restart = "on-failure";
    RestartSec = 3;

    # Hardening
    CapabilityBoundingSet = "";
    NoNewPrivileges = true;
    PrivateUsers = true;
    PrivateTmp = true;
    PrivateDevices = true;
    PrivateMounts = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    RestrictAddressFamilies = [
      "AF_INET"
      "AF_INET6"
      "AF_UNIX"
    ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
  };
  inherit (lib)
    types
    mkIf
    mkOption
    mkEnableOption
    ;
in
{
  options.services.teldrive = {
    enable = mkEnableOption "Teldrive";
    package = lib.mkPackageOption pkgs "teldrive" { };

    # TODO program config
    # pre-logged in?
    # what if secret expires and relogin? default none?
    # admin user default: create
    # telegram users: default: none
    # bot token file (allow ease of sops) default: none

    host = mkOption {
      type = types.str;
      default = "localhost";
      description = "The host that teldrive will listen on.";
    };
    port = mkOption {
      type = types.port;
      default = 8080;
      description = "The port that teldrive will listen on.";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the teldrive port in the firewall";
    };
    user = mkOption {
      type = types.str;
      default = "teldrive";
      description = "The user teldrive should run as.";
    };
    group = mkOption {
      type = types.str;
      default = "teldrive";
      description = "The group teldrive should run as.";
    };

    # TODO package image-resize + a seperate systemd service
    # https://github.com/divyam234/image-resize/blob/main/Dockerfile
    image-resize = {
      enable = mkEnableOption "allows teldrive to show thumbnails" // {
        default = false;
      };
    };

    database = {
      enable =
        mkEnableOption "The postgresql database for use with teldrive. See {option}`services.postgresql`"
        // {
          default = true;
        };
      createDB = mkEnableOption "The automatic creation of the database for teldrive." // {
        default = true;
      };
      name = mkOption {
        type = types.str;
        default = "teldrive";
        description = "The name of the teldrive database.";
      };
      host = mkOption {
        type = types.str;
        default = "/run/postgresql";
        example = "127.0.0.1";
        description = "Hostname or address of the postgresql server. If an absolute path is given here, it will be interpreted as a unix socket path.";
      };
      user = mkOption {
        type = types.str;
        default = "teldrive";
        description = "The database user for teldrive.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !isPostgresUnixSocket -> cfg.secretsFile != null;
        message = "A secrets file containing at least the database password must be provided when unix sockets are not used.";
      }
    ];
    services.postgresql = mkIf cfg.database.enable {
      enable = true;
      ensureDatabases = mkIf cfg.database.createDB [ cfg.database.name ];
      ensureUsers = mkIf cfg.database.createDB [
        {
          name = cfg.database.user;
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
      extraPlugins =
        ps: with ps; [
          pgvector
          pgroonga
        ];
      settings = {
        shared_preload_libraries = [
          "pgroonga"
          "pgroonga_database" # TODO needed?
          "vector"
        ];
      };
    };
  };
}
