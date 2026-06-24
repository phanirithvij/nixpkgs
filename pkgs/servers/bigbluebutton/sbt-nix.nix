{
  lib,
  stdenv,
  fetchurl,
  sbt,
  jdk17,
  which,
  runCommand,
}:

let
  mkCoursierCache =
    { lockfilePath }:
    let
      depsLock = builtins.fromJSON (builtins.readFile lockfilePath);
      fetchDep =
        dep:
        fetchurl {
          url = dep.url;
          sha256 = dep.sha256;
        };
    in
    runCommand "coursier-cache" { } ''
      mkdir -p $out
      ${builtins.concatStringsSep "\n" (
        map (
          dep:
          let
            fetched = fetchDep dep;
            cachePath = builtins.replaceStrings [ "://" ] [ "/" ] dep.url;
            cacheDir = builtins.dirOf cachePath;
          in
          ''
            mkdir -p "$out/${cacheDir}"
            cp ${fetched} "$out/${cachePath}"
          ''
        ) depsLock.artifacts
      )}
    '';

  mkSbtSetup =
    {
      coursierCache,
      jdk ? jdk17,
      extraSbtOpts ? "",
    }:
    {
      setupScript = ''
        export HOME=$(mktemp -d)
        export JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS -Duser.home=$HOME"
        export SCALA_CLI_HOME="$HOME/.scala-cli"
        export COURSIER_CACHE="$HOME/.cache/coursier"
        export COURSIER_ARCHIVE_CACHE="$HOME/.cache/coursier-arc"
        export COURSIER_BIN_DIR="$HOME/.local/bin/coursier"
        export COURSIER_CONFIG_DIR="$HOME/.config/coursier"
        export COURSIER_JVM_CACHE="$HOME/.cache/coursier-jvm"

        mkdir -p "$HOME/.cache"
        cp -r ${coursierCache} "$HOME/.cache/coursier"
        chmod -R u+w "$HOME/.cache/coursier"

        export COURSIER_MODE=offline
        export SBT_OPTS="-Dsbt.offline=true -Dsbt.boot.directory=$HOME/.sbt/boot ${extraSbtOpts}"
      '';
      nativeBuildInputs = [
        sbt
        jdk
        which
      ];
      JAVA_HOME = jdk;
    };

  mkSbtDerivation =
    {
      pname,
      version,
      depsLockfile ? ./deps.lock.json,
      ...
    }@args:
    let
      coursierCache = mkCoursierCache { lockfilePath = depsLockfile; };
      setup = mkSbtSetup { inherit coursierCache; };
      drvArgs = builtins.removeAttrs args [
        "depsLockfile"
        "overrideDepsAttrs"
        "depsWarmupCommand"
        "depsArchivalStrategy"
        "depsOptimize"
        "depsSha256"
      ];
    in
    stdenv.mkDerivation (
      drvArgs
      // {
        nativeBuildInputs = (drvArgs.nativeBuildInputs or [ ]) ++ setup.nativeBuildInputs;
        preBuild = ''
          ${setup.setupScript}
          export JAVA_HOME=${setup.JAVA_HOME}
          ${drvArgs.preBuild or ""}
        '';
      }
    );
in
{
  inherit mkCoursierCache mkSbtSetup mkSbtDerivation;
}
