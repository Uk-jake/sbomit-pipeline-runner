#!/usr/bin/env bash
# Stage 1-2: install syft
#
# To change how syft is installed, edit only the "Install" block.
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# ── Install ──────────────────────────────────────────────────────────────────
group_start "Install syft"
curl -sSfL https://get.anchore.io/syft | sudo sh -s -- -b /usr/local/bin
group_end
# ─────────────────────────────────────────────────────────────────────────────

# Record the version the installer picked.
record_fact SYFT_VERSION "$(syft version | awk '/^Version:/ {print $2}')"
