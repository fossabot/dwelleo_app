#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "l10n.yaml"
  "lib/l10n/app_en.arb"
  "lib/l10n/app_ar.arb"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing required localization source: $file" >&2
    exit 1
  fi
done

flutter gen-l10n
