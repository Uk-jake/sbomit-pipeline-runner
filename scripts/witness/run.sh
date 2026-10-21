#!/usr/bin/env bash
# Stage 2-3: run witness
#
# Run: witness run --trace --trace-backend ebpf -- bash -c "$SBOMIT_BUILD_COMMAND"
# Under: sudo -E env HOME=$HOME PATH=$PATH, wrapped with coreutils timeout.
# Output: attestation in $SBOMIT_OUT_DIR, ownership returned to the runner user.
# Step output: attestation-path
#
# Status: skeleton. Not implemented yet.
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

not_implemented "Stage 2-3: run witness"
