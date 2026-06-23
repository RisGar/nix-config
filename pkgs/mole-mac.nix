{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "mole-mac";
  version = "1.44.0";

  src = fetchFromGitHub {
    owner = "tw93";
    repo = "Mole";
    rev = "V${finalAttrs.version}";
    hash = "sha256-jYNeUCurLMPv7/7Em1vedNjIW3fTcJ3Zu9S3+Ys9ikA=";
  };

  vendorHash = "sha256-HcCJ3DYj5AXX+E5AD6jxBysCq4TAoIs2I6oVN4dCBxQ=";

  subPackages = [
    "cmd/analyze"
    "cmd/status"
  ];

  ldflags = [
    "-s"
    "-w"
  ];

  postInstall = ''
    libexec="$out/libexec"
    mkdir -p "$libexec"
    cp -r bin lib "$libexec/"

    install -m755 mole "$out/bin/mole"
    ln -s "$out/bin/mole" "$out/bin/mo"

    install -m755 "$out/bin/analyze" "$libexec/bin/analyze-go"
    install -m755 "$out/bin/status" "$libexec/bin/status-go"
    rm -f "$out/bin/analyze" "$out/bin/status"

    substituteInPlace "$out/bin/mole" \
      --replace-fail 'SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"' "SCRIPT_DIR=\"$out/libexec\""
  '';

  doCheck = false;

  meta = {
    description = "Deep clean and optimize your Mac";
    homepage = "https://github.com/tw93/Mole";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "mo";
  };
})
