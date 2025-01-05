#!/usr/bin/env nix-shell
#!nix-shell -i python -p git nix nixfmt-rfc-style 'python3.withPackages (pp: [ pp.requests ])'

from copy import deepcopy
import json
import os
from pathlib import Path
import subprocess
import sys
import requests

USAGE = """Usage: {0} [ | plugin-name | plugin-file-path]

eg.
  {0}   - to only update official dprint plugins from plugins.dprint.dev
  {0} dprint-plugin-json - to update a single plugin by name
  {0} /path/to/dprint-plugin-json.nix - to update a single plugin by filepath
"""

FILE_PATH = Path(os.path.realpath(__file__))
SCRIPT_DIR = FILE_PATH.parent

pname = ""
if len(sys.argv) > 1:
    if "-help" in "".join(sys.argv):
        print(USAGE.format(FILE_PATH.name))
        exit(0)
    pname = sys.argv[1]
else:
    pname = os.environ.get("UPDATE_NIX_PNAME", "")


# get sri hash for a url, no unpack
def nix_prefetch_url(url, name, algo="sha256"):
    hash = (
        subprocess.check_output(
            ["nix-prefetch-url", "--type", algo, "--name", name, url]
        )
        .decode("utf-8")
        .rstrip()
    )
    sri = (
        subprocess.check_output(
            # split by space is enough for this command
            "nix --extra-experimental-features nix-command "
            f"hash convert --hash-algo {algo} --to sri {hash}".split(" ")
        )
        .decode("utf-8")
        .rstrip()
    )
    return sri


# json object to nix string
def json_to_nix(jsondata):
    # to quote strings, dumps twice does it
    json_str = json.dumps(json.dumps(jsondata))
    return (
        subprocess.check_output(
            "nix --extra-experimental-features nix-command eval "
            f"--expr 'builtins.fromJSON ''{json_str}''' --impure | nixfmt",
            shell=True,
        )
        .decode("utf-8")
        .rstrip()
    )


# nix string to json object
def nix_to_json(nixstr):
    return json.loads(
        subprocess.check_output(
            f"nix --extra-experimental-features nix-command eval --json --impure --expr '{nixstr}'",
            shell=True,
        )
        .decode("utf-8")
        .rstrip()
    )


NIXPKGS = (
    subprocess.check_output(["git", "rev-parse", "--show-toplevel"])
    .decode("utf-8")
    .rstrip()
)


def get_plugin_drv_attrs(filepath: Path) -> str:
    script = f"""
    let
      pkgs = import {NIXPKGS} {{ }};
    in
    builtins.removeAttrs (
        pkgs.callPackage ./{filepath.name} {{
            mkDprintPlugin = f: f;
        }})
        [ "override" "overrideDerivation" ]
    """
    return nix_to_json(script)


# nixfmt a file
def nixfmt(nixfile):
    subprocess.run(["nixfmt", nixfile])


def get_update_url(plugin_url):
    """Get a single plugin's update url given the plugin's url"""

    # remove -version.wasm at the end
    url = "-".join(plugin_url.split("-")[:-1])
    names = url.split("/")[3:]
    # if single name then -> dprint/<name>
    if len(names) == 1:
        names.insert(0, "dprint")
    return "https://plugins.dprint.dev/" + "/".join(names) + "/latest.json"


def write_plugin_derivation(drv_attrs, filepath=None):
    # TODO if file not exists write
    # if file exists overwrite only the relavent lines and sections
    # i.e. version, hash
    # and first { } attrset only for official plugins
    # NOTE tried nix-update but only version changes not the hash
    attrs = deepcopy(drv_attrs)
    for k in ("version", "hash", "homepage", "url"):
        attrs.pop(k, None)
    url = drv_attrs["url"].replace(drv_attrs["version"], "${version}")
    drv = f"""
    {{ mkDprintPlugin, ... }}:
    let
      version = "{drv_attrs["version"]}";
      hash = "{drv_attrs["hash"]}";
      homepage = "{drv_attrs["homepage"]}";
    in
    mkDprintPlugin ({json_to_nix(attrs)} // {{
        inherit version hash homepage;
        url = "{url}";
        changelog = "${{homepage}}/releases/${{version}}";
    }})
    """
    if filepath is None:
        filepath = SCRIPT_DIR / f"{drv_attrs["pname"]}.nix"
    with open(filepath, "w+", encoding="utf8") as f:
        f.write(drv)
    nixfmt(filepath)


def update_plugin_by_filepath(filepath):
    """Update a single unofficial plugin by filepath"""
    pass


def update_plugin_by_name(name):
    """Update a single official plugin by name or filepath"""

    # allow passing in filepath as well as pname
    filepath = None
    if name.endswith(".nix"):
        filepath = Path(name)
        name = Path(name[:-4]).name
    if filepath is None:
        filepath = SCRIPT_DIR / f"{name}.nix"

    try:
        p = filepath.read_text().replace("\n", "")
    except OSError as e:
        print(f"failed to update plugin {name}: error: {e}")
        exit(1)

    # To update all the fields
    data = requests.get("https://plugins.dprint.dev/info.json").json()["latest"]
    plugin_info = None
    for e in data:
        pname = e["name"]
        if "/" in pname:
            pname = pname.replace("/", "-")
        if name == pname:
            plugin_info = e
            break

    start_idx = p.find("mkDprintPlugin {") + len("mkDprintPlugin {")
    p = "{" + p[start_idx:].strip()

    try:
        p = nix_to_json(p)
    except Exception as e:
        update_plugin_by_filepath(filepath, p)

    data = requests.get(p["updateUrl"]).json()
    p["url"] = data["url"]
    # ignore verison attribute, get it from url
    p["version"] = p["url"].split("-")[-1][:-5]
    p["hash"] = nix_prefetch_url(data["url"], f"{name}-{p["version"]}.wasm")
    if plugin_info is not None:
        p.update(
            {
                "description": plugin_info["description"],
                "initConfig": {
                    "configKey": plugin_info["configKey"],
                    "configExcludes": plugin_info["configExcludes"],
                    "fileExtensions": plugin_info["fileExtensions"],
                },
            }
        )

    write_plugin_derivation(p, filepath)


def update_plugins():
    """Update all the official plugins"""

    data = requests.get("https://plugins.dprint.dev/info.json").json()["latest"]

    for e in data:
        update_url = get_update_url(e["url"])
        pname = e["name"]
        homepage = f"https://github.com/dprint/{pname}"
        if "/" in pname:
            homepage = f"https://github.com/{pname}"
            pname = pname.replace("/", "-")

        # ignore version provided by json, extract it from release url
        version = e["url"].split("-")[-1][:-5]
        drv_attrs = {
            "url": e["url"],
            "hash": nix_prefetch_url(e["url"], f"{pname}-{version}.wasm"),
            "updateUrl": update_url,
            "pname": pname,
            "version": version,
            "description": e["description"],
            "homepage": homepage,
            "initConfig": {
                "configKey": e["configKey"],
                "configExcludes": e["configExcludes"],
                "fileExtensions": e["fileExtensions"],
            },
        }
        write_plugin_derivation(drv_attrs)


if pname != "":
    update_plugin_by_name(pname)
else:
    update_plugins()
