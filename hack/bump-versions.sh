#!/usr/bin/env bash

# Checks the latest GitHub release for kcp, kcp-operator, and api-syncagent,
# then bumps Chart.yaml appVersion (and chart version patch) for any that changed.
# Also regenerates kcp-operator CRDs when its version changes.
#
# Requirements: gh, yq, kubectl (for CRD regeneration)
#
# Usage:
#   hack/bump-versions.sh            # check & bump all
#   hack/bump-versions.sh --dry-run  # only print what would change

set -euo pipefail
cd "$(dirname "$0")/.."

for cmd in gh yq; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: '$cmd' is required but not installed." >&2
    exit 1
  fi
done

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

# Map: chart directory -> GitHub repo -> whether appVersion uses 'v' prefix
declare -A CHART_REPOS=(
  ["kcp"]="kcp-dev/kcp"
  ["kcp-operator"]="kcp-dev/kcp-operator"
  ["api-syncagent"]="kcp-dev/api-syncagent"
)

# kcp uses bare versions (0.30.2), operator and syncagent use v-prefixed (v0.5.1)
declare -A VERSION_PREFIX=(
  ["kcp"]=""
  ["kcp-operator"]="v"
  ["api-syncagent"]="v"
)

changed=()

for chart in "${!CHART_REPOS[@]}"; do
  repo="${CHART_REPOS[$chart]}"
  prefix="${VERSION_PREFIX[$chart]}"
  chart_yaml="charts/${chart}/Chart.yaml"

  current_app_version="$(yq '.appVersion' "$chart_yaml")"
  # Get latest release tag from GitHub
  latest_tag="$(gh release view --repo "$repo" --json tagName --jq '.tagName')"

  # Normalize: add or strip 'v' prefix to match chart convention
  if [[ -z "$prefix" ]]; then
    # Chart expects no prefix — strip 'v' if present
    latest_app_version="${latest_tag#v}"
  else
    # Chart expects 'v' prefix — ensure it's there
    latest_app_version="${latest_tag}"
    if [[ "$latest_app_version" != v* ]]; then
      latest_app_version="v${latest_app_version}"
    fi
  fi

  if [[ "$current_app_version" == "$latest_app_version" ]]; then
    echo "✓ ${chart}: up to date (${current_app_version})"
    continue
  fi

  echo "⬆ ${chart}: ${current_app_version} → ${latest_app_version}"

  if [[ "$DRY_RUN" == true ]]; then
    changed+=("$chart")
    continue
  fi

  # Bump appVersion
  yq -i ".appVersion = \"${latest_app_version}\"" "$chart_yaml"

  # Bump chart version patch
  current_chart_version="$(yq '.version' "$chart_yaml")"
  IFS='.' read -r major minor patch <<< "$current_chart_version"
  new_chart_version="${major}.${minor}.$((patch + 1))"
  yq -i ".version = \"${new_chart_version}\"" "$chart_yaml"

  echo "  chart version: ${current_chart_version} → ${new_chart_version}"
  changed+=("$chart")
done

# Regenerate kcp-operator CRDs if it was bumped
if printf '%s\n' "${changed[@]}" | grep -qx "kcp-operator"; then
  if [[ "$DRY_RUN" == true ]]; then
    echo ""
    echo "Would regenerate kcp-operator CRDs"
  else
    echo ""
    echo "Regenerating kcp-operator CRDs..."
    hack/update-kcp-operator-crds.sh
  fi
fi

echo ""
if [[ ${#changed[@]} -eq 0 ]]; then
  echo "All charts are up to date."
else
  if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run complete. ${#changed[@]} chart(s) would be bumped."
  else
    echo "Done. ${#changed[@]} chart(s) bumped."
    echo "Don't forget to review the changes and commit."
  fi
fi
