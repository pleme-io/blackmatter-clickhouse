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
      packagesFor = import ./pkgs;
      trio = (import "${substrate}/lib/module-trio.nix" { inherit lib; }).mkModuleTrio
        (import ./module { inherit mcpHelpers packagesFor; });
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
    in
    lib.recursiveUpdate
    ((import "${substrate}/lib/blackmatter-component-flake.nix") {
      inherit self nixpkgs;
      name = "blackmatter-clickhouse";
      description = "ClickHouse client, connection profiles, the Cloud CLI and the ClickHouse MCP servers";
      modules.homeManager = trio.homeManagerModule;
      overlay = final: _prev: packagesFor final;
      extraChecks = pkgs: {
        module-render = import ./tests/render.nix { inherit pkgs lib trio; };
      };
    })
    {
      packages = lib.genAttrs systems (system: packagesFor (import nixpkgs { inherit system; }));
    };
}
