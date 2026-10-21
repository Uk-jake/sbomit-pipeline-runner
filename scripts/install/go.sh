#!/usr/bin/env bash
# Stage 1-2: install tools Go
#
# Go used ONLY to build witness and sbomit. It goes to $SBOMIT_TOOLS_DIR/go and
# is NOT put on the user's PATH (see use_tools_go in common.sh for why).
#
# To change the Go version, edit only GO_VERSION.
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# ── Version ──────────────────────────────────────────────────────────────────
GO_VERSION="${SBOMIT_TOOLS_GO_VERSION:-1.26.5}"   # witness requires >= 1.26.5
# ─────────────────────────────────────────────────────────────────────────────

# ── Install ──────────────────────────────────────────────────────────────────
group_start "Install tools Go ${GO_VERSION}"
mkdir -p "$SBOMIT_TOOLS_DIR"
cd "$SBOMIT_TOOLS_DIR"
rm -rf go

curl -fsSLO "https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz"
echo "$(curl -fsSL "https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz.sha256")  go${GO_VERSION}.linux-amd64.tar.gz" | sha256sum -c -
tar -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm "go${GO_VERSION}.linux-amd64.tar.gz"

./go/bin/go version
group_end
# ─────────────────────────────────────────────────────────────────────────────

record_fact TOOLS_GO_VERSION "$GO_VERSION"
