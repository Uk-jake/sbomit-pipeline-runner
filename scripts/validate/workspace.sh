#!/usr/bin/env bash
# Stage 0-2: confirm the user's source has been checked out into the workspace.
#
# This action does not check out code itself. The user must run actions/checkout
# immediately before this action. Without it, $GITHUB_WORKSPACE is empty.
#
# Env:
#   GITHUB_WORKSPACE   set by GitHub Actions (falls back to $PWD for local runs)
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

ws="$SBOMIT_WORKSPACE"
checkout_hint="Add 'uses: actions/checkout@v7' as the step right before this action."

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

# Warn (not fail) when files were changed before this action ran.
# Anything prepared before witness starts is outside the traced build.
dirty="$(git -C "$ws" status --porcelain 2>/dev/null || true)"
if [ -n "$dirty" ]; then
  log_warn "Workspace has changes before the traced build started. Work done before this action is not observed by witness. Place this action right after actions/checkout."
  group_start "Uncommitted changes in workspace"
  printf '%s\n' "$dirty" | head -50
  group_end
fi

log_info "Workspace : ${ws}"
log_info "Commit    : ${commit}"
