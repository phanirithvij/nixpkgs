{
  lib,
  buildPythonPackage,
  fetchPypi,
  flake8,
  orderedmultidict,
  python,
  pytestCheckHook,
  six,
}:

buildPythonPackage rec {
  pname = "furl";
  version = "2.1.3";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    sha256 = "5a6188fe2666c484a12159c18be97a1977a71d632ef5bb867ef15f54af39cc4e";
  };

  # With python 3.11.4, invalid IPv6 address does throw ValueError
  # https://github.com/gruns/furl/issues/164#issuecomment-1595637359
  postPatch = ''
    substituteInPlace tests/test_furl.py \
      --replace-fail '[0:0:0:0:0:0:0:1:1:1:1:1:1:1:1:9999999999999]' '[2001:db8::9999]'
  '';

  propagatedBuildInputs = [
    orderedmultidict
    six
  ];

  nativeCheckInputs = [
    flake8
    pytestCheckHook
  ];

  disabledTests =
    # test failure "test_odd_urls"
    # https://github.com/gruns/furl/issues/176
    let
      pythonVersionFull = with python.sourceVersion; "${major}.${minor}.${patch}";
      pythonAtLeast' =
        v: (python.pythonVersion == lib.versions.majorMinor v) && (lib.versionAtLeast pythonVersionFull v);
      cond = (
        lib.lists.any lib.trivial.id (
          lib.map pythonAtLeast' [
            "3.13.0"
            "3.12.4"
            "3.11.10"
            "3.10.15"
            "3.9.20"
            "3.8.20"
          ]
        )
      );
    in
    lib.optionals cond [
      # AssertionError: assert '//////path' == '////path'
      "test_odd_urls"
    ];

  pythonImportsCheck = [ "furl" ];

  meta = with lib; {
    description = "Python library that makes parsing and manipulating URLs easy";
    homepage = "https://github.com/gruns/furl";
    license = licenses.unlicense;
    maintainers = with maintainers; [ vanzef ];
  };
}
