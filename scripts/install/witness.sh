#!/usr/bin/env bash
# Stage 1-2: install witness
#
# Install the eBPF-capable witness binary to /usr/local/bin/witness.
# Version: ${SBOMIT_WITNESS_VERSION:-$DEFAULT_WITNESS_VERSION} (binary source TBD).
# Must verify integrity (sha256) before installing.
#
# Status: skeleton. Not implemented yet.
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

not_implemented "Stage 1-2: install witness"
