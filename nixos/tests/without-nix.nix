{
  pkgs,
}:
let
  inherit (pkgs) lib;

  evalConfig = import ../lib/eval-config.nix;

  node = evalConfig {
    system = null;
    modules = [
      {
        nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform.system;
        system.stateVersion = "26.11";
        documentation.enable = false;
        nix.enable = false;
        nixpkgs.overlays = [
          (self: super: {
            nix = throw "don't want to use pkgs.nix";
            nixVersions = lib.mapAttrs (k: throw "don't want to use pkgs.nixVersions.${k}") super.nixVersions;
            # aliases, some deprecated
            nix_2_3 = throw "don't want to use pkgs.nix_2_3";
            nix_2_4 = throw "don't want to use pkgs.nix_2_4";
            nix_2_5 = throw "don't want to use pkgs.nix_2_5";
            nix_2_6 = throw "don't want to use pkgs.nix_2_6";
            nixFlakes = throw "don't want to use pkgs.nixFlakes";
            nixStable = throw "don't want to use pkgs.nixStable";
            nixUnstable = throw "don't want to use pkgs.nixUnstable";
            nixStatic = throw "don't want to use pkgs.nixStatic";
          })
        ];
      }
    ];
  };
in
pkgs.runCommand "without-nix-test"
  {
    meta.maintainers = with lib.maintainers; [ ericson2314 ];
  }
  ''
    export PATH="${node.config.system.path}/bin"
    command -v which
    if command -v nix; then
      echo "nix should not be in PATH" >&2
      exit 1
    fi
    touch $out
  ''
