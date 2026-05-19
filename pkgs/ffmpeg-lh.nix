{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname = "ffmpeg-lh";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "indiscipline";
    repo = "ffmpeg-loudnorm-helper";
    rev = "v0.2.1";
    hash = "sha256-tbqPAjzBTzRSTHRyGAu6GGe0jeZp7tdFhFTO4Onzqf4=";
  };

  cargoLock.lockFile = ./ffmpeg-lh-Cargo.lock;

  # upstream does not commit Cargo.lock; inject the generated one
  postPatch = ''
    cp ${./ffmpeg-lh-Cargo.lock} Cargo.lock
  '';

  meta = with lib; {
    description = "Helper for FFmpeg's loudnorm filter";
    homepage = "https://github.com/indiscipline/ffmpeg-loudnorm-helper";
    license = licenses.gpl3Plus;
    mainProgram = "ffmpeg-lh";
  };
}
