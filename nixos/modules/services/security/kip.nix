{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.kip;
in
{
  options.services.kip = {
    enable = lib.mkEnableOption "Keyful Identity Protocol (KIP) daemon";

    realm = lib.mkOption {
      type = lib.types.str;
      default = "example.com";
      example = "unicorn.demo.arpa2.org";
      description = ''
        The default realm (domain) name for KIP virtual hosting.
        This is used to initialize the first virtual host domain during setup.
      '';
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "::1";
      example = "127.0.0.1";
      description = ''
        The IPv4 or IPv6 address the KIP daemon should listen on.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9876;
      description = ''
        The TCP port the KIP daemon should listen on.
      '';
    };

    keepalive = lib.mkOption {
      type = lib.types.ints.positive;
      default = 15;
      description = ''
        The keepalive interval in seconds for the KIP daemon connections.
      '';
    };

    stateDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/kip";
      description = ''
        The directory where KIP state, keytabs, and virtual host databases are stored.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."sasl2/Hosted_Identity.conf".text = ''
      mech_list: DIGEST-MD5 ANONYMOUS
      sasldb_path: ${cfg.stateDir}/sasldb2
    '';

    systemd.services.kipd = {
      description = "Keyful Identity Protocol Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        KIP_VARDIR = cfg.stateDir;
        KIP_KEYTAB = "FILE:${cfg.stateDir}/master.keytab";
        SASL_CONF_PATH = "/etc/sasl2";
      };

      serviceConfig = {
        ExecStartPre = pkgs.writeShellScript "kipd-init" ''
          if [ ! -f ${cfg.stateDir}/master.keytab ]; then
            ${pkgs.kip}/bin/a2kip master create service kip vardir ${cfg.stateDir}
            ${pkgs.kip}/bin/a2kip virtual add domain ${cfg.realm} service kip vardir ${cfg.stateDir}
          fi
          echo 'testPassword' | ${pkgs.cyrus_sasl}/bin/saslpasswd2 -p -f ${cfg.stateDir}/sasldb2 -u ${cfg.realm} demo
          echo 'testPassword' | ${pkgs.cyrus_sasl}/bin/saslpasswd2 -p -f ${cfg.stateDir}/sasldb2 demo
          chmod 644 ${cfg.stateDir}/sasldb2
        '';
        ExecStart = "${pkgs.kip}/bin/kipd ${cfg.address} ${toString cfg.port} ${toString cfg.keepalive}";
        StateDirectory = lib.mkIf (cfg.stateDir == "/var/lib/kip") "kip";
        DynamicUser = true;
      };
    };
  };
}
