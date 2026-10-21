# shellcheck shell=bash
# defaults.sh — internal values that are NOT exposed as action inputs (yet).
#
# This file is the single source of truth for pipeline-controlled settings.
# Scripts must read these values as ${SBOMIT_<NAME>:-$DEFAULT_<NAME>}, so that
# promoting one to an action input later only requires adding the input in
# action.yml and mapping it to the matching SBOMIT_<NAME> env var.
#
# User-facing input defaults (language, sbom-format, ...) live in action.yml,
# not here, to avoid two sources of truth.

# Tracing backend. Fixed by project policy: SBOMit does not use ptrace.
# shellcheck disable=SC2034  # consumed by scripts that source this file
DEFAULT_TRACE_BACKEND="ebpf"

# Upper bound for the traced build (minutes). Applied with coreutils `timeout`
# because composite actions cannot set a job-level timeout.
# shellcheck disable=SC2034
DEFAULT_TIMEOUT_MINUTES="30"

# witness attestors to enable. Placeholder until the witness stage is implemented.
# shellcheck disable=SC2034
DEFAULT_ATTESTORS="environment,git"

# Pinned tool versions. Finalized in the install stage (witness binary source TBD).
# shellcheck disable=SC2034
DEFAULT_WITNESS_VERSION=""
# shellcheck disable=SC2034
DEFAULT_SBOMIT_VERSION=""
# shellcheck disable=SC2034
DEFAULT_SYFT_VERSION=""
