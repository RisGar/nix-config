{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "clippy-mac";
  version = "1.6.9";

  src = fetchFromGitHub {
    owner = "neilberkman";
    repo = "clippy";
    rev = "v${finalAttrs.version}";
    hash = "sha256-8OdT+R4dvJCLhelIAsAgVoWGGwmWueTsiJFpCm1uQEc=";
  };

  vendorHash = "sha256-7do+KgoiIocS+mq2hsgv3NOd+TjMl2I9ew2Emx3/Bbg=";

  subPackages = [
    "cmd/clippy"
    "cmd/pasty"
  ];

  ldflags = [
    "-s"
    "-w"
  ];

  doCheck = false;

  meta = {
    description = "Unified clipboard tool for macOS";
    homepage = "https://github.com/neilberkman/clippy";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "clippy";
  };
})
