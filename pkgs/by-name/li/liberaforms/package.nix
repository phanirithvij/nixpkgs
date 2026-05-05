{
  lib,
  python3,
  fetchFromGitea,
  fetchFromGitHub,
  fetchPypi,
  makeWrapper,

  moreutils,
  dart-sass,
  postgresql,
  libxml2,
  libxslt,

  # tests
  postgresqlTestHook,
  nixosTests,
}:

let
  python = python3.override {
    packageOverrides = self: super: {
      # required 1.8.1 (tests fail otherwise)
      alembic = super.alembic.overridePythonAttrs rec {
        pname = "alembic";
        version = "1.8.1";
        src = fetchPypi {
          inherit pname version;
          sha256 = "sha256-zQteRbFLcGQmuDPwY2m5ptXuA/gm7DI4cjzoyq9uX/o=";
        };
        doCheck = false;
      };
      # required 3.1.0 (requirements and 3.1.0 works with alembic 1.8.1)
      flask-migrate = super.flask-migrate.overridePythonAttrs rec {
        version = "3.1.0";
        src = fetchFromGitHub {
          owner = "miguelgrinberg";
          repo = "Flask-Migrate";
          tag = "v${version}";
          hash = "sha256-2P9UfR/1Vv9FSmpSZn0gV4/uuSNdl6sdgRnSbefFR34=";
        };
        dependencies = [
          self.alembic
          super.flask
          self.flask-sqlalchemy
        ];
        nativeCheckInputs = [ ];
      };
      # required downgrade to 3.0.2 (from requirements.txt as well as sqlalchemy downgrade)
      flask-sqlalchemy = super.flask-sqlalchemy.overridePythonAttrs rec {
        version = "3.0.2";
        src = fetchPypi {
          pname = "Flask-SQLAlchemy";
          inherit version;
          hash = "sha256-FhmfWz3ftp4N8vUq5Mdq7b/sgjRiNJ2rshobLgorZek=";
        };
        dependencies = [
          super.flask
          self.sqlalchemy
          super.pdm-pep517
        ];
      };
      # required 1.4.42 (from requirements)
      sqlalchemy = super.sqlalchemy_1_4.overridePythonAttrs rec {
        version = "1.4.42";
        src = fetchFromGitHub {
          owner = "sqlalchemy";
          repo = "sqlalchemy";
          rev = "rel_${lib.replaceStrings [ "." ] [ "_" ] version}";
          hash = "sha256-RVpreszvd5hn9BLzvnfKT4nibUuybtZwBRloe5NaP/E=";
        };
        doCheck = false;
      };
    };
  };
  python3Packages = python.pkgs;
