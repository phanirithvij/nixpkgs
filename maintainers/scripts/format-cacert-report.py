#!/usr/bin/env python3
import json
import os
import re
import sys
import collections

def main():
    if len(sys.argv) < 4:
        print("Usage: format_report.py <format> <team> <total_pkgs>", file=sys.stderr)
        sys.exit(1)

    fmt = sys.argv[1]
    team = sys.argv[2]
    total_pkgs = int(sys.argv[3])

    raw_input = sys.stdin.read().strip()
    if not raw_input:
        findings = []
    elif raw_input.startswith("["):
        findings = json.loads(raw_input)
    else:
        findings = []
        for line in raw_input.splitlines():
            line = line.strip()
            if line.startswith("{"):
                try:
                    findings.append(json.loads(line))
                except json.JSONDecodeError:
                    pass

    pkgs = collections.defaultdict(lambda: {
        "files": [],
        "ecc": False,
        "aaa": False,
        "roots": 0,
        "class": "compiled-in"
    })

    def pname(nar):
        base = os.path.basename(nar)
        clean = re.sub(r"^[a-z0-9]{32}-", "", base)
        clean = re.sub(r"-[0-9].*$", "", clean)
        return clean

    for f in findings:
        nar = f["nar"]
        name = pname(nar)
        p = pkgs[name]
        rel_path = f["file"][len(nar):]
        p["files"].append(rel_path)
        p["ecc"] |= ("emSign ECC Root CA - G3" in f.get("watch", []))
        p["aaa"] |= ("AAA Certificate Services" in f.get("watch", []))
        p["roots"] = max(p["roots"], len(f.get("known_roots", [])))
        if f.get("magic") == "elf" or ("der" in f.get("formats", []) and "pem" not in f.get("formats", [])):
            p["class"] = "compiled-in"
        else:
            p["class"] = "other"

    if fmt in ("markdown", "both"):
        print(f"# CA Trust Store Audit Report: Team `{team}` Packages\n")
        print(f"**Tracking Issue**: https://github.com/NixOS/nixpkgs/issues/576544")
        print(f"**Scanner**: `nix run github:zimbatm/nix-cacert-scan`")
        print(f"**Scope**: Only packages maintained by `{team}` team in nixpkgs\n")
        print(f"**Summary**: Found **{len(pkgs)}** affected packages out of **{total_pkgs}** scanned team packages.\n")
        print("### Checklist (GitHub Issue Format)\n")
        if not pkgs:
            print("No affected packages found! All scanned packages use system cacert or have no embedded roots.")
        else:
            for name, p in sorted(pkgs.items()):
                files = sorted(set(p["files"]), key=lambda f: (len(f), f))
                first_file = files[0] if files else "binary"
                more = f" (+{len(files) - 1} more)" if len(files) > 1 else ""
                stale = "" if p["ecc"] else " · stale bundle, no ECC G3"
                aaa = " · trusts AAA" if p["aaa"] else ""
                print(f"- [ ] **{name}** — `{first_file}`{more}{stale}{aaa}")
        print()

    if fmt in ("tsv", "both"):
        if fmt == "both":
            print("### Raw Scanner TSV Output\n```tsv")
        print("PACKAGE\tFILE\tROOTS\tFLAGS")
        for f in findings:
            nar = f["nar"]
            bname = re.sub(r"^/nix/store/[a-z0-9]{32}-", "", nar)
            rel_path = f["file"][len(nar):]
            roots = f"{len(f.get('known_roots', []))} roots"
            flags = []
            if "emSign ECC Root CA - G3" in f.get("watch", []):
                flags.append("ECC G3")
            if "AAA Certificate Services" in f.get("watch", []):
                flags.append("AAA")
            print(f"{bname}\t{rel_path}\t{roots}\t{','.join(flags)}")
        if fmt == "both":
            print("```")

    if fmt == "json":
        print(json.dumps(findings, indent=2))

if __name__ == "__main__":
    main()
