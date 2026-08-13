#!/usr/bin/env bash
set -euo pipefail

# Deploy the tip_splitter contract to a Stellar network.
#
# Required env (see .env.example):
#   NETWORK     testnet | mainnet | local
#   SOURCE      Stellar CLI identity used to sign
#   ADMIN       admin address stored in the contract
#   USDC_TOKEN  USDC Stellar Asset Contract id (C...)
#
# Usage:  set -a; source .env; set +a; ./scripts/deploy.sh

: "${NETWORK:?set NETWORK}"
: "${SOURCE:?set SOURCE}"
: "${ADMIN:?set ADMIN}"
: "${USDC_TOKEN:?set USDC_TOKEN}"

echo "==> Building contracts"
stellar contract build

# The Stellar CLI moved its wasm target from wasm32-unknown-unknown to
# wasm32v1-none, so the output path differs by CLI version. Locate the artifact
# rather than hardcoding either path, newest first.
WASM="$(find target -name 'tip_splitter.wasm' -path '*release*' -not -path '*/deps/*' \
        -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"

if [ -z "${WASM}" ] || [ ! -f "${WASM}" ]; then
  echo "error: no built tip_splitter.wasm found under target/." >&2
  echo "       If the build printed a missing-target error, run:" >&2
  echo "       rustup target add wasm32v1-none" >&2
  exit 1
fi

echo "==> Built ${WASM} ($(wc -c < "${WASM}") bytes)"

echo "==> Deploying tip_splitter to ${NETWORK}"
CONTRACT_ID=$(stellar contract deploy \
  --wasm "${WASM}" \
  --source "${SOURCE}" \
  --network "${NETWORK}" \
  -- \
  --admin "${ADMIN}" \
  --token "${USDC_TOKEN}")

echo "==> Deployed contract id: ${CONTRACT_ID}"
echo "${CONTRACT_ID}" > .contract-id
echo "    (saved to .contract-id)"
