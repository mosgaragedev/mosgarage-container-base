#!/usr/bin/env bash
# =============================================================================
# workspace-start — entrypoint/C​MD for the code-server target
#
# Prepares the code-server configuration, optionally clones a project, then
# hands the container over to supervisord (code-server + sshd + cron).
#
#   CODE_SERVER_PASSWORD   fixed IDE password (generated when unset)
#   MOSGARAGE_GIT_REPO     repository to clone into ~/workspace
#   GIT_BRANCH             branch for that clone (default main)
# =============================================================================
set -euo pipefail

WORKSPACE_USER="${USERNAME:-mosgarage}"
HOME_DIR="/home/${WORKSPACE_USER}"
LOG_DIR="/var/log/mosgarage"
CONF_DIR="${HOME_DIR}/.config/code-server"
CONF_FILE="${CONF_DIR}/config.yaml"

log() {
  printf '%s [workspace-start] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

mkdir -p "${HOME_DIR}/workspace" "${CONF_DIR}" \
         "${HOME_DIR}/.local/share/code-server" "${LOG_DIR}"

# ── code-server configuration ─────────────────────────────────────────────────
if [[ ! -s "${CONF_FILE}" ]]; then
  if [[ -n "${CODE_SERVER_PASSWORD:-}" ]]; then
    PASSWORD="${CODE_SERVER_PASSWORD}"
  else
    PASSWORD="$(head -c 32 /dev/urandom | base64 | tr -d '/+=' | cut -c1-24)"
    log "generated code-server password: ${PASSWORD}"
  fi

  cat > "${CONF_FILE}" <<EOF
bind-addr: 0.0.0.0:8080
auth: password
password: ${PASSWORD}
cert: false
user-data-dir: ${HOME_DIR}/.local/share/code-server
extensions-dir: ${HOME_DIR}/.local/share/code-server/extensions
EOF
fi

chown -R "${WORKSPACE_USER}:${WORKSPACE_USER}" \
      "${CONF_DIR}" "${HOME_DIR}/workspace" "${HOME_DIR}/.local/share"

# ── optional project clone ────────────────────────────────────────────────────
if [[ -n "${MOSGARAGE_GIT_REPO:-}" && ! -d "${HOME_DIR}/workspace/.git" ]]; then
  log "cloning ${MOSGARAGE_GIT_REPO} (${GIT_BRANCH:-main}) into ${HOME_DIR}/workspace"
  su -s /bin/bash "${WORKSPACE_USER}" -c \
     "git clone --branch '${GIT_BRANCH:-main}' --single-branch '${MOSGARAGE_GIT_REPO}' '${HOME_DIR}/workspace'" \
     || log "clone failed — starting with an empty workspace"
fi

# ── hourly-to-daily crontab is shipped by /etc/cron.d/mosgarage-backup ────────
if command -v /usr/local/bin/backup-workspace >/dev/null 2>&1; then
  log "backup worker available (cron.d/mosgarage-backup)"
fi

log "starting supervisord"
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/workspace.conf
