#!/usr/bin/env bash
# Generates the Salesforce JWT key pair into ./keys (git-ignored).
# Run from the repo root:  bash scripts/make_keys.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p keys
if [[ -f keys/private.key ]]; then
  echo "keys/private.key already exists - delete it first for a new pair."; exit 1
fi
echo ">> Private key: set a passphrase (typing is invisible), enter it twice"
openssl genpkey -algorithm RSA -out keys/private.key -aes256
echo ">> Public certificate: enter the same passphrase once"
openssl req -new -x509 -key keys/private.key -out keys/public.crt -days 365 \
  -subj "/C=US/ST=Ohio/L=Columbus/O=test/CN=openflow-salesforce-test"
ls -l keys/
echo
echo "Upload keys/public.crt to the Salesforce External Client App."
echo "Paste the full contents of keys/private.key into Openflow (Connected App Key)."
echo "Windows path:"; (cd keys && pwd -W 2>/dev/null || pwd)
