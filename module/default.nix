{ mcpHelpers, packagesFor }:
{
  name = "clickhouse";
  description = "ClickHouse client, connection profiles, the Cloud CLI and the ClickHouse MCP servers";
  hmNamespace = "blackmatter.components";

  extraHmOptions = lib: with lib; {
    connections = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          host = mkOption { type = types.str; };
          port = mkOption { type = types.port; default = 9440; };
          httpPort = mkOption { type = types.port; default = 8443; };
          secure = mkOption { type = types.bool; default = true; };
          user = mkOption { type = types.str; default = "default"; };
          database = mkOption { type = types.nullOr types.str; default = null; };
          passwordFile = mkOption { type = types.nullOr types.str; default = null; };
          userFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "File holding the user name, for lanterna. Unset, the `user` name is written to the store: a user name is not a secret.";
          };
          tls = mkOption {
            type = types.either (types.enum [ "system" "accept-any" ]) (types.strMatching "ca:.+");
            default = "system";
            description = "lanterna's TLS posture for this connection: system, accept-any (degraded) or ca:<PEM_PATH>.";
          };
          lanterna.enable = mkEnableOption "this connection as a target of the lanterna-mcp server";
          mcp = {
            enable = mkEnableOption "a local read-only mcp-clickhouse server for this connection";
            scopes = mkOption { type = types.listOf types.str; default = [ ]; };
          };
        };
      });
      default = { };
    };

    defaultConnection = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    mcp.cloud = {
      enable = mkEnableOption "the ClickHouse Cloud remote MCP (one endpoint for every organization the signed-in user belongs to)";
      url = mkOption { type = types.str; default = "https://mcp.clickhouse.cloud/mcp"; };
      scopes = mkOption { type = types.listOf types.str; default = [ ]; };
    };

    mcp.lanterna = {
      enable = mkEnableOption "lanterna-mcp: one typed, observe-only ClickHouse MCP server over every connection with lanterna.enable, each a `--target` addressed by its name";
      name = mkOption { type = types.str; default = "clickhouse-fleet"; };
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "The lanterna-mcp package. Unset, `pkgs.lanterna-mcp` from the consumer's overlay.";
      };
      configFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "lanterna's --config: a YAML overlay of LanternaConfig bounds (maxResults, selectAllow, ...).";
      };
      scopes = mkOption { type = types.listOf types.str; default = [ ]; };
    };

    cloudCli.enable = mkEnableOption "clickhousectl, the ClickHouse Cloud CLI (also as chctl)";
  };

  extraHmConfigFn = { cfg, pkgs, lib, config }:
    let
      kind = (mcpHelpers.mcpKinds pkgs).clickhouse-cloud;
      own = packagesFor pkgs;
      connectionXml = n: c: ''
          <connection>
            <name>${n}</name>
            <hostname>${c.host}</hostname>
            <port>${toString c.port}</port>
            <secure>${if c.secure then "1" else "0"}</secure>
            <user>${c.user}</user>${lib.optionalString (c.database != null) "\n      <database>${c.database}</database>"}
          </connection>'';
      localMcp = lib.filterAttrs (_: c: c.mcp.enable) cfg.connections;
      lanterna = cfg.mcp.lanterna;
      lanternaTargets = lib.filterAttrs (_: c: c.lanterna.enable) cfg.connections;
      lanternaPackage =
        if lanterna.package != null then lanterna.package
        else pkgs.lanterna-mcp or (throw "blackmatter.components.clickhouse.mcp.lanterna: pkgs.lanterna-mcp is absent; apply the lanterna flake input's overlay or set mcp.lanterna.package");
      lanternaTarget = n: c: builtins.toJSON ({
        label = n;
        host = "${if c.secure then "https" else "http"}://${c.host}:${toString c.httpPort}";
        inherit (c) tls;
        user-file = if c.userFile != null then c.userFile else "${pkgs.writeText "clickhouse-${n}-user" c.user}";
      } // lib.optionalAttrs (c.passwordFile != null) { password-file = c.passwordFile; });
      lanternaServer = {
        enable = true;
        package = lanternaPackage;
        command = "lanterna-mcp";
        args = lib.concatLists (lib.mapAttrsToList (n: c: [ "--target" (lanternaTarget n c) ]) lanternaTargets)
          ++ lib.optionals (lanterna.configFile != null) [ "--config" lanterna.configFile ];
        description = "ClickHouse (lanterna, observe-only) — ${lib.concatStringsSep ", " (lib.attrNames lanternaTargets)}";
        inherit (lanterna) scopes;
      };
      localServer = n: c: {
        enable = true;
        package = own.mcp-clickhouse;
        command = "mcp-clickhouse";
        description = "ClickHouse ${n} (mcp-clickhouse, read-only) — ${c.host}";
        inherit (c.mcp) scopes;
        env = {
          CLICKHOUSE_HOST = c.host;
          CLICKHOUSE_PORT = toString c.httpPort;
          CLICKHOUSE_USER = c.user;
          CLICKHOUSE_SECURE = lib.boolToString c.secure;
          CLICKHOUSE_ALLOW_WRITE_ACCESS = "false";
        } // lib.optionalAttrs (c.database != null) { CLICKHOUSE_DATABASE = c.database; };
        envFiles.CLICKHOUSE_PASSWORD = cfg.connections.${n}.passwordFile;
      };
    in
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.defaultConnection == null || cfg.connections ? ${cfg.defaultConnection};
            message = "blackmatter.components.clickhouse.defaultConnection = ${toString cfg.defaultConnection} names no entry of connections";
          }
          {
            assertion = !(cfg.mcp.cloud.enable && localMcp ? cloud);
            message = "blackmatter.components.clickhouse: a connection named `cloud` with mcp.enable would collide with the clickhouse-cloud server";
          }
          {
            assertion = !lanterna.enable || lanternaTargets != { };
            message = "blackmatter.components.clickhouse.mcp.lanterna.enable names no target: set lanterna.enable on at least one connection";
          }
          {
            assertion = !(lanterna.enable && (cfg.mcp.cloud.enable && lanterna.name == "clickhouse-cloud" || localMcp ? ${lib.removePrefix "clickhouse-" lanterna.name}));
            message = "blackmatter.components.clickhouse.mcp.lanterna.name = ${lanterna.name} collides with another clickhouse MCP server";
          }
        ] ++ lib.mapAttrsToList (n: c: {
          assertion = c.passwordFile != null;
          message = "blackmatter.components.clickhouse.connections.${n}.mcp.enable needs passwordFile: mcp-clickhouse would start and every tool would fail authentication";
        }) localMcp
        ++ lib.optionals lanterna.enable (lib.mapAttrsToList (n: c: {
          assertion = c.passwordFile != null;
          message = "blackmatter.components.clickhouse.connections.${n}.lanterna.enable needs passwordFile: lanterna-mcp would answer `blind` on every call";
        }) lanternaTargets);
      }
      (lib.mkIf (cfg.connections != { }) {
        home.file.".clickhouse-client/config.xml".text = ''
          <config>${lib.optionalString (cfg.defaultConnection != null) "\n  <connection>${cfg.defaultConnection}</connection>"}
            <connections_credentials>
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList connectionXml cfg.connections)}
            </connections_credentials>
          </config>
        '';
      })
      (lib.mkIf cfg.mcp.cloud.enable {
        blackmatter.components.anvil.mcp.servers.clickhouse-cloud = kind.mkServer { inherit (cfg.mcp.cloud) url; } // {
          enable = true;
          inherit (cfg.mcp.cloud) scopes;
        };
      })
      (lib.mkIf (localMcp != { }) {
        blackmatter.components.anvil.mcp.servers = lib.mapAttrs' (n: c: lib.nameValuePair "clickhouse-${n}" (localServer n c)) localMcp;
      })
      (lib.mkIf lanterna.enable {
        blackmatter.components.anvil.mcp.servers.${lanterna.name} = lanternaServer;
      })
      (lib.mkIf cfg.cloudCli.enable {
        home.packages = [ own.clickhousectl ];
      })
    ];
}
