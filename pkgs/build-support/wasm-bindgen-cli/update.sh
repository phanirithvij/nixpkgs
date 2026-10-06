#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash curl jq nix-prefetch

set -euo pipefail

MAX_PKG_VER=$(ls pkgs/by-name/wa/wasm-bindgen-cli_*/package.nix | grep -o '0_2_[0-9]*' | sed 's/_/./g' | sort -V | tail -n 1)

ALL_VERSIONS=$(curl -s https://index.crates.io/wa/sm/wasm-bindgen-cli | jq -r '.vers')
NEW_VERSIONS=$(echo "$ALL_VERSIONS" | sort -V | sed "1,/^$MAX_PKG_VER$/d")

if [ -z "$NEW_VERSIONS" ]; then
    echo "wasm-bindgen-cli is already up-to-date ($MAX_PKG_VER)."
    exit 0
fi

latest_existing="pkgs/by-name/wa/wasm-bindgen-cli_${MAX_PKG_VER//./_}"

for version in $NEW_VERSIONS; do
    versionUnderscore="${version//./_}"
    PKG_DIR="pkgs/by-name/wa/wasm-bindgen-cli_$versionUnderscore"

    cp -r "$latest_existing" "$PKG_DIR"

    sed -i "s/version = \".*\"/version = \"$version\"/" "$PKG_DIR/package.nix"
    sed -i 's/hash = ".*"/hash = ""/' "$PKG_DIR/package.nix"

    SRC_HASH=$(nix-prefetch "{ fetchCrate, ... }: fetchCrate { pname = \"wasm-bindgen-cli\"; version = \"$version\"; }")
    sed -i "0,/hash = \"\"/s//hash = \"$SRC_HASH\"/" "$PKG_DIR/package.nix"

    CARGO_HASH=$(nix-build -E "(import ./. {}).wasm-bindgen-cli_$versionUnderscore.cargoDeps" 2>&1 | awk '/got:/{print $2; exit}' || true)
    if [ -n "$CARGO_HASH" ]; then
        sed -i "s/hash = \"\"/hash = \"$CARGO_HASH\"/" "$PKG_DIR/package.nix"
        echo "Packaged wasm-bindgen-cli $version"
    else
        echo "Failed to extract cargo deps hash for $version"
        exit 1
    fi
done

LATEST_VERSION=$(echo "$NEW_VERSIONS" | tail -n 1)
sed -i "s/wasm-bindgen-cli = wasm-bindgen-cli_.*/wasm-bindgen-cli = wasm-bindgen-cli_${LATEST_VERSION//./_};/" pkgs/top-level/aliases.nix
