#!/usr/bin/env bash
# Stage 1-3: check eBPF
#
# Record kernel/BTF facts, then run a functional probe: trace 'true' with
# witness --trace-backend ebpf. Fail if eBPF tracing does not work (no ptrace fallback).
# Must also confirm witness did not silently fall back to another backend.
#
# Status: skeleton. Not implemented yet.
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

not_implemented "Stage 1-3: check eBPF"
