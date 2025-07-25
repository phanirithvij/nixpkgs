{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  inherit (pkgs) ntp;

  cfg = config.services.ntp;

  configFile = pkgs.writeText "ntp.conf" ''
    driftfile /var/lib/ntp/ntp.drift

    restrict default ${toString cfg.restrictDefault}
    restrict -6 default ${toString cfg.restrictDefault}
    restrict source ${toString cfg.restrictSource}

    restrict 127.0.0.1
    restrict -6 ::1

    ${toString (map (server: "server " + server + " iburst\n") cfg.servers)}

    ${cfg.extraConfig}
  '';

  ntpFlags = [
    "-c"
    "${configFile}"
    "-u"
    "ntp:ntp"
  ]
  ++ cfg.extraFlags;

in

{

  ###### interface

  options = {

    services.ntp = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to synchronise your machine's time using ntpd, as a peer in
          the NTP network.

          Disables `systemd.timesyncd` if enabled.
        '';
      };

      restrictDefault = mkOption {
        type = types.listOf types.str;
        description = ''
          The restriction flags to be set by default.

          The default flags prevent external hosts from using ntpd as a DDoS
          reflector, setting system time, and querying OS/ntpd version. As
          recommended in section 6.5.1.1.3, answer "No" of
          https://support.ntp.org/Support/AccessRestrictions
        '';
        default = [
          "limited"
          "kod"
          "nomodify"
          "notrap"
          "noquery"
          "nopeer"
        ];
      };

      restrictSource = mkOption {
        type = types.listOf types.str;
        description = ''
          The restriction flags to be set on source.

          The default flags allow peers to be added by ntpd from configured
          pool(s), but not by other means.
        '';
        default = [
          "limited"
          "kod"
          "nomodify"
          "notrap"
          "noquery"
        ];
      };

      servers = mkOption {
        default = config.networking.timeServers;
        defaultText = literalExpression "config.networking.timeServers";
        type = types.listOf types.str;
        description = ''
          The set of NTP servers from which to synchronise.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          fudge 127.127.1.0 stratum 10
        '';
        description = ''
          Additional text appended to {file}`ntp.conf`.
        '';
      };

      extraFlags = mkOption {
        type = types.listOf types.str;
        description = "Extra flags passed to the ntpd command.";
        example = literalExpression ''[ "--interface=eth0" ]'';
        default = [ ];
      };

    };

  };

  ###### implementation

  meta.maintainers = with lib.maintainers; [ thoughtpolice ];

  config = mkIf config.services.ntp.enable {
    # Make tools such as ntpq available in the system path.
    environment.systemPackages = [ pkgs.ntp ];
    services.timesyncd.enable = mkForce false;

    systemd.services.systemd-timedated.environment = {
      SYSTEMD_TIMEDATED_NTP_SERVICES = "ntpd.service";
    };

    users.users.ntp = {
      isSystemUser = true;
      group = "ntp";
      description = "NTP daemon user";
      home = "/var/lib/ntp";
      createHome = true;
    };
    users.groups.ntp = { };

    systemd.services.ntpd = {
      description = "NTP Daemon";

      wantedBy = [ "multi-user.target" ];
      wants = [ "time-sync.target" ];
      before = [ "time-sync.target" ];

      serviceConfig = {
        ExecStart = "@${ntp}/bin/ntpd ntpd -g ${builtins.toString ntpFlags}";
        Type = "forking";

        # Hardening options
        PrivateDevices = true;
        PrivateIPC = true;
        PrivateTmp = true;
        ProtectClock = false;
        ProtectHome = true;

        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = true;

        RestrictNamespaces = true;
        RestrictRealtime = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        AmbientCapabilities = [
          "CAP_SYS_TIME"
        ];

        ProtectControlGroups = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RestrictSUIDSGID = true;
      };
    };

  };

}
