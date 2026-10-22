#!/usr/bin/env bash
# Stage 0-2: confirm the user's source has been checked out into the workspace.
#
# This action does not check out code itself. The caller's job must run
# actions/checkout before this action (setup steps in between are fine).
# Without it, $GITHUB_WORKSPACE is empty.
#
# Env:
#   GITHUB_WORKSPACE   set by GitHub Actions (falls back to $PWD for local runs)
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ws="$SBOMIT_WORKSPACE"
checkout_hint="Add 'uses: actions/checkout@v7' to your job before this action."

if [ ! -d "$ws" ]; then
  die "Workspace directory does not exist: ${ws}. ${checkout_hint}"
fi

# Empty workspace (ignoring nothing) means no checkout happened.
if [ -z "$(ls -A "$ws" 2>/dev/null)" ]; then
  die "Workspace is empty: ${ws}. ${checkout_hint}"
fi

# The git attestor needs a git repository at the workspace root.
if ! git -C "$ws" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  die "Workspace is not a git repository: ${ws}. ${checkout_hint} (If you used 'path:' on checkout, check out to the workspace root instead.)"
fi

commit="$(git -C "$ws" rev-parse HEAD 2>/dev/null || echo unknown)"

# Report (do not warn) files changed by earlier steps. Earlier setup steps are
# expected, but anything they produced is outside the traced build.
dirty="$(git -C "$ws" status --porcelain 2>/dev/null || true)"
if [ -n "$dirty" ]; then
  log_info "Workspace was modified by earlier steps (not observed by witness):"
  printf '%s\n' "$dirty" | head -50 | sed 's/^/    /'
fi

log_info "Workspace : ${ws}"
log_info "Commit    : ${commit}"
