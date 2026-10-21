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
MAX_JOBS=0 # default to substituting cached packages without compiling for hours
FORMAT="both" # markdown, tsv, json, both

usage() {
  cat << USAGE
Usage: $0 [OPTIONS]

Options:
  --team <name>         Team name from maintainers/team-list.nix (default: ngi)
  --result <path>       Path to existing result symlink or store path to scan
  --format <fmt>        Output format: markdown, tsv, json, both (default: both)
  --max-jobs <N>        Max local build jobs (default: 0, substitute pre-built packages from cache)
  --skip-build          Skip building, scan existing result path
  -h, --help            Show this help message

Examples:
  $0
  $0 --max-jobs 4       # Also compile missing packages locally using 4 cores
  $0 --format markdown
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
    --max-jobs)
      MAX_JOBS="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    -h|--help)
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
  echo "==> Fetching and building packages for team '${TEAM}' (max-jobs=${MAX_JOBS})..." >&2

  TMP_DRVS=$(mktemp)
  TMP_PATHS=$(mktemp)
  trap 'rm -f "$TMP_DRVS" "$TMP_PATHS"' EXIT

  # 1. Instantiate the list of derivations for the team
  echo "==> Evaluating derivations for team '${TEAM}'..." >&2
  nix-instantiate maintainers/scripts/team-packages.nix \
    --argstr team "$TEAM" \
    --arg returnList true > "$TMP_DRVS" 2>/dev/null

  TOTAL_TEAM_PKGS=$(wc -l < "$TMP_DRVS")
  echo "==> Found $TOTAL_TEAM_PKGS candidate packages for team '${TEAM}'." >&2

  # 2. Build / substitute with --keep-going
  echo "==> Realising packages from binary caches / local builds..." >&2
  nix-build maintainers/scripts/team-packages.nix \
    --argstr team "$TEAM" \
    --arg returnList true \
    --keep-going \
    --max-jobs "$MAX_JOBS" \
    --no-out-link \
    --option substituters "https://cache.nixos.org https://nix-community.cachix.org" \
    --option connect-timeout 5 >/dev/null 2>&1 || true

  # 3. Collect store paths of all successfully realised packages
  while read -r drv; do
    while read -r out; do
      if [[ -n "$out" && -e "$out" ]]; then
        echo "$out"
      fi
    done < <(nix-store -q --outputs "${drv%%!*}" 2>/dev/null || true)
  done < "$TMP_DRVS" | sort -u > "$TMP_PATHS"

  REALIZED_COUNT=$(wc -l < "$TMP_PATHS")
  echo "==> Successfully realised $REALIZED_COUNT store paths for team packages." >&2

  if [[ $REALIZED_COUNT -eq 0 ]]; then
    echo "Error: No packages could be realised." >&2
    exit 1
  fi

  # 4. Assemble the realised packages into a single result linkFarm with store context
  echo "==> Constructing single result linkFarm..." >&2
  nix-build -E "with import ./. {}; linkFarm \"${TEAM}-team-packages\" (map (p: { name = baseNameOf p; path = /. + p; }) (pkgs.lib.filter (s: s != \"\") (pkgs.lib.splitString \"\n\" (pkgs.lib.fileContents $TMP_PATHS))))" \
    -o "$RESULT_LINK" >/dev/null
fi

if [[ ! -e "$RESULT_LINK" ]]; then
  echo "Error: Result link '$RESULT_LINK' does not exist." >&2
  exit 1
fi

RESULT_REAL="$(readlink -f "$RESULT_LINK")"
echo "==> Result target: $RESULT_REAL" >&2

# Direct package paths belonging to the team in the result linkFarm
mapfile -t TEAM_STORE_PATHS < <(readlink -f "$RESULT_REAL"/* 2>/dev/null | sort -u)
echo "==> Found ${#TEAM_STORE_PATHS[@]} team packages in '$RESULT_LINK'." >&2

echo "==> Scanning closure with 'nix run github:zimbatm/nix-cacert-scan'..." >&2
SCAN_RAW=$(nix run github:zimbatm/nix-cacert-scan -- --json "$RESULT_REAL" 2>/dev/null || true)

# Filter findings to only those whose .nar is one of the team's packages in the result
FILTERED_JSON=$(echo "$SCAN_RAW" | jq -rs --argjson team_paths "$(printf '%s\n' "${TEAM_STORE_PATHS[@]}" | jq -R . | jq -s .)" '
  [
    .[]
    | select(.nar as $nar | $team_paths | index($nar) != null)
    | select((.known_roots | length) >= 20)
    | select(.nar | test("-nss-cacert-") | not)
  ]
')

nix-shell -p python3 --run "python3 \"$SCRIPT_DIR/format-cacert-report.py\" \"$FORMAT\" \"$TEAM\" \"${#TEAM_STORE_PATHS[@]}\"" <<< "$FILTERED_JSON"
