{ mkDprintPlugin, ... }:
let
  version = "v0.2.1";
  hash = "sha256-PlQwpR0tMsghMrOX7is+anN57t9xa9weNtoWpc0E9ec=";
  homepage = "https://github.com/g-plane/pretty_graphql";
in
mkDprintPlugin (
  {
    description = "GraphQL formatter.";
    initConfig = {
      configExcludes = [ ];
      configKey = "graphql";
      fileExtensions = [
        "graphql"
        "gql"
      ];
    };
    pname = "g-plane-pretty_graphql";
    updateUrl = "https://plugins.dprint.dev/g-plane/pretty_graphql/latest.json";
  }
  // {
    inherit version hash homepage;
    url = "https://plugins.dprint.dev/g-plane/pretty_graphql-${version}.wasm";
    changelog = "${homepage}/releases/${version}";
  }
)
