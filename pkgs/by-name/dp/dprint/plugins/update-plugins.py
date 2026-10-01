#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p nix nix-prefetch-github 'python3.withPackages (ps: [ ps.requests ])'

import json
import os
from pathlib import Path
import sys
import subprocess
import requests
import re

USAGE = """Usage: {0} [ | plugin-name ]

eg.
  {0}
  {0} dprint-plugin-json"""

FILE_PATH = Path(os.path.realpath(__file__))
SCRIPT_DIR = FILE_PATH.parent
PLUGINS_JSON = SCRIPT_DIR / "plugins.json"

pname = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("UPDATE_NIX_PNAME", "")

if "-help" in sys.argv:
    print(USAGE.format(FILE_PATH.name))
    exit(0)


def get_update_url(plugin_url):
    url = "-".join(plugin_url.split("-")[:-1])
    names = url.split("/")[3:]
    if len(names) == 1:
        names.insert(0, "dprint")
    return "https://plugins.dprint.dev/" + "/".join(names) + "/latest.json"


def get_hashes(owner, repo, version):
    rev = version
    print(f"Prefetching {owner}/{repo} at {rev}")
    try:
        res = subprocess.check_output(
            f"nix-prefetch-github {owner} {repo} --rev {rev}",
            shell=True,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        rev = "v" + version
        try:
            res = subprocess.check_output(
                f"nix-prefetch-github {owner} {repo} --rev {rev}",
                shell=True,
                stderr=subprocess.DEVNULL,
            )
        except subprocess.CalledProcessError:
            print(f"Failed to fetch {owner}/{repo} at {rev} and v{version}")
            return None, None

    src_data = json.loads(res.decode("utf-8"))
    return src_data["rev"], src_data["hash"]


def get_cargo_hash(pname, plugins):
    print(f"Building {pname} to get cargoHash...")
    # First set fakeHash
    plugins[pname]["cargoHash"] = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    with open(PLUGINS_JSON, "w") as f:
        json.dump(plugins, f, indent=2, sort_keys=True)
        f.write("\n")

    try:
        subprocess.check_output(
            f"nix-build -A dprint-plugins.{pname} --no-out-link",
            shell=True,
            stderr=subprocess.STDOUT,
        )
        print(f"Wait, {pname} succeeded with fake hash?")
        return "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    except subprocess.CalledProcessError as e:
        output = e.output.decode("utf-8")
        m = re.search(r"got:\s+(sha256-[a-zA-Z0-9+/=]+)", output)
        if m:
            print(f"Found cargoHash for {pname}: {m.group(1)}")
            return m.group(1)
        else:
            print(
                f"Build failed for {pname} and no cargoHash found in output:\n{output}"
            )
            return None


def update_plugin(plugins, pname, e):
    if "repoUrl" not in e:
        print(f"Skipping {pname} (no repoUrl, cannot build from source)")
        return

    p = plugins.get(pname, {})
    if p.get("version") == e["version"] and "cargoHash" in p:
        print(f"Skipping {pname} (already at {e['version']})")
        return

    repo_url = e["repoUrl"]
    parts = repo_url.split("/")
    owner = parts[-2]
    repo = parts[-1]

    rev, src_hash = get_hashes(owner, repo, e["version"])
    if not rev:
        return

    if pname not in plugins:
        plugins[pname] = {}

    p = plugins[pname]
    p["owner"] = owner
    p["repo"] = repo
    p["rev"] = rev
    p["hash"] = src_hash
    p["version"] = e["version"]
    p["updateUrl"] = get_update_url(e["url"])
    p["description"] = e["description"].rstrip(".")
    p["initConfig"] = {
        "configKey": e.get("configKey", ""),
        "configExcludes": e.get("configExcludes", []),
        "fileExtensions": e.get("fileExtensions", []),
    }

    # Strip the binary url if it exists since we do source builds now
    p.pop("url", None)

    c_hash = get_cargo_hash(pname, plugins)
    if c_hash:
        p["cargoHash"] = c_hash
    else:
        print(f"WARNING: Could not fetch cargoHash for {pname}. Source build broken.")


def update_plugin_by_name(name):
    if name.endswith(".nix"):
        name = Path(name[:-4]).name

    with open(PLUGINS_JSON, "r") as f:
        plugins = json.load(f)

    if name not in plugins:
        print(f"plugin {name} not found in plugins.json")
        exit(1)

    p = plugins[name]
    data = requests.get(p["updateUrl"]).json()
    e = requests.get("https://plugins.dprint.dev/info.json").json()["latest"]
    e = next((x for x in e if x["name"].replace("/", "-") == name), None)
    if e is None:
        print(f"plugin {name} not found in dprint info.json")
        exit(1)

    update_plugin(plugins, name, e)

    with open(PLUGINS_JSON, "w") as f:
        json.dump(plugins, f, indent=2, sort_keys=True)
        f.write("\n")


def update_plugins():
    with open(PLUGINS_JSON, "r") as f:
        plugins = json.load(f)

    data = requests.get("https://plugins.dprint.dev/info.json").json()["latest"]

    for e in data:
        pname = e["name"].replace("/", "-")
        if pname in plugins:
            update_plugin(plugins, pname, e)

    with open(PLUGINS_JSON, "w") as f:
        json.dump(plugins, f, indent=2, sort_keys=True)
        f.write("\n")


if pname != "":
    update_plugin_by_name(pname)
else:
    update_plugins()
