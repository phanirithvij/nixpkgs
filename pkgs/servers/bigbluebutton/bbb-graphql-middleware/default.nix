{
  lib,
  bbb-shared-utils,
  buildGoModule,
}:

buildGoModule {
  pname = "bbb-graphql-middleware";
  version = bbb-shared-utils.versionComponent;
  src = "${bbb-shared-utils.src}/bbb-graphql-middleware";

  vendorHash = "sha256-naEZwxrxsMoLrLH4ZT++EtNpXf2UxIX+9YmSqRoNoXA=";

  meta = bbb-shared-utils.meta // {
    description = "BigBlueButton GraphQL Middleware";
  };
}
