# shellcheck shell=bash
# common.sh — shared helpers for every pipeline script.
#
# Usage (from any script under scripts/<stage>/):
#   # shellcheck source=scripts/lib/common.sh
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
#
# Contract for all scripts:
#   - Inputs come only from SBOMIT_* environment variables.
#   - Outputs go to $GITHUB_OUTPUT when running in GitHub Actions,
#     otherwise they are printed to stdout as key=value (local runs).
#   - Working files live under $SBOMIT_WORK_DIR (outside the user workspace).

# Guard against double sourcing.
if [ -n "${__SBOMIT_COMMON_LOADED:-}" ]; then
  return 0
fi
__SBOMIT_COMMON_LOADED=1

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

# Repository root of this action (scripts/lib/../..).
SBOMIT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Internal defaults.
# shellcheck source=scripts/lib/defaults.sh
source "${SBOMIT_ROOT_DIR}/scripts/lib/defaults.sh"

# Working area. RUNNER_TEMP is per-job and wiped by GitHub; /tmp is the local fallback.
SBOMIT_WORK_DIR="${SBOMIT_WORK_DIR:-${RUNNER_TEMP:-/tmp}/sbomit}"
SBOMIT_KEY_DIR="${SBOMIT_WORK_DIR}/keys"   # private material; never uploaded
SBOMIT_OUT_DIR="${SBOMIT_WORK_DIR}/out"    # final results; uploaded as the artifact
export SBOMIT_WORK_DIR SBOMIT_KEY_DIR SBOMIT_OUT_DIR

# User source location. GITHUB_WORKSPACE in Actions, current directory locally.
SBOMIT_WORKSPACE="${GITHUB_WORKSPACE:-$PWD}"
export SBOMIT_WORKSPACE

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

# True when running inside GitHub Actions.
in_gha() {
  [ "${GITHUB_ACTIONS:-}" = "true" ]
}

# Escape a message for a GitHub workflow command (%, CR, LF must be encoded).
_gha_escape() {
  local s="$1"
  s="${s//'%'/'%25'}"
  s="${s//$'\r'/'%0D'}"
  s="${s//$'\n'/'%0A'}"
  printf '%s' "$s"
}

log_info() {
  printf '[sbomit] %s\n' "$*"
}

log_notice() {
  if in_gha; then
    printf '::notice title=SBOMit::%s\n' "$(_gha_escape "$*")"
  else
    printf '[sbomit] NOTICE: %s\n' "$*"
  fi
}

log_warn() {
  if in_gha; then
    printf '::warning title=SBOMit::%s\n' "$(_gha_escape "$*")"
  else
    printf '[sbomit] WARNING: %s\n' "$*" >&2
  fi
}

log_error() {
  if in_gha; then
    printf '::error title=SBOMit::%s\n' "$(_gha_escape "$*")"
  else
    printf '[sbomit] ERROR: %s\n' "$*" >&2
  fi
}

# Print an error and exit non-zero.
die() {
  log_error "$*"
  exit 1
}

# Collapsible log sections in the Actions UI.
group_start() {
  if in_gha; then printf '::group::%s\n' "$*"; else printf '[sbomit] ==> %s\n' "$*"; fi
}
group_end() {
  if in_gha; then printf '::endgroup::\n'; fi
}

# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

# Fail if any of the given commands is missing from PATH.
require_cmd() {
  local cmd missing=()
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    die "Required command(s) not found: ${missing[*]}"
  fi
}

# Return 0 if $1 equals one of the remaining arguments.
is_one_of() {
  local value="$1" candidate
  shift
  for candidate in "$@"; do
    [ "$value" = "$candidate" ] && return 0
  done
  return 1
}

# Return 0 for the exact strings "true" or "false".
is_bool() {
  is_one_of "$1" true false
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

# set_output <name> <value>
# Writes a step output. Supports multi-line values via a random delimiter.
set_output() {
  local name="$1" value="$2" delim
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    delim="SBOMIT_EOF_$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
    {
      printf '%s<<%s\n' "$name" "$delim"
      printf '%s\n' "$value"
      printf '%s\n' "$delim"
    } >>"$GITHUB_OUTPUT"
  else
    printf '%s=%s\n' "$name" "$value"
  fi
}

# Create the working directories with safe permissions.
ensure_work_dirs() {
  mkdir -p "$SBOMIT_WORK_DIR" "$SBOMIT_OUT_DIR" "$SBOMIT_KEY_DIR"
  chmod 700 "$SBOMIT_KEY_DIR"   # key dir must not be readable by others
}

# Placeholder used by skeleton scripts that are not implemented yet.
not_implemented() {
  log_notice "$1: not implemented yet (skeleton). Skipping."
}
