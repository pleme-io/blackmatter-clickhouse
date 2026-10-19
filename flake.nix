{
  description = "Blackmatter ClickHouse — ClickHouse client, connection profiles and the ClickHouse Cloud MCP";

  inputs = {
    nixpkgs.follows = "substrate/nixpkgs";
    substrate.url = "github:pleme-io/substrate";
  };

  outputs =
    { self, nixpkgs, substrate, ... }:
    let
      lib = nixpkgs.lib;
      mcpHelpers = import "${substrate}/lib/hm-mcp-helpers.nix" { inherit lib; };
      trio = (import "${substrate}/lib/module-trio.nix" { inherit lib; }).mkModuleTrio
        (import ./module { inherit mcpHelpers; });
    in
    (import "${substrate}/lib/blackmatter-component-flake.nix") {
      inherit self nixpkgs;
      name = "blackmatter-clickhouse";
      description = "ClickHouse client, connection profiles and the ClickHouse Cloud MCP";
      modules.homeManager = trio.homeManagerModule;
      extraChecks = pkgs: {
        module-render = import ./tests/render.nix { inherit pkgs lib trio; };
      };
    };
}
