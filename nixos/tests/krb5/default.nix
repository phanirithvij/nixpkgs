{
  pkgs,
  evalSystem,
  ...
}:
{
  example-config = import ./example-config.nix { inherit pkgs evalSystem; };
}
