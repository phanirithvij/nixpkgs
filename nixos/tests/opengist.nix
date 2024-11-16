{ pkgs, lib, ... }:
let
  port = 6157;
  sshPort = 2222;
  sshKey = "/root/.ssh/id_ed25519";
  initSshKey = pkgs.writeShellApplication {
    name = "init-ssh-key";
    text = ''
      ssh-keygen -t ed25519 -C "test@example.com" -N "" -f ${sshKey} -q
    '';
  };
  addSshKey =
    pkgs.writers.writePython3Bin "add-ssh-key"
      {
        libraries = with pkgs.python3Packages; [ requests ];
      }
      ''
        import requests
        url = "http://localhost:${toString port}"
        s = requests.Session()

        s.get(f"{url}/login")
        data = {
          "username": "admin",
          "password": "admin",
          "_csrf": s.cookies.get("_csrf", ""),
        }
        s.post(f"{url}/login", data=data)

        # register ssh key
        data = {
            "title": "sshkey",
            "content": open("${sshKey}.pub").read(),
            "_csrf": s.cookies.get("_csrf", ""),
        }
        r = s.post(f"{url}/settings/ssh-keys", data=data)
        assert r.status_code == 200
      '';
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

        # register/login account (to get session)
        s.get(f"{url}/register")
        data = {
          "username": "admin",
          "password": "admin",
          "_csrf": s.cookies.get("_csrf", ""),
        }
        # no problem if fails, idempotent
        s.post(f"{url}/register", data=data)
        s.post(f"{url}/login", data=data)

        # create post
        data = {
          "name": "test.sh",
          "content": "echo%20-en%20hello",
          "_csrf": s.cookies.get("_csrf", ""),
        }
        r = s.post(url, data=data, allow_redirects=True)
        url_post = r.url.rstrip("/")

        if sys.argv[1] == "git":
            url_post += ".git"
        elif sys.argv[1] == "ssh":
            url_post = "/".join(["ssh://localhost:${toString sshPort}", *url_post.split("/")[3:]])
            url_post += ".git"
        elif sys.argv[1] == "raw":
            url_post += "/raw/HEAD/test.sh"
        elif sys.argv[1] == "zip":
            url_post += "/archive/HEAD"
        print(url_post, end="")
      '';
  makeOpengistNode =
    extraConfig:
    lib.mkMerge [
      {
        # TODO find the lowest memory possible without getting oomd
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
      if name in [ "minimal_no_ssh" ]:
        # tests raw and archive dls
        url_post = machine.succeed("post-url-opengist raw")
        machine.succeed(f"sh -c 'mkdir testdir; curl --fail {url_post} -o testdir/test.sh'")
        url_post = machine.succeed("post-url-opengist zip")
        machine.succeed(f"sh -c 'mkdir testdir2; curl --fail {url_post} -o - | bsdtar -xvf- -C testdir2'")
        url_post = machine.succeed("post-url-opengist git")
        # tests git clone fails
        machine.fail(f"git clone {url_post}")
      else:
        # tests git http clone
        url_post = machine.succeed("post-url-opengist git")
        machine.succeed(f"git clone {url_post} testdir")
        # tests ssh clone
        machine.succeed("sh -c 'init-ssh-key && add-ssh-key'")
        url_post = machine.succeed("post-url-opengist ssh")
        SSH_COMMAND="ssh -i ${sshKey} -p ${toString sshPort} -o StrictHostKeyChecking=no"
        machine.succeed(f"""GIT_SSH_COMMAND="{SSH_COMMAND}" git clone {url_post} testdir2""")
      assert machine.succeed("sh -c 'cd testdir; chmod +x test.sh; ./test.sh'") == "hello"
      assert machine.succeed("sh -c 'cd testdir2; chmod +x test.sh; ./test.sh'") == "hello"
    '';

  baseDBCfg = {
    username = "opengist";
    name = "opengist";
    host = "localhost";
  };
in
{
  name = "opengist";
  meta = {
    maintainers = [ lib.maintainers.phanirithvij ];
  };
  nodes = {
    default_sqlite = makeOpengistNode {
      # tests sqlite
      services.opengist.enable = true;
      environment.systemPackages = [
        initSshKey
        addSshKey
      ];
    };

    minimal_no_ssh = makeOpengistNode {
      environment.systemPackages = [
        pkgs.libarchive # bsdtar
      ];
      services.opengist = {
        enable = true;
        settings = {
          "index.enabled" = false;
          "http.git-enabled" = false;
          "ssh.git-enabled" = false;
        };
        # tests postgres
        database = baseDBCfg // {
          # tests password
          password = "notsosecretpass";
          port = 5432;
          type = "postgresql";
          createLocally = true;
        };
      };
    };

    manual = makeOpengistNode {
      services.opengist = {
        enable = true;
        # tests that it works outside /var/lib/opengist
        opengist-home = "/opengist";
        # tests that settingsFile works
        settingsFile =
          pkgs.writeText "opengist-config.yaml" # yaml
            ''
              http.host: 0.0.0.0
              http.port: ${toString port}
              opengist-home: "/opengist"
            '';
        # tests mysql
        database = baseDBCfg // {
          # tests password file
          passwordFile = "/root/postgres_opengist_pass";
          port = 3306;
          type = "mysql";
          createLocally = true;
        };
        # tests secretsFile
        secretsFile = "/root/opengist_secret_key";
      };
      # TODO these two tests
      #services.mysql.package = pkgs.mysql80;
      #services.mysql.package = pkgs.percona-server_8_4;
      systemd.tmpfiles.settings.opengist = {
        "/opengist".d = {
          user = "opengist";
          mode = "0750";
        };
        # dumb way to have the secrets exist before service startup
        # use sops or agenix in real systems
        "/root/postgres_opengist_pass"."L+" = {
          user = "opengist";
          mode = "0400";
          argument = toString (pkgs.writeText "opengist_pgpass" "Super:Secret:Password");
        };
        "/root/opengist_secret_key"."L+" = {
          user = "opengist";
          mode = "0400";
          argument = toString (pkgs.writeText "opengist_secret_key" "ogist_secret_never_gonna_give_u");
        };
        # TODO nginx?
        # TODO test custom dir write access in manual instead of minimal_no_ssh
      };
      environment.systemPackages = [
        initSshKey
        addSshKey
      ];
    };
  };

  # TODO createLocally = false, percona caddy?
  # TODO settings settingsFile assert test

  testScript =
    # python
    ''
      start_all()

      ${nodeTestScript "default_sqlite"}

      ${nodeTestScript "manual"}
      # tests write access to dir
      manual.succeed("touch /opengist/custom/logoempty.png")
      manual.succeed("curl --fail -OJ http://localhost:${toString port}/assets/logoempty.png")
      assert manual.succeed("sh -c '[ -s logoempty.png ] || echo -en empty'") == "empty"

      ${nodeTestScript "minimal_no_ssh"}
      # tests we can NOT write to custom dir
      print(minimal_no_ssh.succeed("ls -ld /var/lib/opengist"))
      print(minimal_no_ssh.succeed("ls -l /var/lib/opengist"))
      print(minimal_no_ssh.succeed("ls -l /var/lib/opengist/custom"))
      print(minimal_no_ssh.succeed("ls -dl /var/lib/opengist/custom"))
      minimal_no_ssh.fail("touch /var/lib/opengist/custom/file.png")
    '';
}
