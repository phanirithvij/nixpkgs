{ mkDprintPlugin, ... }:
mkDprintPlugin {
  changelog = "https://github.com/g-plane/pretty_graphql/releases/v0.2.1";
  description = "GraphQL formatter.";
  hash = "sha256-PlQwpR0tMsghMrOX7is+anN57t9xa9weNtoWpc0E9ec=";
  homepage = "https://github.com/g-plane/pretty_graphql";
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
  url = "https://plugins.dprint.dev/g-plane/pretty_graphql-v0.2.1.wasm";
  version = "v0.2.1";
}
