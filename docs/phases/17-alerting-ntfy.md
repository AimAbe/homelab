# Phase 17 — Alerting: Alertmanager + ntfy

## Goal

The lab tells you when something's wrong, without you having to go look. Prometheus
evaluates alert rules, Alertmanager groups and routes them, and ntfy pushes them to
your phone. Tapping a notification opens that alert's runbook. This is the same
pipeline an on-call SRE works with, at lab scale.

```
Prometheus (alerts.yml) ──► Alertmanager ──► alertmanager-ntfy ──► ntfy ──► phone app
                                                                     ▲
                                              Diun (phase 18) ───────┘
```

## Prerequisites

- Phase 8 (monitoring) and phase 15 (AdGuard, so the phone can resolve `ntfy.homelab`)
- The ntfy app on your phone (Android: F-Droid or Play Store; iOS: App Store)

## Steps

### 1. ntfy server

```
scp -r stacks/ntfy homelab:~/homelab/
ssh homelab
cd ~/homelab/ntfy
```
**iPhone users:** uncomment `upstream-base-url` in `server.yml` first (the comment
there explains why). Then:
```
docker compose up -d
# Your account (phone + browser), full access:
docker exec -it ntfy ntfy user add --role=admin aimen
# A publish-only account for Alertmanager and Diun:
docker exec -it ntfy ntfy user add bot
docker exec ntfy ntfy access bot 'homelab-*' write-only
docker exec ntfy ntfy token add bot      # copy the tk_... token
```
In the phone app: Settings → add server `http://ntfy.homelab` with your `aimen` login.
Then subscribe to `homelab-alerts` and `homelab-updates`.

### 2. Alertmanager + bridge

The repo's monitoring stack now includes Alertmanager, the alertmanager-ntfy bridge,
alert rules, and one fix. node-exporter gets `--path.rootfs` so disk metrics reflect
the host.
```
scp -r stacks/monitoring homelab:~/homelab/
ssh homelab
cd ~/homelab/monitoring
openssl rand -base64 24 > webhook-password && chmod 600 webhook-password
cp alertmanager-ntfy-auth.example.yml alertmanager-ntfy-auth.yml
chmod 600 alertmanager-ntfy-auth.yml
vim alertmanager-ntfy-auth.yml   # paste webhook-password's contents + the bot token
docker compose up -d
```

### 3. Read the rules and runbooks

Go through `stacks/monitoring/alerts.yml` and `docs/runbooks.md` side by side. Every
alert should answer "what do I do when this fires?" If one doesn't, fix the rule or
the runbook. Tune thresholds to what's actually normal for the T480. Check Grafana
for a week first.

## Verification

- `http://alerts.homelab` loads. In Prometheus (via Grafana Explore or
  `docker exec prometheus wget -qO- localhost:9090/api/v1/rules`) the rules show as
  loaded.
- **Test notification end to end:**
  ```
  docker exec alertmanager amtool alert add TestAlert severity=warning \
    --annotation=summary="Test alert from the lab" \
    --annotation=runbook_url="https://github.com/AimAbe/homelab/blob/main/docs/runbooks.md" \
    --alertmanager.url=http://localhost:9093
  ```
  Your phone buzzes within about 30s (`group_wait`). Tapping it opens the runbooks
  page.
- **Real drill:** `docker stop jellyfin`. About 2–7 minutes later you get
  *Container jellyfin is not running*. `docker start jellyfin` sends *Resolved:*.

## Troubleshooting

- **amtool alert shows in Alertmanager but no push arrives:** `docker logs
  alertmanager-ntfy`. A 401 or 403 from ntfy means the bot token or its `homelab-*`
  access is wrong. A 401 from Alertmanager's side means `webhook-password` and the
  auth file don't match.
- **Notification arrives on desktop but not on the phone:** Android: in the ntfy app,
  allow background usage / disable battery optimization. iOS: set
  `upstream-base-url` (step 1). If the iOS app refuses a plain-`http` server, use
  `tailscale serve` to put ntfy behind HTTPS on your `*.ts.net` name.
- **Disk alerts show container paths or nothing:** make sure the node-exporter change
  (`--path.rootfs=/rootfs`) is deployed.
- **The container-missing alert takes ~7 minutes:** expected. Prometheus keeps a
  series for 5 minutes after it disappears, then the rule's `for: 2m` applies.
