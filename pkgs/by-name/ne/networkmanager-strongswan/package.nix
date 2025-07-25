{
  stdenv,
  lib,
  fetchurl,
  intltool,
  pkg-config,
  networkmanager,
  strongswanNM,
  gtk3,
  gtk4,
  libsecret,
  libnma,
  libnma-gtk4,
}:

stdenv.mkDerivation rec {
  pname = "NetworkManager-strongswan";
  version = "1.6.2";

  src = fetchurl {
    url = "https://download.strongswan.org/NetworkManager/${pname}-${version}.tar.bz2";
    sha256 = "sha256-jL8kf63MsCbTTvYn1M7YbpUOMXPl2h/ZY7Rpz2rAr34=";
  };

  nativeBuildInputs = [
    intltool
    pkg-config
  ];

  buildInputs = [
    networkmanager
    strongswanNM
    libsecret
    gtk3
    gtk4
    libnma
    libnma-gtk4
  ];

  configureFlags = [
    "--disable-more-warnings" # disables -Werror
    "--with-charon=${strongswanNM}/libexec/ipsec/charon-nm"
    "--with-nm-libexecdir=${placeholder "out"}/libexec"
    "--with-nm-plugindir=${placeholder "out"}/lib/NetworkManager"
    "--with-gtk4"
  ];

  PKG_CONFIG_LIBNM_VPNSERVICEDIR = "${placeholder "out"}/lib/NetworkManager/VPN";

  passthru = {
    networkManagerPlugin = "VPN/nm-strongswan-service.name";
    networkManagerDbusDeps = [ strongswanNM ];
    networkManagerTmpfilesRules = [
      "d /etc/ipsec.d 0700 root root -"
    ];
  };

  meta = with lib; {
    description = "NetworkManager's strongswan plugin";
    inherit (networkmanager.meta) platforms;
    license = licenses.gpl2Plus;
  };
}
