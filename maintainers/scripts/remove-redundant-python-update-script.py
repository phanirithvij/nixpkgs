#!/usr/bin/env python3
"""
Scan nixpkgs for redundant usages of `nix-update-script { }` in Python packages
(buildPythonPackage / buildPythonApplication) and remove them.

Since commit 048507355c6e8069c47642fc037da6d34b95acef, buildPythonPackage
and buildPythonApplication default to `nix-update-script { }` in
mk-python-derivation.nix. Explicit declarations with empty arguments are
completely redundant and can be removed without causing derivation rebuilds.

Usage:
  ./maintainers/scripts/remove-redundant-python-update-script.py        # Dry-run scan
  ./maintainers/scripts/remove-redundant-python-update-script.py --run  # Apply changes and commit
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile
from typing import List, Optional

EXCLUDED_PATHS = {
    "pkgs/development/interpreters/python/mk-python-derivation.nix",
}

EMPTY_UPDATE_SCRIPT_PATTERN = re.compile(
    r"(passthru\.)?updateScript\s*=\s*nix-update-script\s*\{\s*\}\s*;",
    re.DOTALL,
)


def remove_comments(code: str) -> str:
    """Strip block and line comments from Nix code."""
    code = re.sub(r"/\*.*?\*/", "", code, flags=re.DOTALL)
    code = re.sub(r"#[^\n]*", "", code)
    return code


def get_root_builder(code: str) -> Optional[str]:
    """Find the top-level builder expression returned by the file."""
    m = re.search(r"^\s*\{.*?\}\s*:\s*", code, re.DOTALL)
    if not m:
        return None
    rest = code[m.end():]

    tokens = re.findall(r"[a-zA-Z0-9_.\-]+|\{|\}|\(|\)|;", rest)

    let_depth = 0
    brace_depth = 0
    paren_depth = 0

    i = 0
    while i < len(tokens):
        t = tokens[i]
        if t == "let" and brace_depth == 0 and paren_depth == 0:
            let_depth += 1
        elif t == "in" and brace_depth == 0 and paren_depth == 0:
            let_depth -= 1
            if let_depth == 0:
                i += 1
                return tokens[i] if i < len(tokens) else None
        elif t == "{":
            brace_depth += 1
        elif t == "}":
            brace_depth -= 1
        elif t == "(":
            paren_depth += 1
        elif t == ")":
            paren_depth -= 1
        elif let_depth == 0 and brace_depth == 0 and paren_depth == 0:
            return t
        i += 1
    return None


def is_candidate(path: str, content: str) -> bool:
    """Check if the nix file is a python package with redundant empty nix-update-script."""
    for excluded in EXCLUDED_PATHS:
        if path.endswith(excluded) or excluded in path:
            return False
    if not EMPTY_UPDATE_SCRIPT_PATTERN.search(content):
        return False

    code = remove_comments(content)
    root_builder = get_root_builder(code)
    if not root_builder:
        return False

    # Disallow non-python builders (e.g. stdenv.mkDerivation, rustPlatform.buildRustPackage)
    if "mkDerivation" in root_builder or "buildRustPackage" in root_builder or "buildGoModule" in root_builder:
        return False

    if not ("buildPython" in root_builder or root_builder in ("with", "nbqa", "effectiveBuildPythonApplication")):
        return False

    return True


def transform_nix_content(content: str) -> str:
    """Transform Nix source code to remove redundant nix-update-script."""
    # 1. Remove comments specifically preceding passthru.updateScript
    content = re.sub(
        r"([ \t]*#[^\n]*\n)*[ \t]*passthru\.updateScript\s*=\s*nix-update-script\s*\{\s*\}\s*;\n?",
        "",
        content,
        flags=re.M,
    )

    # 2. Check passthru = { ... } blocks
    def repl_passthru_block(m: re.Match) -> str:
        inner = m.group("inner")
        no_comm = remove_comments(inner)
        cleaned = re.sub(
            r"updateScript\s*=\s*nix-update-script\s*\{\s*\}\s*;", "", no_comm
        ).strip()
        if not cleaned:
            # Entire passthru was just updateScript (or comments)
            return ""
        new_inner = re.sub(
            r"^[ \t]*updateScript\s*=\s*nix-update-script\s*\{\s*\}\s*;\n?",
            "",
            inner,
            flags=re.M,
        )
        indent = m.group("indent")
        return f"{indent}passthru = {{{new_inner}}};"

    # Match single-line or nested passthru block where braces don't have deeper unclosed scopes
    content = re.sub(
        r"^(?P<indent>[ \t]*)passthru\s*=\s*\{(?P<inner>[^;{}]+;[ \t\n\r]*)\};[ \t]*\n?",
        repl_passthru_block,
        content,
        flags=re.M,
    )

    # In case updateScript was inside a complex multi-attribute passthru block
    content = re.sub(
        r"^[ \t]*updateScript\s*=\s*nix-update-script\s*\{\s*\}\s*;\n?",
        "",
        content,
        flags=re.M,
    )

    # Remove any empty passthru = { }; block that might remain
    content = re.sub(
        r"^[ \t]*passthru\s*=\s*\{\s*\};[ \t]*\n?",
        "",
        content,
        flags=re.M,
    )

    # 3. Clean up trailing blank lines before closing braces in attrsets (e.g. passthru = { ... \n\n };)
    content = re.sub(r"\n[ \t]*\n([ \t]*\};)", r"\n\1", content)

    # 4. Check lambda arguments: if nix-update-script is unused in code, remove it
    arg_match = re.search(r"^(\s*\{)([^:]+)(\}:)", content, re.DOTALL)
    if arg_match:
        header_pre = arg_match.group(1)
        args_body = arg_match.group(2)
        header_post = arg_match.group(3)
        rest_of_file = content[arg_match.end():]

        code_in_rest = remove_comments(rest_of_file)
        if not re.search(r"\bnix-update-script\b", code_in_rest):
            new_args = re.sub(
                r"^[ \t]*nix-update-script,[ \t]*\n?", "", args_body, flags=re.M
            )
            new_args = re.sub(
                r"^[ \t]*,[ \t]*nix-update-script[ \t]*\n?",
                "",
                new_args,
                flags=re.M,
            )
            new_args = re.sub(
                r"^[ \t]*nix-update-script[ \t]*\n?", "", new_args, flags=re.M
            )
            new_args = re.sub(r",\s*nix-update-script\b", "", new_args)
            new_args = re.sub(r"\bnix-update-script\s*,\s*", "", new_args)
            new_args = re.sub(r"\bnix-update-script\b", "", new_args)
            content = header_pre + new_args + header_post + rest_of_file

    # Clean up excessive blank lines (more than 2 -> 2)
    content = re.sub(r"\n{3,}", "\n\n", content)
    return content


def verify_parse(nix_content: str) -> bool:
    """Verify that the generated content is valid Nix syntax."""
    with tempfile.NamedTemporaryFile("w", suffix=".nix", delete=False) as tf:
        tf.write(nix_content)
        tf_path = tf.name
    try:
        res = subprocess.run(
            ["nix-instantiate", "--parse", tf_path],
            capture_output=True,
            text=True,
        )
        return res.returncode == 0
    finally:
        if os.path.exists(tf_path):
            os.unlink(tf_path)


def main():
    parser = argparse.ArgumentParser(
        description="Scan and remove redundant nix-update-script in Python packages across nixpkgs."
    )
    parser.add_argument(
        "--run",
        action="store_true",
        help="Apply changes to files and create treewide git commit",
    )
    args = parser.parse_args()

    files_to_check: List[str] = []
    for root, _, files in os.walk("pkgs"):
        for f in files:
            if f.endswith(".nix"):
                files_to_check.append(os.path.join(root, f))

    matching_files = 0
    modified_files = 0
    parse_errors = 0
    modified_paths: List[str] = []

    for file_path in files_to_check:
        try:
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                orig_content = f.read()
        except Exception as e:
            print(f"Warning: Failed to read {file_path}: {e}", file=sys.stderr)
            continue

        if not is_candidate(file_path, orig_content):
            continue

        matching_files += 1
        new_content = transform_nix_content(orig_content)

        if new_content == orig_content:
            continue

        if not verify_parse(new_content):
            print(
                f"ERROR: nix-instantiate parse failed for {file_path}! Skipping.",
                file=sys.stderr,
            )
            parse_errors += 1
            continue

        modified_files += 1
        modified_paths.append(file_path)

        if args.run:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(new_content)
        else:
            print(f"Found candidate: {file_path}")

    action_word = "Modified" if args.run else "Identified"
    print("\n--- Summary ---")
    print(f"Scanned files:    {len(files_to_check)}")
    print(f"Candidates found: {matching_files}")
    print(f"{action_word} files:   {modified_files}")
    print(f"Parse errors:     {parse_errors}")

    if args.run and modified_paths:
        commit_msg = (
            "treewide: remove redundant nix-update-script in python packages\n\n"
            "Since commit 048507355c6e8069c47642fc037da6d34b95acef, buildPythonPackage\n"
            "and buildPythonApplication default to `nix-update-script { }` in\n"
            "mk-python-derivation.nix.\n\n"
            "This commit removes redundant `passthru.updateScript = nix-update-script { };`\n"
            "and unneeded `nix-update-script` arguments across packages without causing\n"
            "derivation rebuilds."
        )
        print("\nCreating git commit...")
        subprocess.run(["git", "add"] + modified_paths, check=True)
        res = subprocess.run(["git", "commit", "-m", commit_msg])
        if res.returncode == 0:
            print("Successfully created treewide commit.")
        else:
            print("Commit failed.", file=sys.stderr)


if __name__ == "__main__":
    main()
