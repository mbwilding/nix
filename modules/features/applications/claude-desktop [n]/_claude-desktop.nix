{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libappindicator-gtk3,
  libayatana-appindicator,
  libdrm,
  libgbm,
  libnotify,
  libsecret,
  libuuid,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxtst,
  nspr,
  nss,
  pango,
  systemd,
  xdg-utils,
}:

let
  pname = "claude-desktop";
  version = "1.37937.1";

  sources = {
    "x86_64-linux" = {
      url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
      hash = "sha256-ZrvGHdBGS1UMTWOBJSARnoNEtGJUHeRHlzUriRiEL08=";
    };
    "aarch64-linux" = {
      url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_arm64.deb";
      hash = "sha256-wUgsOU0vPvQcw3oROR+ZmAtY7rW1OJFSSZw4dHiaB/c=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  src = fetchurl { inherit (source) url hash; };

  rpath =
    lib.makeLibraryPath [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      libappindicator-gtk3
      libayatana-appindicator
      libdrm
      libgbm
      libnotify
      libsecret
      libuuid
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      libxtst
      nspr
      nss
      pango
      stdenv.cc.cc
      systemd
    ]
    + ":${lib.getLib stdenv.cc.cc}/lib64";
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    dpkg
    makeWrapper
  ];

  buildInputs = [
    gtk3 # needed for GSETTINGS_SCHEMAS_PATH
  ];

  dontUnpack = true;
  dontBuild = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    dpkg --fsys-tarfile $src | tar --extract
    # Setuid sandbox helper: unused, NixOS uses the unprivileged userns sandbox instead
    rm -rf usr/share/lintian usr/lib/claude-desktop/chrome-sandbox

    mkdir -p $out
    mv usr/* $out
    chmod -R g-w $out

    for file in $(find $out -type f \( -perm /0111 -o -name '*.so*' \)); do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$file" || true
      patchelf --set-rpath ${rpath}:$out/lib/claude-desktop "$file" || true
    done

    rm $out/bin/claude-desktop
    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      --prefix XDG_DATA_DIRS : $GSETTINGS_SCHEMAS_PATH \
      --suffix PATH : ${lib.makeBinPath [ xdg-utils ]}

    runHook postInstall
  '';

  meta = {
    description = "Desktop application for Claude.ai";
    homepage = "https://claude.ai";
    downloadPage = "https://code.claude.com/docs/en/desktop-linux";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = with lib.maintainers; [ mbwilding ];
    platforms = builtins.attrNames sources;
    mainProgram = pname;
  };
}
