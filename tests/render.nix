{ pkgs, lib, trio }:
let
  hmLib = lib.extend (_: _: { hm.dag.entryAfter = _: text: text; });
  stubs = { ... }: {
    options = {
      assertions = lib.mkOption { type = lib.types.listOf lib.types.unspecified; default = [ ]; };
      warnings = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
      home.packages = lib.mkOption { type = lib.types.listOf lib.types.package; default = [ ]; };
      home.homeDirectory = lib.mkOption { type = lib.types.str; default = "/home/op"; };
      home.file = lib.mkOption { type = lib.types.attrsOf lib.types.unspecified; default = { }; };
      home.activation = lib.mkOption { type = lib.types.attrsOf lib.types.unspecified; default = { }; };
      launchd.agents = lib.mkOption { type = lib.types.attrsOf lib.types.unspecified; default = { }; };
      systemd.user.services = lib.mkOption { type = lib.types.attrsOf lib.types.unspecified; default = { }; };
      blackmatter.components.anvil.mcp.servers = lib.mkOption { type = lib.types.attrsOf lib.types.unspecified; default = { }; };
    };
    config._module.args = { inherit pkgs; };
  };
  eval = cfg: (hmLib.evalModules {
    modules = [ trio.homeManagerModule stubs { config.blackmatter.components.clickhouse = cfg; } ];
  }).config;

  on = eval {
    enable = true;
    defaultConnection = "aws-staging";
    connections.aws-staging = { host = "abc.us-east-2.aws.clickhouse.cloud"; database = "logs"; };
    connections.gcp-shared = { host = "def.us-central1.gcp.clickhouse.cloud"; secure = false; port = 9000; };
    connections.azure-prod = { host = "ghi.eastus2.azure.clickhouse.cloud"; passwordFile = "/run/secrets/ch/azure-prod"; mcp = { enable = true; scopes = [ "akeyless" ]; }; };
    mcp.cloud = { enable = true; scopes = [ "akeyless" ]; };
    cloudCli.enable = true;
  };
  local = on.blackmatter.components.anvil.mcp.servers.clickhouse-azure-prod;
  noPassword = eval { enable = true; connections.x = { host = "h"; mcp.enable = true; }; };
  xml = on.home.file.".clickhouse-client/config.xml".text;
  srv = on.blackmatter.components.anvil.mcp.servers.clickhouse-cloud;

  off = eval { enable = true; };
  badDefault = eval { enable = true; defaultConnection = "nope"; connections.a.host = "h"; };

  checks = {
    xml-names-every-connection = lib.hasInfix "<name>aws-staging</name>" xml && lib.hasInfix "<name>gcp-shared</name>" xml;
    xml-default-connection = lib.hasInfix "<connection>aws-staging</connection>" xml;
    xml-secure-and-port = lib.hasInfix "<secure>0</secure>" xml && lib.hasInfix "<port>9000</port>" xml && lib.hasInfix "<port>9440</port>" xml;
    xml-database-only-when-set = lib.hasInfix "<database>logs</database>" xml && (lib.length (lib.splitString "<database>" xml) == 2);
    mcp-is-http-cloud = srv.transport == "http" && srv.url == "https://mcp.clickhouse.cloud/mcp" && srv.scopes == [ "akeyless" ] && srv.enable;
    off-renders-nothing = !(off.home.file ? ".clickhouse-client/config.xml") && off.blackmatter.components.anvil.mcp.servers == { };
    bad-default-is-refused = lib.any (a: !a.assertion) badDefault.assertions;
    local-mcp-is-read-only-stdio = local.command == "mcp-clickhouse" && local.env.CLICKHOUSE_ALLOW_WRITE_ACCESS == "false" && local.env.CLICKHOUSE_PORT == "8443" && local.envFiles.CLICKHOUSE_PASSWORD == "/run/secrets/ch/azure-prod" && local.scopes == [ "akeyless" ];
    local-mcp-only-where-enabled = !(on.blackmatter.components.anvil.mcp.servers ? clickhouse-aws-staging);
    cloud-cli-installed = lib.any (p: (p.pname or "") == "clickhousectl") on.home.packages;
    local-mcp-without-password-is-refused = lib.any (a: !a.assertion) noPassword.assertions;
  };
  failed = lib.attrNames (lib.filterAttrs (_: ok: !ok) checks);
in
pkgs.runCommand "blackmatter-clickhouse-render" { } (
  if failed == [ ] then "touch $out"
  else "echo 'failed: ${lib.concatStringsSep " " failed}' >&2; exit 1"
)
