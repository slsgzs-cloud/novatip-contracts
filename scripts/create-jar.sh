#!/usr/bin/env bash
set -euo pipefail

# Create a tip jar on a deployed tip_splitter contract.
#
# Required env (see .env.example):
#   NETWORK, SOURCE, OWNER, SLUG
#   CONTRACT_ID  (optional; defaults to the contents of .contract-id)
#
# Recipients — either one of:
#   RECIPIENT  single-recipient shorthand; builds the 100% split for you
#   SPLITS     full splits JSON, e.g.
#              '[{"to":"G...A","bps":6000},{"to":"G...B","bps":4000}]'
#              bps values must sum to 10000; at most 20 recipients
#
# Usage:  set -a; source .env; set +a; ./scripts/create-jar.sh
#         SPLITS='[{"to":"G...A","bps":7000},{"to":"G...B","bps":3000}]' \
#           ./scripts/create-jar.sh

: "${NETWORK:?set NETWORK}"
: "${SOURCE:?set SOURCE}"
: "${OWNER:?set OWNER}"
: "${SLUG:?set SLUG}"
CONTRACT_ID="${CONTRACT_ID:-$(cat .contract-id)}"

if [ -n "${SPLITS:-}" ]; then
  command -v jq >/dev/null 2>&1 || {
    echo "error: SPLITS requires jq to be installed" >&2
    exit 1
  }
  echo "${SPLITS}" | jq -e 'type == "array"' >/dev/null 2>&1 || {
    echo "error: SPLITS must be a JSON array" >&2
    exit 1
  }

  COUNT=$(echo "${SPLITS}" | jq 'length')
  if [ "${COUNT}" -eq 0 ] || [ "${COUNT}" -gt 20 ]; then
    echo "error: splits must have between 1 and 20 recipients (got ${COUNT})" >&2
    exit 1
  fi

  TOTAL_BPS=$(echo "${SPLITS}" | jq '[.[].bps] | add')
  if [ "${TOTAL_BPS}" != "10000" ]; then
    echo "error: bps values must sum to 10000 (got ${TOTAL_BPS})" >&2
    exit 1
  fi
else
  : "${RECIPIENT:?set RECIPIENT or SPLITS}"
  SPLITS="[{\"to\":\"${RECIPIENT}\",\"bps\":10000}]"
fi

echo "==> Creating jar ${SLUG} on ${CONTRACT_ID} (${COUNT:-1} recipient(s))"
stellar contract invoke \
  --id "${CONTRACT_ID}" \
  --source "${SOURCE}" \
  --network "${NETWORK}" \
  -- \
  create_jar \
  --owner "${OWNER}" \
  --jar_id "${SLUG}" \
  --splits "${SPLITS}"

echo "==> Done."
