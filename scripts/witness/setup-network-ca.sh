#!/usr/bin/env bash
# Stage 2-2: set up network-trace CA
#
# Status: NOT IMPLEMENTED. network-trace=true is rejected in Stage 0 for now.
#
# Reference procedure (manual, from VM experiments):
#
#   # Generate the CA with a no-op run.
#   sudo -E HOME=$HOME PATH=$PATH witness run \
#     --experimental \
#     --step ca-bootstrap \
#     -a network-trace \
#     --signer-file-key-path ./signing-key.pem \
#     -o /dev/null \
#     -- /bin/true
#
#   # Trust the CA.
#   sudo cp ./witness_nettrace_proxy/ca_cert.pem \
#     /usr/local/share/ca-certificates/witness-nettrace.crt
#   sudo update-ca-certificates
#
#   The CA cert/key default to ./witness_nettrace_proxy/ relative to the current
#   directory. Every later witness run must use the same CA, otherwise HTTPS in
#   the build fails with "x509: certificate signed by unknown authority".
#
# Notes for implementation:
#   - Default CA location would be inside the user workspace (witness runs there).
#     Prefer pointing witness at $SBOMIT_KEY_DIR with the network-trace attestor
#     options (--attestor-network-trace-ca-cert-path / -ca-key-path) so the CA key
#     never lands in the workspace. Verify these flags on the pinned witness.
#   - Stage 2-3 must then add: --experimental, -a network-trace, and the same CA paths.
#   - Some build tools ignore the OS trust store (Node, Python requests, Java);
#     they may need NODE_EXTRA_CA_CERTS / REQUESTS_CA_BUNDLE / SSL_CERT_FILE.
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

die "Stage 2-2: network trace is not implemented yet."
