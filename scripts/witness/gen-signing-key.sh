#!/usr/bin/env bash
# Stage 2-1: generate signing key
#
# Create an ephemeral ed25519 key pair for signing the attestation.
#   private: $SBOMIT_KEY_DIR/signing.key   (outside the workspace, never uploaded)
#   public : $SBOMIT_OUT_DIR/signing.pub   (uploaded with the attestation)
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ensure_work_dirs

# ── Generate ─────────────────────────────────────────────────────────────────
openssl genpkey -algorithm ed25519 -out "$SBOMIT_KEY_DIR/signing.key"
chmod 600 "$SBOMIT_KEY_DIR/signing.key"
openssl pkey -in "$SBOMIT_KEY_DIR/signing.key" -pubout -out "$SBOMIT_OUT_DIR/signing.pub"
# ─────────────────────────────────────────────────────────────────────────────

log_info "Signing key: $SBOMIT_KEY_DIR/signing.key (private, not uploaded)"
log_info "Public key : $SBOMIT_OUT_DIR/signing.pub"
