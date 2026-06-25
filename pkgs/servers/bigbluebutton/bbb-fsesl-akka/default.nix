{
  mkSbtDerivation,
  dpkg,
  fakeroot,
  jdk,
  lndir,
  makeWrapper,
  bbb-shared-utils,
  bbb-common-message,
  bbb-fsesl-client,
}:

mkSbtDerivation {
  pname = "bbb-fsesl-akka";
  version = bbb-shared-utils.versionComponent;

  inherit (bbb-shared-utils) src postPatch;

  depsLockfile = ./deps.lock.json;

  strictDeps = true;

  nativeBuildInputs = [
    dpkg
    fakeroot
    lndir
    makeWrapper
  ];

  # TODO where is the warmup phase or something?
  # I didn't notice deps being compiled either unlike the ngipkgs build

  buildPhase = ''
    runHook preBuild

    cd akka-bbb-fsesl

    mkdir -p $HOME/.ivy2/local
    for dep in ${bbb-common-message} ${bbb-fsesl-client}; do
      lndir "$dep" $HOME/.ivy2/local
    done

    sbt debian:packageBin

    find $HOME/.ivy2/local -type l -exec rm -v {} \;

    runHook postBuild
  '';

  # TODO: More hardcoded assumptions in $out/share/bbb-fsesl-akka/conf/*
  installPhase = ''
    runHook preInstall

    dpkg -x target/*.deb $out

    # Fix up Debian-isms

    # No usr please, we have the prefix for that
    mv -vt $out/ $out/usr/*
    rmdir $out/usr

    # Fix broken symlinks, due to prefix not being / and no more usr
    ln -vfs $out/share/bbb-fsesl-akka/conf $out/etc/bbb-fsesl-akka
    ln -vfs $out/share/bbb-fsesl-akka/bin/bbb-fsesl-akka $out/bin/bbb-fsesl-akka

    ln -vfs /var/lib/bbb-fsesl-akka/logs $out/share/bbb-fsesl-akka/logs

    # We won't be using this, since it's read-only
    rm -r $out/var/log
    rmdir $out/var # Just to make sure we notice if there's ever smth else worth keeping here

    # Add Nix-isms

    # Add default Java
    wrapProgram $out/share/bbb-fsesl-akka/bin/bbb-fsesl-akka \
      --set-default JAVA_HOME ${jdk.home}

    runHook postInstall
  '';

  meta = bbb-shared-utils.meta // {
    description = bbb-shared-utils.meta.description + " (bbb-fsesl-akka)";
  };
}
