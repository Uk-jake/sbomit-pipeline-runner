#!/usr/bin/env bash
# Stage 1-2: install syft
#
# Install a pinned syft release, verified against the official checksums file.
# Version: ${SBOMIT_SYFT_VERSION:-$DEFAULT_SYFT_VERSION}.
#
# Status: skeleton. Not implemented yet.
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

not_implemented "Stage 1-2: install syft"
