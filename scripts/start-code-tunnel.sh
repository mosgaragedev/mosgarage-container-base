#!/usr/bin/env bash
# =============================================================================
# start-code-tunnel — run a VS Code tunnel from inside the container
#
# Supervisord starts this only when the operator opts in:
#     docker exec -it <container> mgw start code-tunnel
#
#   GITHUB_TOKEN        GitHub token with tunnel scope (required)
#   CODE_TUNNEL_NAME    tunnel name (default: mosgarage-<hostname>)
#
# Without a token the program idles instead of crash-looping, so the
# supervisor stays healthy.
# =============================================================================
set -euo pipefail

TUNNEL_NAME="${CODE_TUNNEL_NAME:-mosgarage-$(hostname -s)}"

log() {
  printf '%s [code-tunnel] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

if ! command -v code >/dev/null 2>&1; then
  log "the 'code' CLI is not installed in this image — tunnel unavailable; idling"
  exec sleep infinity
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  log "GITHUB_TOKEN is not set — tunnel unavailable; idling"
  exec sleep infinity
fi

log "starting tunnel '${TUNNEL_NAME}'"
exec code tunnel --accept-server-license-terms --name "${TUNNEL_NAME}"
