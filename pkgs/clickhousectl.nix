{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  perl,
  withTelemetry ? false,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "clickhousectl";
  version = "0.4.2";

  src = fetchFromGitHub {
    owner = "ClickHouse";
    repo = "clickhousectl";
    tag = "v${finalAttrs.version}";
    hash = "sha256-RaW9EJPVoRNSDwcpMbqFcmk070xMCsgz/SDDiDxrSTI=";
  };

  cargoHash = "sha256-6Tca4lpV+oMn6R503xjPg0OFpYJ9KBOu7A4/+qWrcoI=";

  cargoBuildFlags = [ "--package" "clickhousectl" ];

  buildNoDefaultFeatures = !withTelemetry;

  nativeBuildInputs = [
    cmake
    perl
  ];

  cargoTestFlags = [
    "--package"
    "clickhousectl"
    "--bins"
  ];

  checkFlags = [
    "--skip=local::server::tests::the_escalation_path_kills_the_server_the_watchdog_supervised"
  ];

  postInstall = ''
    ln -s clickhousectl $out/bin/chctl
  '';

  meta = {
    description = "Official CLI for ClickHouse and ClickHouse Cloud";
    homepage = "https://github.com/ClickHouse/clickhousectl";
    changelog = "https://github.com/ClickHouse/clickhousectl/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "clickhousectl";
    platforms = lib.platforms.unix;
  };
})
