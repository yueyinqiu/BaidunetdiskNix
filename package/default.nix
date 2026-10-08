{
  lib,
  stdenv,
  buildFHSEnv,
  fetchurl,
  dpkg,
  makeWrapper,
  udev,
  # runtime libraries
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  atkmm,
  cairo,
  cairomm,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  glibmm,
  gtk2,
  gtk3,
  gtkmm2,
  libappindicator,
  libdbusmenu,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libpulseaudio,
  libsigcxx,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxt,
  libxtst,
  mesa,
  nspr,
  nss,
  pango,
  pangomm,
  systemd,
  xz,
}:

let
  version = "8.7.0";

  libraries = [
    stdenv.cc.cc.lib
    udev
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    atkmm
    cairo
    cairomm
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    glibmm
    gtk2
    gtk3
    gtkmm2
    libappindicator
    libdbusmenu
    libdrm
    libgbm
    libglvnd
    libnotify
    libpulseaudio
    libsigcxx
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxscrnsaver
    libxshmfence
    libxt
    libxtst
    mesa
    nspr
    nss
    pango
    pangomm
    systemd
    xz
  ];

  app = stdenv.mkDerivation {
    pname = "baidunetdisk";
    version = version;

    src = fetchurl {
      url = "https://pkg-ant.baidu.com/issue/netdisk/LinuxGuanjia/${version}/baidunetdisk_${version}_amd64.deb";
      hash = "sha256-7HHCrRFRYJ/Q2LhtlRhMC0V9bbWqGIYeCxX8I8z+Afc=";
    };

    nativeBuildInputs = [
      makeWrapper
      dpkg
    ];

    dontPatchELF = true;

    unpackPhase = ''
      runHook preUnpack
      dpkg -x $src .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r opt/baidunetdisk/* $out/

      # The bundled sandbox / crash handler need setuid, which does not work in Nix.
      rm -f $out/chrome-sandbox $out/chrome_crashpad_handler $out/baidunetdiskhost

      # The bundled locale packs trigger "Invalid file descriptor to ICU data"
      # and the app aborts right after startup.
      rm -rf $out/LICENSE.* $out/locales

      # Drop Windows/macOS-only native addons.
      find $out/resources/app.asar.unpacked -path "*/build/node_gyp_bins/*" -delete 2>/dev/null || true
      find $out/resources/app.asar.unpacked -path "*/windows-*/*" -delete 2>/dev/null || true
      find $out/resources/app.asar.unpacked -path "*/macos-*/*" -delete 2>/dev/null || true

      mkdir -p $out/bin
      makeWrapper $out/baidunetdisk $out/bin/baidunetdisk \
        --add-flags "--no-sandbox"

      runHook postInstall
    '';
  };
in
buildFHSEnv {
  name = "baidunetdisk";
  version = version;

  targetPkgs = _: [ app ];
  runScript = "baidunetdisk";

  multiPkgs = _: libraries;

  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/icons/hicolor/scalable/apps
    cp ${app}/baidunetdisk.desktop $out/share/applications/baidunetdisk.desktop
    substituteInPlace $out/share/applications/baidunetdisk.desktop \
      --replace-fail 'Exec=/opt/baidunetdisk/baidunetdisk --no-sandbox %U' \
                     "Exec=$out/bin/baidunetdisk %U"
    ln -s ${app}/baidunetdisk.svg \
      $out/share/icons/hicolor/scalable/apps/baidunetdisk.svg
  '';

  meta = {
    description = "Baidu Netdisk (百度网盘)";
    homepage = "https://pan.baidu.com/";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "baidunetdisk";
  };
}
