{ pkgs, ... }:

{
  name = "liberaforms";
  meta.maintainers = with pkgs.lib.maintainers; [ ];

  nodes.machine =
    { config, pkgs, ... }:
    {
      services.liberaforms = {
        enable = true;
        domain = "localhost";
        useHTTPS = false;
        rootUser = "admin@example.org";
        secretKeyFile = pkgs.writeText "secret" ''
          SECRET_KEY=something-secret
          DB_PASSWORD=
        '';
      };

      services.postgresql = {
        enable = true;
        initialScript = pkgs.writeText "init.sql" ''
          CREATE ROLE liberaforms WITH LOGIN;
          CREATE DATABASE liberaforms OWNER liberaforms;
        '';
      };

      environment.systemPackages = [ config.services.liberaforms.package ];
    };

  testScript =
    { nodes, ... }:
    ''
      machine.wait_for_unit("postgresql.service")
      machine.wait_for_unit("liberaforms.service", timeout=300)

      # Initialize user and site using full path to manage script
      machine.succeed("su liberaforms -s /bin/sh -c '${nodes.machine.services.liberaforms.package}/bin/liberaforms-manage user create -role admin root admin@example.org not-so-secret' >&2")

      machine.wait_for_open_port(5000)

      # Check if the site is reachable and contains expected text
      machine.succeed("curl --fail http://localhost:5000 | grep 'LiberaForms; ethical form software'")
    '';
}
