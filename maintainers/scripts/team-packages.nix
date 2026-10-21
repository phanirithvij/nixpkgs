# maintainers/scripts/team-packages.nix
#
# Constructs a single derivation linking all packages maintained by a team.
# Used to scan team packages with tools like `nix-cacert-scan`.
#
# USAGE:
#   nix-build maintainers/scripts/team-packages.nix --argstr team ngi -o result
#
{
  pkgs ? import ../.. {
    config.allowBroken = false;
    config.allowUnfree = true;
    config.allowUnsupportedSystem = false;
  },
  team ? "ngi",
  packageNames ? null,
  returnList ? false,
}:

let
  inherit (pkgs) lib;

  # Verify team exists in maintainers/team-list.nix (pattern from commit b26df0add817d8f39b25c29305fa74ff07e8f20a)
  myTeam =
    if !builtins.hasAttr team lib.teams then
      throw "Team with name `${team}` does not exist in `maintainers/team-list.nix`."
    else
      builtins.getAttr team lib.teams;

  # Match packages maintained by team (handles both list and attrset)
  isMaintainedByTeam =
    pkg:
    let
      res = builtins.tryEval (
        if builtins.hasAttr "teams" (pkg.meta or { }) then
          (
            if builtins.isList pkg.meta.teams then
              builtins.elem myTeam pkg.meta.teams
            else
              myTeam == pkg.meta.teams
          )
        else
          false
      );
    in
    res.success && res.value;

  isDerivationRobust =
    pkg:
    let
      res = builtins.tryEval (lib.isDerivation pkg);
    in
    res.success && res.value;

  isPkgSet =
    pkg:
    let
      res = builtins.tryEval (lib.isAttrs pkg && (pkg.recurseForDerivations or false));
    in
    res.success && res.value;

  # Recursive package search (pattern from community-projects/ngi-nix-forge/maintainers/list-nixpkgs.nix)
  recursePackageSet =
    prefix: set:
    lib.concatMap (
      name:
      let
        res = builtins.tryEval set.${name};
        pkg = if res.success then res.value else null;
        fullName = if prefix != null then "${prefix}.${name}" else name;
      in
      if pkg == null then
        [ ]
      else if isDerivationRobust pkg then
        let
          isMaintained = isMaintainedByTeam pkg;
          outEval = builtins.tryEval pkg.outPath;
          broken = pkg.meta.broken or false;
        in
        if isMaintained && outEval.success && !broken then
          [
            {
              name = fullName;
              path = pkg;
            }
          ]
        else
          [ ]
      else if isPkgSet pkg then
        recursePackageSet fullName pkg
      else
        [ ]
    ) (lib.attrNames set);

  allPackages = recursePackageSet null pkgs;
  packages =
    if packageNames != null then
      lib.filter (p: builtins.elem p.name packageNames || builtins.elem (lib.getName p.path) packageNames) allPackages
    else
      allPackages;
in
if returnList then
  map (p: p.path) packages
else
  pkgs.linkFarm "${team}-team-packages" packages
