{
  lib,
  bbb-shared-utils,
  buildNpmPackage,
}:

buildNpmPackage {
  pname = "bbb-webhooks";
  version = bbb-shared-utils.versionComponent;
  src = "${bbb-shared-utils.src}/bbb-webhooks";

  npmDepsHash = "sha256-ZQB4mw9I/TFfcYtsp7Dlh6lJ0ShaBpCLaWYUvz2m5Zw=";

  dontNpmBuild = true;

  meta = bbb-shared-utils.meta // {
    description = "A BigBlueButton mudule for events WebHooks";
  };
}
