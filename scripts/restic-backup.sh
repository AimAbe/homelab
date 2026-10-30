#!/usr/bin/env bash
# Nightly restic backup of the homelab's Compose config/data directories to an
# external USB drive. Installed as a systemd timer — see docs/phases/10-*.md.
set -euo pipefail

# Mount point of the external backup drive (see phase 10 for fstab/mount setup).
export RESTIC_REPOSITORY="/mnt/backup/restic-repo"
export RESTIC_PASSWORD_FILE="$HOME/.restic-password"

# Paperless (phase 19): export documents + metadata to a consistent, restorable
# snapshot first. Backing up a live Postgres data dir isn't reliably restorable, so
# the export is what actually gets backed up for Paperless.
if [ -f "$HOME/homelab/paperless/docker-compose.yml" ]; then
  docker compose -f "$HOME/homelab/paperless/docker-compose.yml" \
    exec -T webserver document_exporter ../export
fi

# What to back up: bind-mounted config/data under ~/homelab, plus the Obsidian
# vault clone. Prometheus's own TSDB is excluded — it's high-churn and fully
# regenerable by just re-scraping, not worth the backup size/time.
BACKUP_PATHS=(
  "$HOME/homelab/gitea"
  "$HOME/homelab/monitoring"
  "$HOME/homelab/traefik"
  "$HOME/homelab/jellyfin"
  "$HOME/homelab/code-server"
  "$HOME/homelab/obsidian"
  # Added with phases 15–19 (missing directories are skipped):
  "$HOME/homelab/adguard"
  "$HOME/homelab/homepage"
  "$HOME/homelab/ntfy"
  "$HOME/homelab/diun"
  "$HOME/homelab/paperless"
)

EXISTING_PATHS=()
for p in "${BACKUP_PATHS[@]}"; do
  [ -e "$p" ] && EXISTING_PATHS+=("$p")
done

EXCLUDES=(
  --exclude "*/prometheus-data/*"
  --exclude "*/grafana-data/*"
  --exclude "*/paperless/pgdata"     # covered by the export above
  --exclude "*/paperless/redisdata"  # queue only, regenerable
  --exclude "*/ntfy/cache"           # message cache, regenerable
)

restic backup "${EXISTING_PATHS[@]}" "${EXCLUDES[@]}"

# Retention: keep a week of dailies, a month of weeklies, half a year of monthlies.
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
