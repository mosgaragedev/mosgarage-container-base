#!/usr/bin/env bash
# =============================================================================
# backup-workspace — archive the workspace and shell/editor config
#
#   BACKUP_DIR              destination (default /workspaces/.mosgarage-backups)
#   BACKUP_RETENTION_DAYS   prune archives older than N days (default 7)
#   BACKUP_USER             owner of the archive (default mosgarage)
#
# Cron invokes this at 02:17 daily; see /etc/cron.d/mosgarage-backup.
# =============================================================================
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/workspaces/.mosgarage-backups}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
BACKUP_USER="${BACKUP_USER:-mosgarage}"
HOME_DIR="/home/${BACKUP_USER}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE="${BACKUP_DIR}/workspace-${STAMP}.tar.gz"

log() {
  printf '%s [backup-workspace] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

mkdir -p "${BACKUP_DIR}"

if [[ ! -d "${HOME_DIR}/workspace" ]]; then
  log "no workspace at ${HOME_DIR}/workspace — nothing to back up"
  exit 0
fi

# Paths that may legitimately disappear mid-run (editor temp files, sockets)
# must not fail the archive, hence --ignore-failed-read with a warning.
read -r -a SOURCES <<< "workspace .zshrc .zsh-aliases.zsh .p10k.zsh .bindkeys.zsh .config/code-server"

log "archiving ${HOME_DIR}/{${SOURCES[*]}} -> ${ARCHIVE}"
tar --create --gzip --ignore-failed-read --warning=no-file-changed \
    --file="${ARCHIVE}" \
    --directory="${HOME_DIR}" \
    "${SOURCES[@]}"

if ! tar --list --gzip --file="${ARCHIVE}" >/dev/null; then
  log "archive ${ARCHIVE} is unreadable — removing it"
  rm -f "${ARCHIVE}"
  exit 1
fi

if id "${BACKUP_USER}" >/dev/null 2>&1; then
  chown "${BACKUP_USER}:${BACKUP_USER}" "${ARCHIVE}"
fi

log "archive size: $(du -h "${ARCHIVE}" | cut -f1)"

# Retention: drop archives older than RETENTION_DAYS, always keep the newest one.
find "${BACKUP_DIR}" -maxdepth 1 -name 'workspace-*.tar.gz' -type f \
     -mtime "+${RETENTION_DAYS}" -print -delete | while read -r old; do
  log "pruned ${old}"
done

log "done"
