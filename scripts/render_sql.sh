#!/usr/bin/env bash
# Fills <SF_MY_DOMAIN> into the SQL files -> build/ (git-ignored)
# Usage: SF_MY_DOMAIN=orgfarm-xxxx-dev-ed.develop.my.salesforce.com bash scripts/render_sql.sh
set -euo pipefail
cd "$(dirname "$0")/.."
: "${SF_MY_DOMAIN:?Set SF_MY_DOMAIN (no https://)}"
[[ "$SF_MY_DOMAIN" == *"://"* ]] && { echo "SF_MY_DOMAIN must not include https://"; exit 1; }
mkdir -p build
for f in RUN_ALL.sql snowflake/*/*.sql; do
  out="build/$(echo "$f" | tr '/' '_')"
  sed "s/<SF_MY_DOMAIN>/${SF_MY_DOMAIN}/g" "$f" > "$out"
  echo "wrote $out"
done
