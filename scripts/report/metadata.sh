#!/usr/bin/env bash
# Stage 4-1: write run metadata
#
# Write $SBOMIT_OUT_DIR/run-metadata.json: kernel, BTF, runner image (ImageOS/ImageVersion),
# tool versions, input values, event name, commit SHA.
# Step output: metadata-path
#
# Status: skeleton. Not implemented yet.
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

not_implemented "Stage 4-1: write run metadata"
