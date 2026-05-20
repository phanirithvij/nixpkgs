{ lib, ... }:
{
  _class = "nixosTest";
  name = "backrest-modular";
  nodes.machine =
    { pkgs, ... }:
    {
      system.services.backrest = {
        imports = [ pkgs.backrest.services.default ];
        backrest = {
          address = "0.0.0.0";
        };
      };
      networking.firewall.allowedTCPPorts = [ 9898 ];
    };

  testScript = ''
    machine.wait_for_unit("backrest.service")
    machine.wait_for_open_port(9898)
    machine.succeed("curl -fsS http://localhost:9898")
  '';

  meta.maintainers = with lib.maintainers; [ phanirithvij ];
}
