#!/usr/bin/env bash
# Stage 3-1: generate SBOM
#
# Generate an SBOM from the Stage 2 attestation with `sbomit generate`.
# When use-syft is true, sbomit first runs `syft <project-dir> -o spdx-json`
# (syft from PATH, installed in Stage 1) and merges it with the
# attestation-derived packages.
#
# To change HOW sbomit is invoked, edit only the "Generate" block.
#
# Env:
#   SBOMIT_SBOM_FORMAT   spdx23 | cdx14 | cdx15
#   SBOMIT_USE_SYFT      true | false
# Step output:
#   sbom-path
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

require_cmd sbomit git

FORMAT="${SBOMIT_SBOM_FORMAT:?SBOMIT_SBOM_FORMAT is required}"
USE_SYFT="${SBOMIT_USE_SYFT:?SBOMIT_USE_SYFT is required}"
ATTESTATION="$SBOMIT_OUT_DIR/attestation.json"
SBOM="$(sbom_path "$FORMAT")"

[ -s "$ATTESTATION" ] || die "Attestation not found: ${ATTESTATION}. Stage 2 must succeed first."

# Document identity: which repository and which commit this SBOM describes.
#   name    = repository name (e.g. "my-project" from "owner/my-project")
#   version = short commit SHA of the checked-out source
DOC_NAME="${GITHUB_REPOSITORY##*/}"
DOC_NAME="${DOC_NAME:-$(basename "$SBOMIT_WORKSPACE")}"
DOC_VERSION="$(git -C "$SBOMIT_WORKSPACE" rev-parse --short=12 HEAD 2>/dev/null || echo "${GITHUB_SHA:-unknown}" | cut -c1-12)"

# syft catalog flags (only when enabled). syft scans the workspace after the build.
SYFT_ARGS=()
if [ "$USE_SYFT" = "true" ]; then
  require_cmd syft
  SYFT_ARGS=(--catalog syft --project-dir "$SBOMIT_WORKSPACE")
fi

cd "$SBOMIT_WORKSPACE"

# ── Generate ─────────────────────────────────────────────────────────────────
group_start "sbomit generate (format: ${FORMAT}, syft: ${USE_SYFT})"
sbomit generate "$ATTESTATION" \
  --format "$FORMAT" \
  --name "$DOC_NAME" \
  --version "$DOC_VERSION" \
  --output "$SBOM" \
  "${SYFT_ARGS[@]}"
group_end
# ─────────────────────────────────────────────────────────────────────────────

[ -s "$SBOM" ] || die "sbomit finished but ${SBOM} is missing or empty."

record_fact SBOM_FORMAT "$FORMAT"
record_fact SBOM_USE_SYFT "$USE_SYFT"
record_fact SBOM_DOCUMENT_NAME "$DOC_NAME"
record_fact SBOM_DOCUMENT_VERSION "$DOC_VERSION"

log_info "SBOM     : ${SBOM}"
log_info "Document : ${DOC_NAME} ${DOC_VERSION}"

set_output sbom-path "$SBOM"
