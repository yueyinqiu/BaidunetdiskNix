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

  # The unpacked application. Its bundled Electron keeps its original
  # `/lib64/ld-linux-x86-64.so.2` interpreter on purpose: patching the ELF
  # makes it abort right after startup. It is therefore run inside an FHS
  # environment below, which provides that interpreter.
  app = stdenv.mkDerivation {
    pname = "baidunetdisk";
    inherit version;

    src = fetchurl {
      url = "https://pkg-ant.baidu.com/issue/netdisk/LinuxGuanjia/${version}/baidunetdisk_${version}_amd64.deb";
      hash = "sha256-7HHCrRFRYJ/Q2LhtlRhMC0V9bbWqGIYeCxX8I8z+Afc=";
    };

    nativeBuildInputs = [
      makeWrapper
      dpkg
    ];

    # Deliberately *no* autoPatchelfHook — see note above.
    dontPatchELF = true;
    dontAutoPatchelf = true;

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

  # Everything the bundled Electron expects at conventional FHS paths.
  multiPkgs = _: libraries;

  extraInstallCommands = ''
    # Reuse the .desktop shipped in the deb, only fixing the Exec path (the
    # binary is on PATH inside the FHS, and --no-sandbox is added by runScript).
    mkdir -p $out/share/applications $out/share/icons/hicolor/scalable/apps
    sed 's|^Exec=.*|Exec=baidunetdisk %U|' ${app}/baidunetdisk.desktop \
      > $out/share/applications/baidunetdisk.desktop
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
