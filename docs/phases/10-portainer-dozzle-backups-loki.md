# Phase 10 — Portainer, Dozzle, restic Backups, Loki

Per `docs/pacing-schedule.md`, this phase is suggested for **after** Traefik, Jellyfin,
and the dev environment (phases 11–13) — it's numbered 10 because it was in the original
plan, but the extra Compose-practice phases were deliberately inserted ahead of it.
Nothing here depends on 11–13 except the Traefik labels already in the compose files,
which are inert until Traefik exists.

## Goal

A container management UI (Portainer), a live log viewer (Dozzle), local backups
(restic to an external USB drive), and log aggregation (Loki + Promtail, queryable from
Grafana).

## Prerequisites

- Phase 7 done (Docker); phase 8 done if you want Loki wired into the same Grafana
- An external USB drive dedicated to backups (see `docs/00-architecture.md`)

## Steps

### Portainer + Dozzle

1. Copy and start the stack:
   ```
   scp -r stacks/portainer-dozzle homelab:~/homelab/
   ssh homelab 'cd ~/homelab/portainer-dozzle && docker compose up -d'
   ```
2. By the suggested pacing, Traefik (phase 11) already exists at this point, so both
   services are only reachable by hostname (no ports are published directly on the
   host in this stack's compose file) — visit `http://portainer.homelab` and complete
   the initial admin setup.
3. Dozzle needs no setup — visit `http://dozzle.homelab` to see live container logs.
   If you're doing phase 10 *before* Traefik for some reason, temporarily add a
   `ports:` mapping to each service in `stacks/portainer-dozzle/docker-compose.yml`
   (e.g. `"9000:9000"` and `"8080:8080"`) to reach them directly instead.

### restic backups

1. Follow `scripts/restic-init.md` once, in full, before anything else here.
2. Install the script and a systemd timer on the lab machine:
   ```
   mkdir -p ~/bin && cp scripts/restic-backup.sh ~/bin/
   ```
   Create `/etc/systemd/system/restic-backup.service`:
   ```ini
   [Unit]
   Description=restic backup of homelab config/data

   [Service]
   Type=oneshot
   ExecStart=/home/<user>/bin/restic-backup.sh
   User=<user>
   ```
   And `/etc/systemd/system/restic-backup.timer`:
   ```ini
   [Unit]
   Description=Nightly restic backup

   [Timer]
   OnCalendar=daily
   Persistent=true

   [Install]
   WantedBy=timers.target
   ```
   Then:
   ```
   sudo systemctl daemon-reload
   sudo systemctl enable --now restic-backup.timer
   ```

### Loki

1. Copy and start the stack (requires the `monitoring` network from phase 8):
   ```
   scp -r stacks/loki homelab:~/homelab/
   ssh homelab 'cd ~/homelab/loki && docker compose up -d'
   ```
2. In Grafana, add a Loki data source with URL `http://loki:3100` (same "service name,
   not localhost" rule as Prometheus — see `docs/troubleshooting.md`).
3. Explore logs via Grafana's "Explore" view, filtering by `{container="..."}`.

## Verification

- `http://portainer.homelab` and `http://dozzle.homelab` both load.
- `restic snapshots` (with the env vars from `scripts/restic-init.md` exported) lists at
  least one snapshot after a manual or timer-triggered run.
- `systemctl list-timers | grep restic` shows the next scheduled run.
- Grafana's Explore view returns log lines for a running container when queried by
  Loki.

## Troubleshooting

- **`restic backup` "repository already locked"**: see `docs/troubleshooting.md`.
- **Promtail shows no logs**: confirm it can reach `/var/run/docker.sock` (permissions)
  and that `loki:3100` resolves — both containers must be on the `monitoring` network.
- **Timer never fires**: `systemctl status restic-backup.timer` and
  `journalctl -u restic-backup.service` for the actual error.
