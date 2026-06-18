{ pkgs, lib, ... }: {
  name = "kip";
  meta.maintainers = lib.teams.ngi.members;

  nodes.machine = {
    services.kip = {
      enable = true;
      realm = "unicorn.demo.arpa2.org";
    };
    environment.systemPackages = [
      pkgs.kip
      pkgs.cyrus_sasl
    ];
    environment.etc."sasl2/kip.conf".text = ''
      pwcheck_method: auxprop
      auxprop_plugin: sasldb
      sasldb_path: /var/lib/kip/sasldb2
      mech_list: DIGEST-MD5 ANONYMOUS
    '';
    systemd.services.kipd.environment.KIPSERVICE_SERVERUSER_LOGIN = "kip@unicorn.demo.arpa2.org";
  };

  testScript = /* python */ ''
    machine.wait_for_unit("kipd.service")
    machine.wait_for_open_port(9876)

    # Check that kipd is running
    machine.succeed("systemctl status kipd.service")

    # Check that keys were created in the state directory
    machine.succeed("test -f /var/lib/kip/master.keytab")
    machine.succeed("test -f /var/lib/kip/kip-vhost/unicorn.demo.arpa2.org")

    machine.succeed("systemctl restart kipd.service")
    machine.wait_for_open_port(9876)

    # Perform kip up and kip down
    machine.succeed("echo 'hello world' > /tmp/plain.txt")

    # Create unbound config file to mock the SRV record for KIP Service
    machine.succeed("echo 'server:' > /tmp/hosts.pump")
    machine.succeed("echo '  local-data: \"_kip._tcp.unicorn.demo.arpa2.org. IN SRV 10 10 9876 localhost.\"' >> /tmp/hosts.pump")
    machine.succeed("echo '  local-data: \"localhost. IN A 127.0.0.1\"' >> /tmp/hosts.pump")
    machine.succeed("echo '  local-data: \"localhost. IN AAAA ::1\"' >> /tmp/hosts.pump")

    # Note: KIP uses SASL to authenticate with the kip daemon
    env_vars = {
        "KIP_KEYTAB": "/var/lib/kip/master.keytab",
        "KIP_REALM": "unicorn.demo.arpa2.org",
        "KIP_VARDIR": "/var/lib/kip",
        "KIPSERVICE_CLIENT_REALM": "unicorn.demo.arpa2.org",
        "KIPSERVICE_SERVERUSER_LOGIN": "kip@unicorn.demo.arpa2.org",
        "KIPSERVICE_CLIENTUSER_LOGIN": "demo@unicorn.demo.arpa2.org",
        "KIPSERVICE_CLIENTUSER_ACL": "demo+unicorn@unicorn.demo.arpa2.org",
        "QUICKSASL_PASSPHRASE": "testPassword",
        "UNBOUND_CONFIG": "/tmp/hosts.pump"
    }
    env = " ".join([f"{k}={v}" for k,v in env_vars.items()])

    status, output = machine.execute(f"env {env} kip up /tmp/plain.txt /tmp/enc.kip")
    if status != 0:
        machine.succeed("journalctl -u kipd.service > /tmp/journal.log")
        machine.copy_from_machine("/tmp/journal.log", "")
        raise Exception(f"kip up failed with status {status}. Output: {output}")
    status, output = machine.execute(f"env {env} kip down /tmp/enc.kip /tmp/dec.txt > /tmp/kip_down.out 2> /tmp/kip_down.err")
    if status != 0:
        machine.succeed("cat /tmp/kip_down.err >&2")
        machine.succeed("cat /tmp/kip_down.out >&2")
        raise Exception(f"kip down failed with status {status}. Output: {output}")
    machine.succeed("cmp /tmp/plain.txt /tmp/dec.txt")
  '';
}
