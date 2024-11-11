import ./make-test-python.nix (
  { pkgs, lib, ... }:
  let
    port = 6157;
    postUrlScript =
      pkgs.writers.writePython3Bin "post-url-opengist"
        {
          libraries = with pkgs.python3Packages; [ requests ];
        }
        ''
          import requests
          import sys
          url = "http://localhost:${toString port}"
          s = requests.Session()

          # register account
          s.get(f"{url}/register")
          data = {
            "username": "admin",
            "password": "admin",
            "_csrf": s.cookies.get("_csrf", ""),
          }
          s.post(f"{url}/register", data=data)

          # create post
          data = {
            "title": "",
            "description": "",
            "url": "",
            "name": "test.sh",
            "content": "echo%20-en%20hello",
            "private": "0",
            "_csrf": s.cookies.get("_csrf", ""),
          }
          r = s.post(url, data=data, allow_redirects=True)
          url_post = r.url.rstrip("/")

          if sys.argv[1] == "git":
              url_post += ".git"
          elif sys.argv[2] == "raw":
              url_post += "raw/HEAD/test.sh"

          print(url_post, end="")
        '';
    makeOpengistNode =
      extraConfig:
      lib.mkMerge [
        {
          virtualisation.memorySize = lib.mkDefault 512;
          environment.systemPackages = [
            pkgs.gitMinimal
            postUrlScript
          ];
        }
        extraConfig
      ];
    nodeTestScript =
      machine: # python
      ''
        machine = ${machine}
        name = "${machine}"
        machine.wait_for_unit("multi-user.target")
        machine.wait_for_unit("opengist.service")
        machine.wait_for_open_port(${toString port})
        if name in [ "minimal" ]:
          url_post = machine.succeed("post-url-opengist raw")
          machine.succeed(f"sh -c 'mkdir testdir; curl --fail {url_post} -o testdir/test.sh'")
        else:
          url_post = machine.succeed("post-url-opengist git")
          machine.succeed(f"git clone {url_post} testdir")
        assert machine.succeed("sh -c 'cd testdir; chmod +x test.sh; ./test.sh'") == "hello"
      '';
  in
  {
    name = "opengist";
    meta = {
      maintainers = [ lib.maintainers.phanirithvij ];
    };
    nodes = {
      minimal_no_ssh = makeOpengistNode {
        services.opengist = {
          # sqlite
          enable = true;
          # TODO git,ssh features disabled
          # raw dl and exec
        };
      };
      default_sqlite = makeOpengistNode {
        services.opengist = {
          # sqlite
          enable = true;
          # TODO
          # ssh, git push/pull
        };
      };
      caddy_postgres = makeOpengistNode {
        services.opengist = {
          enable = true;
          reverseProxy.webserver.caddy = { };
          reverseProxy.host = "opengist.local";
          # TODO postgres
        };
      };
      nginx_mariadb = makeOpengistNode {
        services.opengist = {
          enable = true;
          reverseProxy.webserver.nginx = { };
          reverseProxy.host = "opengist.local";
          # TODO mariadb
        };
      };
      # httpd?
      httpd_percona_manual = makeOpengistNode {
        services.opengist = {
          enable = true;
          # custom dir write access
          customDirGroup = "users";
          # outside /var/lib/opengist
          opengist-home = "/opengist";
          # test settingsFile works
          settingsFile =
            pkgs.writeText "opengist-config.yaml" # yaml
              ''
                http.host: 0.0.0.0
                http.port: ${toString port}
                opengist-home: "/opengist"
              '';
          # TODO custom icon in custom dir
          # TODO percona
          # TODO http rev proxy
        };
        systemd.tmpfiles.settings.opengist."/opengist".d = {
          user = "opengist";
          mode = "0750";
        };
      };
    };
    testScript =
      # python
      ''
        start_all()

        ${nodeTestScript "httpd_percona_manual"}
        print(httpd_percona_manual.succeed("touch /opengist/custom/logoempty.png"))
        print(httpd_percona_manual.succeed("curl --fail -OJ http://localhost:${toString port}/assets/logoempty.png"))
        print(httpd_percona_manual.succeed("ls -l logoempty.png"))

        ${nodeTestScript "minimal_no_ssh"}
        ${nodeTestScript "default_sqlite"}
        ${nodeTestScript "caddy_postgres"}
        ${nodeTestScript "nginx_mariadb"}
      '';
  }
)
