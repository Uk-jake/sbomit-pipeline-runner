#!/usr/bin/env bash
# Stage 2-1: generate signing key
#
# Create an ephemeral signing key pair in $SBOMIT_KEY_DIR (outside the workspace).
# Only the public key is copied to $SBOMIT_OUT_DIR.
#
# Status: skeleton. Not implemented yet.
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

not_implemented "Stage 2-1: generate signing key"
