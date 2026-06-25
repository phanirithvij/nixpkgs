{
  lib,
  bbb-shared-utils,
  buildNpmPackage,
}:

buildNpmPackage {
  pname = "bbb-pads";
  version = bbb-shared-utils.versionComponent;
  src = "${bbb-shared-utils.src}/bbb-pads";

  npmDepsHash = "sha256-kZJLLH7RSSWcUrmMR5KWLSG9dVu4wgdyggqMUz4y0j4=";

  dontNpmBuild = true;

  meta = bbb-shared-utils.meta // {
    description = "BigBlueButton's pads manager";
  };
}
