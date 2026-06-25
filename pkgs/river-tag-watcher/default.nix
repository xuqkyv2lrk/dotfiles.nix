{ stdenv, wayland, wayland-scanner, pkg-config }:

stdenv.mkDerivation {
  pname   = "river-tag-watcher";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ wayland-scanner pkg-config ];
  buildInputs       = [ wayland ];

  buildPhase = ''
    wayland-scanner client-header \
      river-status-unstable-v1.xml \
      river-status-unstable-v1-client-protocol.h

    wayland-scanner private-code \
      river-status-unstable-v1.xml \
      river-status-unstable-v1-client-protocol.c

    $CC -O2 -o river-tag-watcher \
      river-tag-watcher.c \
      river-status-unstable-v1-client-protocol.c \
      $(pkg-config --cflags --libs wayland-client)
  '';

  installPhase = ''
    install -Dm755 river-tag-watcher $out/bin/river-tag-watcher
  '';
}
