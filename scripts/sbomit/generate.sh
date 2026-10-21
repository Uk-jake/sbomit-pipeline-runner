#!/usr/bin/env bash
# Stage 3-1: generate SBOM
#
# Run sbomit generate on the attestation with SBOMIT_SBOM_FORMAT and SBOMIT_USE_SYFT.
# Step output: sbom-path
#
# Status: skeleton. Not implemented yet.
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

not_implemented "Stage 3-1: generate SBOM"
