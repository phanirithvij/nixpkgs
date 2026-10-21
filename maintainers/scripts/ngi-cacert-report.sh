#!/usr/bin/env bash
set -euo pipefail

# Report CA trust store findings for team-maintained nixpkgs packages
# using `nix run github:zimbatm/nix-cacert-scan`.
#
# Related tracking issue: https://github.com/NixOS/nixpkgs/issues/576544

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TEAM="ngi"
RESULT_LINK="result-team-packages"
SKIP_BUILD=0
FORMAT="both" # markdown, tsv, json, both

usage() {
  cat <<USAGE
Usage: $0 [OPTIONS]

Options:
  --team <name>         Team name from maintainers/team-list.nix (default: ngi)
  --result <path>       Path to existing result symlink or store path
  --format <fmt>        Output format: markdown, tsv, json, both (default: both)
  --skip-build          Skip building, scan existing result path
  -h, --help            Show this help message

Examples:
  $0
  $0 --team ngi --format markdown
  $0 --result ./result-team-packages
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --team)
    TEAM="$2"
    shift 2
    ;;
  --result)
    RESULT_LINK="$2"
    SKIP_BUILD=1
    shift 2
    ;;
  --format)
    FORMAT="$2"
    shift 2
    ;;
  --skip-build)
    SKIP_BUILD=1
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    usage
    exit 1
    ;;
  esac
done

cd "$REPO_ROOT"

if [[ $SKIP_BUILD -eq 0 ]]; then
  echo "==> Building team packages derivation for team '${TEAM}'..." >&2
  # Try building the single linkFarm derivation
  if ! nom-build maintainers/scripts/team-packages.nix \
    --argstr team "$TEAM" \
    -o "$RESULT_LINK" \
    --option substituters "https://cache.nixos.org https://nix-community.cachix.org https://loudgolem-nur-pkgs-0.cachix.org" \
    --option connect-timeout 5; then
    echo "==> Direct linkFarm build failed. Falling back to building available packages with --keep-going..." >&2
    rm -rf "$RESULT_LINK"
    # Build package list with keep-going
    BUILT_PATHS=$(nom-build maintainers/scripts/team-packages.nix \
      --argstr team "$TEAM" \
      --arg returnList true \
      --keep-going \
      --no-out-link \
      --option substituters "https://cache.nixos.org https://nix-community.cachix.org https://loudgolem-nur-pkgs-0.cachix.org" \
      --option connect-timeout 5 || true)

    if [[ -z "$BUILT_PATHS" ]]; then
      echo "Error: No packages could be built." >&2
      exit 1
    fi

    # Construct a linkFarm from all successfully built packages
    NIX_ENTRIES=$(echo "$BUILT_PATHS" | while read -r p; do
      if [[ -n "$p" && -d "$p" ]]; then
        bname=$(basename "$p" | sed -E 's/^[a-z0-9]{32}-//')
        echo "{ name = \"$bname\"; path = $p; }"
      fi
    done)

    nom-build -E "with import ./. {}; linkFarm \"${TEAM}-team-packages\" [ $NIX_ENTRIES ]" -o "$RESULT_LINK"
  fi
fi

if [[ ! -e "$RESULT_LINK" ]]; then
  echo "Error: Result link '$RESULT_LINK' does not exist." >&2
  exit 1
fi

RESULT_REAL="$(readlink -f "$RESULT_LINK")"
echo "==> Result target: $RESULT_REAL" >&2

# Direct package paths belonging to the team in the result linkFarm
mapfile -t TEAM_STORE_PATHS < <(readlink -f "$RESULT_REAL"/* 2>/dev/null | sort -u)
echo "==> Found ${#TEAM_STORE_PATHS[@]} packages maintained by team '${TEAM}' in result." >&2

echo "==> Scanning closure with 'nix run github:zimbatm/nix-cacert-scan'..." >&2
SCAN_RAW=$(nix run github:zimbatm/nix-cacert-scan -- --json "$RESULT_REAL" 2>/dev/null || true)

# Filter findings to only those whose .nar is in TEAM_STORE_PATHS
# and generate report
FILTERED_JSON=$(echo "$SCAN_RAW" | jq -rs --argjson team_paths "$(printf '%s\n' "${TEAM_STORE_PATHS[@]}" | jq -R . | jq -s .)" '
  [
    .[]
    | select(.nar as $nar | $team_paths | index($nar) != null)
    | select((.known_roots | length) >= 20)
    | select(.nar | test("-nss-cacert-") | not)
  ]
')

nix-shell -p python3 --run "python3 \"$SCRIPT_DIR/format-cacert-report.py\" \"$FORMAT\" \"$TEAM\" \"${#TEAM_STORE_PATHS[@]}\"" <<<"$FILTERED_JSON"
