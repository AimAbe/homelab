# Phase 11 — Reverse Proxy (Traefik)

Per `docs/pacing-schedule.md`, do this after phase 8 (monitoring) and phase 9 (Gitea) so
there are already a couple of real services to route to.

## Goal

Friendly hostnames (`grafana.homelab`, `gitea.homelab`, etc.) instead of remembering
port numbers, using Traefik's Docker-label-based service discovery — chosen over the
simpler Caddy specifically because working with it means writing and reading Compose
labels and shared Docker networks, which is direct Docker practice.

## Prerequisites

- Phase 8 and phase 9 done (something to route to)
- The `proxy` network already exists (created in phase 8 step 2); if you skipped that,
  run `docker network create proxy` first

## How it works

Every stack's compose file in this repo already has `proxy` as a network and a
`labels:` block like:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.grafana.rule=Host(`grafana.homelab`)"
  - "traefik.http.services.grafana.loadbalancer.server.port=3000"
```
Traefik watches the Docker socket, sees any container with `traefik.enable=true` on a
network it shares, and wires up routing automatically — no Traefik-side config file to
maintain per service.

## Steps

1. Copy and start Traefik:
   ```
   scp -r stacks/traefik homelab:~/homelab/
   ssh homelab 'cd ~/homelab/traefik && docker compose up -d'
   ```
2. Restart the other stacks so they pick up the `proxy` network and labels if they were
   started before Traefik existed:
   ```
   ssh homelab 'cd ~/homelab/monitoring && docker compose up -d'
   ssh homelab 'cd ~/homelab/gitea && docker compose up -d'
   ```
3. Visit `http://homelab:8080` — Traefik's own dashboard — and confirm `grafana` and
   `gitea` routers appear.
4. **DNS resolution caveat**: Tailscale MagicDNS gives you the single hostname
   `homelab`, not subdomains of it. To make `grafana.homelab` actually resolve from the
   Omarchy laptop, add entries to `/etc/hosts` there:
   ```
   <tailscale-ip-of-homelab>  grafana.homelab gitea.homelab portainer.homelab dozzle.homelab jellyfin.homelab code.homelab
   ```
   Find the Tailscale IP with `tailscale ip -4` on the lab machine. This only affects
   the machine whose `/etc/hosts` you edited — your phone will keep using
   `http://homelab:<port>` for each service until a real internal DNS server (e.g.
   Pi-hole) is added, which is a good future project but out of scope here.

## Verification

- `http://grafana.homelab` and `http://gitea.homelab` load from the Omarchy laptop.
- The Traefik dashboard (`http://homelab:8080`) lists a router and service for each
  labeled container.

## Troubleshooting

- **Hostname doesn't resolve**: confirm the `/etc/hosts` entry and that you're using the
  lab's *Tailscale* IP, not its LAN IP (unless you're testing from the same LAN).
- **404 or "no route" from Traefik**: check the label syntax with
  `docker logs traefik` — a typo in a `Host()` rule is the most common cause.
- **Two services fight over the same hostname**: each `Host()` rule must be unique;
  duplicate rules mean only one router wins unpredictably.
