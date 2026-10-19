# blackmatter-clickhouse

Everything ClickHouse, built here and delivered as one home-manager module trio under `blackmatter.components.clickhouse`.

## Packages

`packages.<system>.*` and `overlays.default`:

| Package | Version | Notes |
|---|---|---|
| `mcp-clickhouse` | 0.7.0 | the official local MCP server, with fastmcp 4 and clickhouse-connect 1.x built in a consistent Python set |
| `clickhousectl` | 0.4.2 | the official Cloud CLI (also `chctl`), rustls, telemetry compiled out (`withTelemetry`) |
| `terraform-provider-clickhouse` | 3.39.0 | `registry.terraform.io/ClickHouse/clickhouse`, for `terraform`/`opentofu.withPlugins` |

## Module

| Option | Renders |
|---|---|
| `enable`, `package` | `pkgs.clickhouse` on PATH (`clickhouse client`) |
| `connections.<name>` | `~/.clickhouse-client/config.xml` `connections_credentials`; `clickhouse client --connection <name>` |
| `connections.<name>.mcp.enable`, `scopes` | anvil MCP server `clickhouse-<name>`: mcp-clickhouse, read-only (`CLICKHOUSE_ALLOW_WRITE_ACCESS=false`), password read from `passwordFile` at start |
| `defaultConnection` | the connection used when none is named; must name an entry of `connections` |
| `mcp.cloud.enable`, `url`, `scopes` | anvil MCP server `clickhouse-cloud`: ClickHouse Cloud's remote MCP over HTTP, substrate's `clickhouse-cloud` kind |
| `cloudCli.enable` | `clickhousectl` on PATH |

The remote MCP answers for every organization the signed-in user belongs to; the agent runs the OAuth sign-in (Claude Code: `/mcp`). A service is reachable only after MCP is enabled on it in the Cloud console (Connect → MCP).

Refused at eval: a `defaultConnection` naming no connection, a local MCP connection without `passwordFile`, a connection named `cloud` beside the remote server.

`config.xml` never carries a password.

```nix
blackmatter.components.clickhouse = {
  enable = true;
  connections.example = {
    host = "abc.us-east-2.aws.clickhouse.cloud";
    passwordFile = "/run/secrets/clickhouse/example";
    mcp.enable = true;
  };
  mcp.cloud.enable = true;
  cloudCli.enable = true;
};
```

`nix flake check` runs `checks.<system>.module-render`.
