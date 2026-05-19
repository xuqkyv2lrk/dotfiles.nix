{ lib, stdenv, fetchurl, autoPatchelfHook, dpkg, makeWrapper,
  qt5, libusb1, alsa-lib, libudev-zero, avahi, libusbmuxd }:

stdenv.mkDerivation rec {
  pname = "iriun-webcam";
  version = "2.9.1";

  src = fetchurl {
    url = "https://iriun.gitlab.io/iriunwebcam-${version}.deb";
    hash = "sha256-slpTyetT96waR7XvcXSZDdl/Ziacc4hgM5XCxX8WC4Q=";
  };

  nativeBuildInputs = [ autoPatchelfHook dpkg makeWrapper qt5.wrapQtAppsHook ];

  buildInputs = with qt5; [
    qtbase
    qtdeclarative
    qtwayland
    libusb1
    alsa-lib
    libudev-zero
    avahi
    libusbmuxd
  ];

  qtWrapperArgs = [
    "--prefix" "LD_LIBRARY_PATH" ":" "${libusbmuxd}/lib"
  ];

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/local/. $out/
    [[ -d usr/share ]] && cp -r usr/share $out/share
    substituteInPlace $out/share/applications/iriunwebcam.desktop \
      --replace "Exec=/usr/local/bin/iriunwebcam" "Exec=iriunwebcam"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Use your phone as a wireless webcam";
    homepage = "https://iriun.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "iriunwebcam";
  };
}
