pkgs: {
  mcp-clickhouse = pkgs.callPackage ./mcp-clickhouse.nix { };
  clickhousectl = pkgs.callPackage ./clickhousectl.nix { };
  terraform-provider-clickhouse = pkgs.callPackage ./terraform-provider-clickhouse.nix { };
}
