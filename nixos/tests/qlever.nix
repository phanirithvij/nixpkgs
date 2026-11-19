{
  pkgs,
  lib,
  ...
}:

let
  olympics-qleverfile = "${pkgs.qlever-control.src}/src/qlever/Qleverfiles/Qleverfile.olympics";
in

{
  name = "Basic QLever test";
  meta.maintainers = lib.teams.ngi.members;

  nodes = {
    machine =
      {
        pkgs,
        ...
      }:
      {
        environment.systemPackages = with pkgs; [
          qlever
          qlever-control
        ];
      };
  };

  testScript =
    # python
    ''
      machine.succeed("cp ${pkgs.qlever.olympics-rdf-data}/olympics.nt /tmp/olympics.nt")
      machine.succeed("cp ${olympics-qleverfile} /tmp/Qleverfile")

      # use qlever binary instead of docker
      machine.succeed("sed -i 's/SYSTEM = docker/SYSTEM = native/' /tmp/Qleverfile")

      machine.succeed("qlever index")

      machine.succeed("qlever start")
      machine.wait_for_open_port(7019) # default server port

      machine.succeed("qlever query")
    '';
}