in

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "liberaforms";
  version = "4.8.1";
  pyproject = false;

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "LiberaForms";
    repo = "server";
    tag = "v${finalAttrs.version}";
    hash = "sha256-rXQxDSMh15CicePCA+nOERE+EBE4SQR0gsUacu1jV98=";
  };

  postPatch = ''
        echo "Compiling sass files"
        pushd liberaforms/static
        chronic sass sass:css --style=compressed --no-source-map
        popd

        # Robust patching using Python. We use double quotes for Python strings and escape them.
        ${python3.interpreter} -c "
    import re
    path = 'liberaforms/config/config.py'
    with open(path, 'r') as f:
        content = f.read()

    # Replace os.environ['VAR'] with os.environ.get('VAR', default)
    def replace_env(var, default_val):
        global content
        content = content.replace(f\"os.environ['{var}']\", f\"os.environ.get('{var}', {default_val})\")

    replace_env('DB_USER', '\"liberaforms\"')
    replace_env('DB_PASSWORD', '\"\"')
    replace_env('DB_HOST', '\"localhost\"')
    replace_env('DB_NAME', '\"liberaforms\"')
    replace_env('FLASK_CONFIG', '\"production\"')
    replace_env('BASE_URL', '\"http://localhost\"')
    replace_env('ROOT_USER', '\"admin@example.org\"')
    replace_env('SECRET_KEY', '\"not-so-secret\"')
    replace_env('TMP_DIR', '\"/tmp\"')
    replace_env('SESSION_TYPE', '\"filesystem\"')
    replace_env('TOKEN_EXPIRATION', '\"3600\"')
    replace_env('DEFAULT_TIMEZONE', '\"UTC\"')
    replace_env('TOTAL_UPLOADS_LIMIT', '\"10G\"')
    replace_env('DEFAULT_USER_UPLOADS_LIMIT', '\"100M\"')
    replace_env('ENABLE_REMOTE_STORAGE', '\"False\"')
    replace_env('ENABLE_PROMETHEUS_METRICS', '\"False\"')
    replace_env('ENABLE_RSS_FEED', '\"True\"')
    replace_env('ENABLE_LDAP', '\"False\"')

    # Handle int() calls separately
    content = re.sub(r\"int\(os\.environ\['(MAX_MEDIA_SIZE|MAX_ATTACHMENT_SIZE)'\]\)\", 
                     r\"int(os.environ.get('\1', 2000000))\", content)

    # 2. Add ASSETS_CACHE to Config class
    if 'ASSETS_CACHE' not in content:
        content = content.replace('class Config(object):', 
                                  'class Config(object):\\n    ASSETS_CACHE = os.environ.get(\"ASSETS_CACHE\", False)')

    # 3. Special path logic fixes
    content = content.replace(\"UPLOADS_DIR = os.path.join(ROOT_DIR, 'uploads')\", 
                              \"UPLOADS_DIR = os.environ.get('UPLOADS_DIR', os.path.join(ROOT_DIR, 'uploads')); SESSION_FILE_DIR = os.environ.get('SESSION_FILE_DIR', os.path.join(ROOT_DIR, 'flask_session'))\")
    content = content.replace(\"LOG_DIR = os.path.join(ROOT_DIR, os.environ.get('LOG_DIR', 'logs'))\", 
                              \"LOG_DIR = os.environ.get('LOG_DIR', os.path.join(ROOT_DIR, 'logs'))\")

    # 4. Database URI logic fix
    content = content.replace(\"SQLALCHEMY_DATABASE_URI = get_SQLALCHEMY_DATABASE_URI()\", 
                              \"SQLALCHEMY_DATABASE_URI = os.environ.get('SQLALCHEMY_DATABASE_URI') or get_SQLALCHEMY_DATABASE_URI()\")

    with open(path, 'w') as f:
        f.write(content)

    # 5. Patch models/site.py
    site_path = 'liberaforms/models/site.py'
    with open(site_path, 'r') as f:
        site_content = f.read()
    site_content = site_content.replace(\"os.environ['DEFAULT_LANGUAGE']\", \"os.environ.get('DEFAULT_LANGUAGE', 'en')\")
    with open(site_path, 'w') as f:
        f.write(site_content)
    "
  '';

  nativeBuildInputs = [
    dart-sass
    moreutils # chronic
    postgresql
    libxml2
    libxslt
    makeWrapper
  ];

  propagatedBuildInputs = with python3Packages; [
    aiohappyeyeballs
    aiohttp
    aiosignal
    aiosmtpd
    alembic
    atpublic
    attrs
    babel
    beautifulsoup4
    bleach
    blinker
    cairocffi
    cairosvg
    cachelib
    certifi
    cffi
    charset-normalizer
    click
    cryptography
    cssselect2
    deepdiff
    defusedxml
    dnspython
    email-validator
    feedgen
    flask
    flask-assets
    flask-babel
    flask-login
    flask-marshmallow
    flask-migrate
    flask-session2
    flask-sqlalchemy
    flask-wtf
    frozenlist
    greenlet
    gunicorn
    idna
    importlib-metadata
    importlib-resources
    iniconfig
    itsdangerous
    jinja2
    jsonpickle
    ldap3
    lxml
    mako
    markdown
    markupsafe
    marshmallow
    marshmallow-sqlalchemy
    minio
    msgspec
    multidict
    orderly-set
    packaging
    passlib
    python3Packages."password-entropy"
    pillow
    platformdirs
    pluggy
    portpicker
    prometheus-client
    propcache
    psutil
    psycopg2
    py
    pyasn1
    pycodestyle
    pycparser
    pygments
    pyjwt
    pyparsing
    pypng
    pyqrcode
    python-dateutil
    python-dotenv
    python-magic
    pytz
    pyyaml
    requests
    six
    snowballstemmer
    soupsieve
    sqlalchemy
    sqlalchemy-json
    tinycss2
    toml
    tomlkit
    unicodecsv
    unidecode
    urllib3
    webassets
    webencodings
    werkzeug
    wtforms
    yarl
    zipp
    zope-dottedname
    zxcvbn
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/liberaforms
    cp -R . $out/lib/liberaforms

    # Create wrappers using pythonEnv to ensure all dependencies are present
    local pythonEnv="${python.withPackages (ps: finalAttrs.propagatedBuildInputs)}"

    # Important: Flask needs to be run from the app root to find the migrations directory and assets
    # We set default paths for all mandatory variables to avoid errors when run via su
    makeWrapper $pythonEnv/bin/gunicorn $out/bin/liberaforms-gunicorn \
      --prefix PYTHONPATH : "$out/lib/liberaforms" \
      --add-flags "--chdir $out/lib/liberaforms" \
      --set-default ASSETS_DIR "$out/lib/liberaforms/assets" \
      --set-default LOG_DIR "/tmp/liberaforms-logs" \
      --set-default UPLOADS_DIR "/tmp/liberaforms-uploads" \
      --set-default SESSION_FILE_DIR "/tmp/liberaforms-sessions" \
      --set-default SESSION_TYPE "filesystem" \
      --set-default FLASK_CONFIG "production" \
      --set-default DEFAULT_LANGUAGE "en" \
      --set-default DEFAULT_TIMEZONE "UTC" \
      --set-default TMP_DIR "/tmp" \
      --set-default MAX_MEDIA_SIZE "2000000" \
      --set-default MAX_ATTACHMENT_SIZE "2000000" \
      --set-default SECRET_KEY "not-so-secret" \
      --set-default ROOT_USER "admin@example.org" \
      --set-default BASE_URL "http://localhost" \
      --set-default FQDN "localhost" \
      --set-default DB_USER "liberaforms" \
      --set-default DB_NAME "liberaforms" \
      --set-default DB_HOST "/run/postgresql" \
      --set-default DB_PORT "5432" \
      --set-default SQLALCHEMY_DATABASE_URI "postgresql+psycopg2:///liberaforms?host=/run/postgresql" \
      --set-default ASSETS_CACHE "/tmp/webassets-cache"

    makeWrapper $pythonEnv/bin/flask $out/bin/liberaforms-manage \
      --run "cd $out/lib/liberaforms" \
      --set FLASK_APP "wsgi.py" \
      --set-default ASSETS_DIR "$out/lib/liberaforms/assets" \
      --set-default LOG_DIR "/tmp/liberaforms-logs" \
      --set-default UPLOADS_DIR "/tmp/liberaforms-uploads" \
      --set-default SESSION_FILE_DIR "/tmp/liberaforms-sessions" \
      --set-default SESSION_TYPE "filesystem" \
      --set-default FLASK_CONFIG "production" \
      --set-default DEFAULT_LANGUAGE "en" \
      --set-default DEFAULT_TIMEZONE "UTC" \
      --set-default TMP_DIR "/tmp" \
      --set-default MAX_MEDIA_SIZE "2000000" \
      --set-default MAX_ATTACHMENT_SIZE "2000000" \
      --set-default SECRET_KEY "not-so-secret" \
      --set-default ROOT_USER "admin@example.org" \
      --set-default BASE_URL "http://localhost" \
      --set-default FQDN "localhost" \
      --set-default DB_USER "liberaforms" \
      --set-default DB_NAME "liberaforms" \
      --set-default DB_HOST "/run/postgresql" \
      --set-default DB_PORT "5432" \
      --set-default SQLALCHEMY_DATABASE_URI "postgresql+psycopg2:///liberaforms?host=/run/postgresql" \
      --set-default ASSETS_CACHE "/tmp/webassets-cache"

    runHook postInstall
  '';

  doCheck = false;

  # avoid writing in the migration process
  postFixup = ''
    cp $out/lib/liberaforms/assets/brand/logo-default.png $out/lib/liberaforms/assets/brand/logo.png
    cp $out/lib/liberaforms/assets/brand/favicon-default.ico $out/lib/liberaforms/assets/brand/favicon.ico
    sed -i "/shutil.copyfile/d" $out/lib/liberaforms/liberaforms/models/site.py
    sed -i "/brand_dir/d" $out/lib/liberaforms/migrations/versions/6f0e2b9e9db3_.py
  '';

  passthru = {
    # PYTHONPATH of all dependencies used by the package
    pythonPath = python3Packages.makePythonPath finalAttrs.propagatedBuildInputs;
    tests = { inherit (nixosTests) liberaforms; };
  };

  meta = {
    description = "Ethical form software";
    homepage = "https://liberaforms.org";
    downloadPage = "https://codeberg.org/LiberaForms/server";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.all;
    teams = with lib.teams; [ ngi ];
  };
})
