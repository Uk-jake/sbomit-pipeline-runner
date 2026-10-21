#!/usr/bin/env bash
# Stage 1-1: check runner
#
# Verify the runner can execute the pipeline: Linux, x86_64, passwordless sudo.
# Fails fast with a clear message on unsupported runners.
#
# Status: skeleton. Not implemented yet.
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

not_implemented "Stage 1-1: check runner"
