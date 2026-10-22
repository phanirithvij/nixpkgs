{
  ccacheDir ? "/tmp/ccache",
  pkgs ? import ./. {
    overlays = [
      # https://wiki.nixos.org/wiki/CCache
      (self: super: {
        ccacheWrapper = super.ccacheWrapper.override {
          extraConfig = ''
            export CCACHE_COMPRESS=1
            export CCACHE_DIR="${ccacheDir}"
            export CCACHE_UMASK=007
            if [ ! -d "$CCACHE_DIR" ]; then
              echo "====="
              echo "Directory '$CCACHE_DIR' does not exist"
              echo "Please create it with:"
              echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
              echo "  sudo chown root:nixbld '$CCACHE_DIR'"
              echo "====="
              exit 1
            fi
            if [ ! -w "$CCACHE_DIR" ]; then
              echo "====="
              echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
              echo "Please verify its access permissions"
              echo "====="
              exit 1
            fi
          '';
        };
      })
    ];
  },
}:
with pkgs;
{
  # nix-build -A init file.nix
  init = writeShellScriptBin "init-ccache-dir" ''
    mkdir -p ${ccacheDir}
    chmod -R 777 ${ccacheDir}
  '';
  # nix-build -A build file.nix --option extra-sandbox-paths /tmp/ccache
  inherit
    libreoffice-collabora
    libreoffice-still
    libreoffice-fresh
    libreoffice
    collabora-online
    collabora-desktop
    ;
  build = libreoffice-collabora.override {
    variant = "collabora-coda";
    withFonts = true;
    withJava = false;
  };
  # build = collabora-desktop;
  nextcloud-test = collabora-online.passthru.tests.nextcloud;
  # nix-build -A watch file.nix
  # NOTE:
  # without root permission, pretend to be nixbld to get ccache stats
  watch = writeShellScriptBin "nix-ccache-watch" (
    let
      nixScript = writeText "ccache-stats.nix" ''
        with import <nixpkgs> { };
        stdenv.mkDerivation {
          dontUnpack = true;
          buildPhase = ${"''"}
            ''${lib.getExe ccache} -s -d ${ccacheDir}
            touch $out
          ${"''"};
          name = "ccache-stats";
        }
      '';
    in
    ''
      nix-build ${nixScript} --option extra-sandbox-paths ${ccacheDir} --no-out-link 2>&1 >/dev/null
      ${lib.getExe viddy} --disable_auto_save -n 1 -d '
          nix-build ${nixScript} \
            --option extra-sandbox-paths ${ccacheDir} \
            --no-out-link \
            --check 2>&1 \
          | sed -n "/Cacheable calls:/,/Running phase: installPhase/{ /Running phase:/d; p; }"
        '
    ''
    # | grep -A 9 "Cacheable calls:"
  );
  clear-ccache-stats = writeShellScriptBin "clear-ccache-stats" (
    let
      nixScript = writeText "ccache-stats.nix" ''
        with import <nixpkgs> { };
        stdenv.mkDerivation {
          dontUnpack = true;
          buildPhase = ${"''"}
            ''${lib.getExe ccache} -z -d ${ccacheDir}
            touch $out
          ${"''"};
          name = "ccache-stats-clear";
        }
      '';
    in
    ''
      nix-build ${nixScript} --option extra-sandbox-paths ${ccacheDir}
    ''
  );
  devtools = writeShellScriptBin "init-devtools" ''
    nix profile add nixpkgs#{lf,lazygit,gdu,duf,btop,sysz,git,tmux,nix-output-monitor,micro,fzf,ccache,nixfmt,viddy,neovim}
  '';
}
