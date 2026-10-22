#!/usr/bin/env bash
# Stage 3-2: check SBOM
#
# Verify the generated SBOM is a structurally valid document for its format and
# report how many packages it lists.
#   SPDX      : spdxVersion is a string, packages is an array
#   CycloneDX : bomFormat == "CycloneDX", specVersion is a string, components is an array
# A document with zero packages is a WARNING, not a failure (decision: revisit
# after looking at real SBOMs).
#
# Env:
#   SBOMIT_SBOM_FORMAT   spdx23 | cdx14 | cdx15
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

require_cmd jq

FORMAT="${SBOMIT_SBOM_FORMAT:?SBOMIT_SBOM_FORMAT is required}"
SBOM="$(sbom_path "$FORMAT")"

[ -s "$SBOM" ] || die "SBOM not found: ${SBOM}. Stage 3-1 must succeed first."
jq empty "$SBOM" 2>/dev/null || die "${SBOM} is not valid JSON."

case "$FORMAT" in
  spdx*)
    jq -e '(.spdxVersion | type) == "string" and (.packages | type) == "array"' "$SBOM" >/dev/null \
      || die "${SBOM} is not a valid SPDX document (missing spdxVersion or packages)."
    spec="$(jq -r '.spdxVersion' "$SBOM")"
    packages="$(jq '.packages | length' "$SBOM")"
    ;;
  cdx*)
    jq -e '.bomFormat == "CycloneDX" and (.specVersion | type) == "string" and (.components | type) == "array"' "$SBOM" >/dev/null \
      || die "${SBOM} is not a valid CycloneDX document (missing bomFormat, specVersion or components)."
    spec="CycloneDX $(jq -r '.specVersion' "$SBOM")"
    packages="$(jq '.components | length' "$SBOM")"
    ;;
esac

record_fact SBOM_SPEC "$spec"
record_fact SBOM_PACKAGES "$packages"

if [ "$packages" -eq 0 ]; then
  log_warn "The SBOM is valid but lists no packages. Check that build-command builds your project and that its dependencies were observed."
fi

log_info "Spec     : ${spec}"
log_info "Packages : ${packages}"
