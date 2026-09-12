# Phase 8 — Prometheus + Grafana + Exporters

## Goal

The canonical DevOps observability stack, running locally and reachable at
`http://homelab:3000` — this delivers the guide's headline milestone.

## Prerequisites

- Phase 7 done

## Steps

1. Copy the stack to the lab machine:
   ```
   scp -r stacks/monitoring homelab:~/homelab/
   ```
   (or `git clone` this repo onto the lab machine directly and work from there — either
   is fine; a clone makes it easier to `git pull` future updates to the guide/stacks.)
2. Create the shared networks referenced by the compose file — safe to run even before
   Traefik (phase 11) or Loki (phase 10) exist, they're just empty Docker networks until
   then:
   ```
   docker network create proxy
   docker network create monitoring
   ```
3. Bring the stack up:
   ```
   cd ~/homelab/monitoring
   docker compose up -d
   ```
4. Log into Grafana at `http://homelab:3000` (default `admin`/`admin`, change it when
   prompted).
5. Add Prometheus as a data source: Connections → Data sources → Add data source →
   Prometheus. **URL must be `http://prometheus:9090`** (the Docker service name) — not
   `localhost`, which is the single most common mistake here (see
   `docs/troubleshooting.md`).
6. Import dashboards by ID (Dashboards → New → Import):
   - **1860** — Node Exporter Full
   - **193** or **14282** — Docker/cAdvisor container metrics (try 14282 first; fall
     back to 193 if it doesn't fit your Grafana version)

## Verification

- **Off your home Wi-Fi** (phone hotspot), load `http://homelab:3000` and see Grafana
  render — this is the plan's original milestone.
- The Node Exporter Full dashboard shows live CPU/memory/disk graphs for the lab
  machine.
- The container dashboard shows Docker container-level metrics.

## Troubleshooting

- **"No data" in every panel**: almost always the data source URL — see
  `docs/troubleshooting.md`.
- **cAdvisor container won't start / permission errors**: cAdvisor needs read access to
  `/var/lib/docker` and `/sys` as mounted in the compose file — confirm those paths
  exist and aren't restricted by anything unusual in your setup.
- **Dashboard import fails for the ID given**: dashboard IDs occasionally get replaced;
  search grafana.com/grafana/dashboards for "Node Exporter Full" or "cAdvisor" directly
  if 1860/193/14282 stop working.
