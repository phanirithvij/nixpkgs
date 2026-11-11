{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  gtest,
  nlohmann_json,
  python3Packages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pybind11_json";
  version = "0.2.15";

  src = fetchFromGitHub {
    owner = "pybind";
    repo = "pybind11_json";
    tag = finalAttrs.version;
    hash = "sha256-e9mBvSg8mIuYO1x2yJhejY3iP0TPIiQXwzxy5asf9tk=";
  };

  nativeBuildInputs = [ cmake ];

  propagatedBuildInputs = [
    nlohmann_json
    python3Packages.pybind11
  ];

  nativeCheckInputs = [
    gtest
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_TESTS" finalAttrs.doCheck)
  ];

  doCheck = true;

  checkTarget = "tests";

  meta = {
    description = "Using nlohmann::json with pybind11";
    homepage = "https://github.com/pybind/pybind11_json";
    changelog = "https://github.com/pybind/pybind11_json/releases/tag/${finalAttrs.version}";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ phanirithvij ];
    platforms = lib.platforms.all;
  };
})
