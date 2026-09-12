#!/usr/bin/env bash
# Nightly restic backup of the homelab's Compose config/data directories to an
# external USB drive. Installed as a systemd timer — see docs/phases/10-*.md.
set -euo pipefail

# Mount point of the external backup drive (see phase 10 for fstab/mount setup).
export RESTIC_REPOSITORY="/mnt/backup/restic-repo"
export RESTIC_PASSWORD_FILE="$HOME/.restic-password"

# What to back up: bind-mounted config/data under ~/homelab, plus the Obsidian
# vault clone. Prometheus's own TSDB is excluded — it's high-churn and fully
# regenerable by just re-scraping, not worth the backup size/time.
BACKUP_PATHS=(
  "$HOME/homelab/gitea"
  "$HOME/homelab/monitoring/prometheus.yml"
  "$HOME/homelab/traefik"
  "$HOME/homelab/jellyfin"
  "$HOME/homelab/code-server"
  "$HOME/homelab/obsidian"
)

EXCLUDES=(
  --exclude "*/prometheus-data/*"
  --exclude "*/grafana-data/*"
)

restic backup "${BACKUP_PATHS[@]}" "${EXCLUDES[@]}"

# Retention: keep a week of dailies, a month of weeklies, half a year of monthlies.
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
