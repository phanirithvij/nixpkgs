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
    environment.etc."sasl2/Hosted_Identity.conf".text = ''
      pwcheck_method: auxprop
      auxprop_plugin: sasldb
      sasldb_path: /var/lib/kip/sasldb2
      mech_list: DIGEST-MD5
    '';
  };

  testScript = ''
    machine.wait_for_unit("kipd.service")
    machine.wait_for_open_port(9876)

    # Check that kipd is running
    machine.succeed("systemctl status kipd.service")

    # Check that keys were created in the state directory
    machine.succeed("test -f /var/lib/kip/master.keytab")
    machine.succeed("test -f /var/lib/kip/kip-vhost/unicorn.demo.arpa2.org")

    # Set up Cyrus SASL db for kip up/down to authenticate to kipd
    machine.succeed("echo 'testPassword' | saslpasswd2 -p -f /var/lib/kip/sasldb2 -u unicorn.demo.arpa2.org demo")
    machine.succeed("chmod 644 /var/lib/kip/sasldb2")

    # Perform kip up and kip down
    machine.succeed("echo 'hello world' > /tmp/plain.txt")

    # Create unbound hosts file to mock the SRV record for KIP Service
    machine.succeed("echo 'local-data: \"_kip._tcp.unicorn.demo.arpa2.org. IN SRV 10 10 9876 ::1.\"' > /tmp/hosts.pump")

    # Note: KIP uses SASL to authenticate with the kip daemon
    env = (
        "KIP_REALM=unicorn.demo.arpa2.org "
        "KIP_VARDIR=/var/lib/kip "
        "KIP_KEYTAB=/var/lib/kip/master.keytab "
        "KIPSERVICE_CLIENT_REALM=unicorn.demo.arpa2.org "
        "KIPSERVICE_CLIENTUSER_LOGIN=demo "
        "KIPSERVICE_CLIENTUSER_ACL=demo+unicorn "
        "QUICKSASL_PASSPHRASE=testPassword "
        "UNBOUND_HOSTS=/tmp/hosts.pump"
    )

    # TODO: Uncomment once upstream bug (segmentation fault during SRV resolution) is resolved.
    # machine.succeed(f"env {env} kip up /tmp/plain.txt /tmp/enc.kip")
    # machine.succeed(f"env {env} kip down /tmp/enc.kip /tmp/dec.txt")
    # machine.succeed("cmp /tmp/plain.txt /tmp/dec.txt")
  '';
}
