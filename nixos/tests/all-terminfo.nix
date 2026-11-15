{
  pkgs,
  evalSystem,
}:
let
  inherit (pkgs) lib;

  # Use derivations instead of attr names to avoid listing missing packages
  maskedTerminfos = with pkgs; [
    alacritty-graphics # would clobber alacritty terminfo
  ];
  infoFilter =
    name: drv:
    let
      o = builtins.tryEval drv;
    in
    o.success
    && lib.isDerivation o.value
    && o.value ? outputs
    && builtins.elem "terminfo" o.value.outputs
    && !o.value.meta.broken
    && lib.meta.availableOn pkgs.stdenv.hostPlatform o.value
    && !(builtins.elem o.value maskedTerminfos);
  terminfos = lib.filterAttrs infoFilter pkgs;

  node = evalSystem {
    system.stateVersion = "26.11";
    environment.enableAllTerminfo = true;
  };

  excludedTerminfos = lib.filterAttrs (
    _: drv: !(builtins.elem drv.terminfo node.config.environment.systemPackages)
  ) terminfos;
  includedOuts = lib.filterAttrs (
    _: drv: builtins.elem drv.out node.config.environment.systemPackages
  ) terminfos;

  missingText = builtins.concatStringsSep "\n" (builtins.attrNames excludedTerminfos);
  extraOutsText = builtins.concatStringsSep "\n" (builtins.attrNames includedOuts);
in
pkgs.runCommand "all-terminfo"
  {
    meta.maintainers = with pkgs.lib.maintainers; [ jkarlson ];
  }
  ''
    missing='${missingText}'
    extraOuts='${extraOutsText}'

    if [ -n "$missing" ]; then
      echo "Missing terminfos: $missing" >&2
      exit 1
    fi
    if [ -n "$extraOuts" ]; then
      echo "Extra terminfo outs included: $extraOuts" >&2
      exit 1
    fi

    touch $out
  ''
