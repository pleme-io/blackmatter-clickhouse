{ mcpHelpers }:
{
  name = "clickhouse";
  description = "ClickHouse client, connection profiles and the ClickHouse Cloud MCP";
  hmNamespace = "blackmatter.components";

  extraHmOptions = lib: with lib; {
    connections = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          host = mkOption { type = types.str; };
          port = mkOption { type = types.port; default = 9440; };
          secure = mkOption { type = types.bool; default = true; };
          user = mkOption { type = types.str; default = "default"; };
          database = mkOption { type = types.nullOr types.str; default = null; };
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
  };

  extraHmConfigFn = { cfg, pkgs, lib, config }:
    let
      kind = (mcpHelpers.mcpKinds pkgs).clickhouse-cloud;
      connectionXml = n: c: ''
          <connection>
            <name>${n}</name>
            <hostname>${c.host}</hostname>
            <port>${toString c.port}</port>
            <secure>${if c.secure then "1" else "0"}</secure>
            <user>${c.user}</user>${lib.optionalString (c.database != null) "\n      <database>${c.database}</database>"}
          </connection>'';
    in
    lib.mkMerge [
      {
        assertions = [{
          assertion = cfg.defaultConnection == null || cfg.connections ? ${cfg.defaultConnection};
          message = "blackmatter.components.clickhouse.defaultConnection = ${toString cfg.defaultConnection} names no entry of connections";
        }];
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
    ];
}
