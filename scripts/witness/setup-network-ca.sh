#!/usr/bin/env bash
# Stage 2-2: set up network-trace CA
#
# Runs only when network-trace=true. Generate/prepare the witness CA and register it
# in the OS trust store (update-ca-certificates) so the build trusts it.
#
# Status: skeleton. Not implemented yet.
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

not_implemented "Stage 2-2: set up network-trace CA"
