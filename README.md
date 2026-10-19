# blackmatter-clickhouse

Home-manager module trio for ClickHouse, under `blackmatter.components.clickhouse`.

| Option | Renders |
|---|---|
| `enable`, `package` | `pkgs.clickhouse` on PATH (`clickhouse client`) |
| `connections.<name>` | `~/.clickhouse-client/config.xml` `connections_credentials`; pick one with `clickhouse client --connection <name>` |
| `defaultConnection` | the connection used when none is named; must name an entry of `connections` |
| `mcp.cloud.enable`, `url`, `scopes` | one anvil MCP server `clickhouse-cloud`, ClickHouse Cloud's remote MCP over HTTP, through substrate's `clickhouse-cloud` kind |

The remote MCP answers for every organization the signed-in user belongs to, so one entry covers every tenant. The agent runs the OAuth sign-in (Claude Code: `/mcp`). A service is only reachable after MCP is enabled on it in the Cloud console (Connect → MCP).

Passwords are not rendered: `config.xml` carries host, port, TLS, user and database only.

```nix
blackmatter.components.clickhouse = {
  enable = true;
  connections.example = { host = "abc.us-east-2.aws.clickhouse.cloud"; };
  mcp.cloud = { enable = true; scopes = [ "work" ]; };
};
```

Pending:

- `pending-local-mcp`: the local `mcp-clickhouse` server needs fastmcp 4 and clickhouse-connect 1.x, which nixpkgs does not carry yet (2.12 and 0.8 at the substrate pin, 2026-10-19).
- `pending-clickhousectl`: the official Cloud CLI is not in nixpkgs.

`nix flake check` runs `checks.<system>.module-render`.
