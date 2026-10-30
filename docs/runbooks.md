# Runbooks

One section per alert in `stacks/monitoring/alerts.yml`. Tapping an ntfy alert opens
its section. Each one follows the same shape: **what it means → check → fix →
afterwards**. When an alert fires and the runbook didn't help, update it. That's the
habit worth building.

Handy everywhere: `http://home.homelab` (status), `http://dozzle.homelab` (logs),
`http://grafana.homelab` (history), `http://alerts.homelab` (silence an alert while
you work).

---

## TargetDown

**Means:** Prometheus can't scrape an exporter. You're blind to that part of the lab.

**Check:**
1. `docker ps -a --filter name=<job>` — is the exporter container running?
2. `docker logs <container> --tail 50`
3. If `job="node-exporter"` or `cadvisor` and the container is up: are they still on
   the `monitoring` network? `docker network inspect monitoring`

**Fix:** `cd ~/homelab/monitoring && docker compose up -d`. If it's restart-looping,
see [ContainerRestarting](#containerrestarting).

**Afterwards:** if you don't know why it stopped, look at `journalctl -u docker` around
the time it fired.

---

## DiskSpaceLow

**Means:** a filesystem is under 15% free (warning) or 5% (critical).

**Check:**
1. Which mount? It's in the alert (`/` or `/mnt/media`).
2. `/`: `docker system df`, then `sudo du -xh / --max-depth=2 | sort -h | tail -20`
3. `/mnt/media`: `du -sh /mnt/media/*`

**Fix (`/`):**
- `docker image prune -a` (removes images not used by any container)
- `docker builder prune`
- Check Loki/Prometheus retention if their volumes are large
- `sudo journalctl --vacuum-time=14d`

**Fix (`/mnt/media`):** delete or move media. That's a human decision.

**Afterwards:** if the same thing fills up again, add retention for it instead of
cleaning by hand.

---

## HighMemoryUsage

**Means:** over 90% of 16 GB in use for 10+ minutes. Swapping or the OOM killer may
follow.

**Check:**
1. Grafana → cAdvisor dashboard: which container grew?
2. `docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" | sort -k2 -h`
3. Usual suspects: Paperless during a big OCR batch, Jellyfin transcoding, k3s if it's
   running.

**Fix:** restart the offender (`docker restart <name>`). If it's expected load (an OCR
batch), let it finish. If it's chronic, add a `mem_limit` to that service.

**Afterwards:** check `dmesg | grep -i oom` to see whether anything was killed.

---

## HighCpuUsage

**Means:** CPU over 90% averaged for 15 minutes.

**Check:** `docker stats`, then `htop` on the host. Usually Jellyfin transcoding (is
QuickSync on? See phase 12) or Paperless OCR.

**Fix:** stop the runaway, or accept it if it's a known batch job. Repeated alerts
during normal Jellyfin use mean transcoding is falling back to CPU.

---

## HighTemperature

**Means:** a sensor has been above 85°C for 5 minutes. Laptops with the lid closed run
hot.

**Check:** `sensors` (package `lm-sensors`). Is CPU load also high?

**Fix:**
- Short-term: reduce load (see HighCpuUsage).
- Physical: make sure the vents aren't blocked. Stand the T480 on its edge or prop the
  back up. Clean the fan.
- If chronic: consider repasting the CPU (a common T480 fix).

---

## CriticalContainerMissing

**Means:** one of the containers everything depends on (traefik, adguard, jellyfin,
ntfy) isn't running.

**Check:**
1. `docker ps -a --filter name=<name>`: exited? Never created?
2. `docker logs <name> --tail 100`
3. Was it a deliberate `docker compose down`? Then silence the alert in Alertmanager
   next time *before* doing maintenance.

**Fix:** `cd ~/homelab/<stack> && docker compose up -d`, then confirm it in Homepage.

**Impact notes:**
- **adguard down** means DNS fails on every tailnet device. Fix this one first.
- **traefik down** means all `*.homelab` URLs fail, but direct ports
  (`homelab:3000`, `homelab:8080`) still work.
- **ntfy down** means *you won't get alerts at all*, including this one. Check Homepage
  occasionally.

---

## ContainerRestarting

**Means:** a container restarted more than twice in 15 minutes (crash loop).

**Check:** `docker logs <name> --tail 200`. The error just before each restart is the
answer, usually a bad config, a missing `.env` value, a full disk, or a dependency
(database) that isn't up.

**Fix:** fix the cause. Don't just keep restarting. If a recent update broke it,
roll back by pinning the previous image tag in the compose file.

**Afterwards:** if an update caused it, write that down in the Diun routine notes.
