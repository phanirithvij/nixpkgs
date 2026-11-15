{
  pkgs,
  evalSystem,
}:
let
  settingName = "prefix";
  settingValue = "/some/path";

  node = evalSystem {
    system.stateVersion = "26.11";
    programs.npm = {
      enable = true;
      npmrc = ''
        ${settingName} = ${settingValue}
      '';
    };
  };
in
pkgs.runCommand "npmrc-test"
  {
    nativeBuildInputs = [ node.config.programs.npm.package ];
    meta.maintainers = [ ];
  }
  ''
    export NPM_CONFIG_GLOBALCONFIG="${node.config.environment.etc.npmrc.source}"
    val="$(npm config get ${settingName})"
    [[ "$val" == "${settingValue}" ]]
    touch $out
  ''
