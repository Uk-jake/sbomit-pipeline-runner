#!/usr/bin/env bash
# Stage 2-3: run witness
#
# Run the user's build under witness with eBPF file tracing and write a signed
# attestation to $SBOMIT_OUT_DIR/attestation.json.
#
# To change HOW witness is invoked, edit only the "Run" block.
#
# After the run this script verifies that eBPF tracing was really used:
#   - on failure : explain likely causes (eBPF unavailable, timeout, build error)
#   - on success : require "Using tracer: ebpf" in the log and >= 1 traced process
# (There is no separate eBPF check step. witness fails before the build starts
#  when the eBPF tracer cannot be loaded; it never falls back to ptrace.)
#
# Env:
#   SBOMIT_BUILD_COMMAND   the user's build command (never interpolated into code)
# Step output:
#   attestation-path
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

require_cmd witness jq base64 timeout
[ -n "${SBOMIT_BUILD_COMMAND:-}" ] || die "SBOMIT_BUILD_COMMAND is empty."
[ -f "$SBOMIT_KEY_DIR/signing.key" ] || die "Signing key not found. Stage 2-1 must run first."

BACKEND="${SBOMIT_TRACE_BACKEND:-$DEFAULT_TRACE_BACKEND}"
ATTESTORS="${SBOMIT_ATTESTORS:-$DEFAULT_ATTESTORS}"
TIMEOUT_MINUTES="${SBOMIT_TIMEOUT_MINUTES:-$DEFAULT_TIMEOUT_MINUTES}"
ATTESTATION="$SBOMIT_OUT_DIR/attestation.json"
LOG="$SBOMIT_WORK_DIR/witness-run.log"

cd "$SBOMIT_WORKSPACE"
mkdir -p "$SBOMIT_OUT_DIR"

# Timestamp marker: files created/modified by the root-run build are newer than this.
MARKER="$SBOMIT_WORK_DIR/build-start.marker"
touch "$MARKER"

# ── Run ──────────────────────────────────────────────────────────────────────
# Root is required for eBPF. HOME and PATH are kept so the build sees the same
# toolchains and caches as the runner user (sudo would otherwise reset them).
# Output goes to the Actions log and to $LOG (for the checks below).
group_start "witness run (backend: ${BACKEND}, timeout: ${TIMEOUT_MINUTES}m)"
set +e
sudo -E env "HOME=$HOME" "PATH=$PATH" \
  timeout --kill-after=30s "${TIMEOUT_MINUTES}m" \
  witness run \
    --step build \
    --trace \
    --attestor-command-run-trace-backend "$BACKEND" \
    --attestations "$ATTESTORS" \
    --signer-file-key-path "$SBOMIT_KEY_DIR/signing.key" \
    --outfile "$ATTESTATION" \
    -- bash -c "$SBOMIT_BUILD_COMMAND" 2>&1 | tee "$LOG"
rc="${PIPESTATUS[0]}"
set -e
group_end
# ─────────────────────────────────────────────────────────────────────────────

# ---- Return files to the runner user ----------------------------------------
# The build ran as root, so build outputs (workspace) and caches ($HOME, e.g.
# ~/go, ~/.cache) it created are root-owned. Later steps in the caller's job run
# as the runner user and would fail with "permission denied" on them.
# Only files that are root-owned AND created/changed after the marker (ctime,
# which tools cannot backdate the way they can mtime) are changed, so
# anything root-owned before this action is left as it was. Runs on success
# and failure alike.
owner="$(id -u):$(id -g)"
sudo find "$SBOMIT_WORKSPACE" "$HOME" "$SBOMIT_WORK_DIR" -xdev -user root -cnewer "$MARKER" \
  -exec chown -h "$owner" {} + 2>/dev/null || true
record_fact WITNESS_EXIT_CODE "$rc"

# Keep the witness log with the uploaded results (success or failure) for diagnosis.
cp "$LOG" "$SBOMIT_OUT_DIR/witness-run.log" 2>/dev/null || true

# ---- Failure: explain the most likely cause --------------------------------
if [ "$rc" -ne 0 ]; then
  if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
    die "witness run timed out after ${TIMEOUT_MINUTES} minutes."
  fi
  # The eBPF tracer is loaded BEFORE the build starts. If witness logged that the
  # tracer is in use, eBPF worked and the failure came from the build itself.
  if ! grep -q "Using tracer: ebpf" "$LOG" && grep -qiE 'ebpf|bpf|cgroup' "$LOG"; then
    # TODO: refine this message once the supported runner image is confirmed by E2E.
    die "witness could not use eBPF tracing on this runner (kernel $(uname -r)). SBOMit requires eBPF; ptrace is not supported. See the witness log above."
  fi
  # The tracer loaded but reported an internal error while reading events.
  # go-witness then kills the build on purpose (an incomplete trace must not be signed).
  if grep -q "command-run eBPF trace error" "$LOG"; then
    die "witness eBPF tracer reported an internal tracing error (see 'command-run eBPF trace error' above). This is a witness/go-witness issue, not a build failure. Known to happen on kernel 7.0 (this runner: $(uname -r))."
  fi
  die "witness run failed (exit code ${rc}). This is usually the build command itself failing; see the log above."
fi

# ---- Success: verify eBPF tracing was really used --------------------------
grep -q "Using tracer: ebpf" "$LOG" \
  || die "witness finished but did not report 'Using tracer: ebpf'. The attestation was not produced with eBPF tracing."

[ -s "$ATTESTATION" ] || die "witness finished but ${ATTESTATION} is missing or empty."

# Decode the DSSE envelope once and summarize what was captured.
statement="$SBOMIT_WORK_DIR/attestation.statement.json"
jq -r '.payload' "$ATTESTATION" | base64 -d >"$statement" || die "Could not decode the attestation payload."
count() { jq "$1" "$statement"; }
processes="$(count '[.predicate.attestations[] | select(.type | test("/command-run/")) | .attestation.processes // [] | length] | add // 0')"
opened_files="$(count '[.predicate.attestations[] | select(.type | test("/command-run/")) | .attestation.processes // [] | .[] | .openedfiles // {} | length] | add // 0')"
materials="$(count '[.predicate.attestations[] | select(.type | test("/material/")) | .attestation // {} | length] | add // 0')"
products="$(count '[.predicate.attestations[] | select(.type | test("/product/")) | .attestation // {} | length] | add // 0')"

[ "$processes" -gt 0 ] || die "The attestation contains no traced processes. eBPF tracing did not capture the build."

record_fact TRACED_PROCESSES "$processes"
record_fact TRACED_OPENED_FILES "$opened_files"
record_fact ATTESTATION_MATERIALS "$materials"
record_fact ATTESTATION_PRODUCTS "$products"

log_info "Attestation    : ${ATTESTATION}"
log_info "Processes      : ${processes}"
log_info "Opened files   : ${opened_files}"
log_info "Materials      : ${materials}"
log_info "Products       : ${products}  (known witness limitation: often empty when tracing is on)"

set_output attestation-path "$ATTESTATION"
