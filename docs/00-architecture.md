# Architecture & Decisions

## Hardware

- ThinkPad T480, running headless (lid closed, external power)
- Intel UHD 620 iGPU — usable for light hardware-accelerated video transcoding
  (Jellyfin), not much else
- Internal storage is the OS + Docker volumes; plan on at least one external USB drive
  for backups, and ideally a second (or a large enough single drive, partitioned) for
  the Jellyfin media library

## Decisions and rationale

| Area | Choice | Rationale |
|---|---|---|
| Base OS | Debian 12 (minimal, no desktop) | Stable, headless-friendly, keeps the lab separate from the Omarchy workstation |
| Remote access | Tailscale + SSH (keys only) | No port forwarding, nothing exposed to the open internet |
| Containers | Docker + Docker Compose | Foundation for nearly all workloads |
| Reverse proxy | Traefik | Docker-label-based service discovery — deliberately chosen over the simpler Caddy for the extra Docker practice it gives (reading/writing Compose labels, shared networks, live service discovery) |
| Observability | Prometheus, Grafana, node_exporter, cAdvisor, Loki | Canonical DevOps stack; Loki added in phase 10 for log aggregation |
| Kubernetes | k3s (deliberately last) | Lightweight, full K8s API on a single machine; delayed until Compose is second nature |
| Obsidian sync | Gitea + Obsidian Git plugin | More educational than Syncthing — real git workflow, self-hosted, no cloud dependency |
| Media server | Jellyfin | Fully open-source and self-hosted; no account or cloud dependency, unlike Plex, which stays consistent with the Tailscale-only / nothing-exposed approach |
| Dev environment | tmux + neovim over SSH, plus optional code-server | Terminal workflow matches existing CLI comfort; code-server available behind Traefik when a browser GUI is preferred |
| Backups | restic → external USB drive | Simple, free, local; accepted as not-offsite for now, with cloud (e.g. Backblaze B2) as a documented future upgrade |

## Network / access model

```
                          ┌─────────────────────────────┐
  Omarchy laptop  ───┐    │        ThinkPad T480          │
  Phone            ──┼──► │  (Debian 12, headless)        │
  (via Tailscale)    │    │                                │
                      │    │  Tailscale (tailscale0) ◄──── only interface UFW trusts widely
                      │    │       │                        │
                      │    │       ▼                        │
                      │    │  sshd (key-only)                │
                      │    │  Traefik :80 ──► grafana.homelab, gitea.homelab, │
                      │    │                   jellyfin.homelab, code.homelab │
                      │    │  Docker network(s) for each Compose stack       │
                      └───►│  UFW: LAN SSH fallback on the physical subnet   │
                          └─────────────────────────────┘
```

- Tailscale is the only way in from outside the LAN; MagicDNS gives you the `homelab`
  hostname.
- UFW trusts `tailscale0` broadly and allows SSH from the LAN subnet as a physical-access
  fallback if Tailscale ever breaks — see `phases/06-firewall.md`.
- Traefik terminates HTTP for all web UIs and routes by hostname
  (`grafana.homelab`, etc.). Hostname resolution for those is via `/etc/hosts` entries on
  admin machines (see `phases/11-reverse-proxy-traefik.md`) — there's no internal DNS
  server yet, so this doesn't extend automatically to the phone. Adding something like
  Pi-hole for real internal DNS is a good future project, not covered here.

## Directory layout on the lab machine

```
~/homelab/
  monitoring/   → stacks/monitoring/docker-compose.yml
  gitea/        → stacks/gitea/docker-compose.yml
  portainer/    → stacks/portainer-dozzle/docker-compose.yml
  traefik/      → stacks/traefik/docker-compose.yml
  jellyfin/     → stacks/jellyfin/docker-compose.yml
  code-server/  → stacks/code-server/docker-compose.yml
  obsidian/     → vault clone (see phase 09)
```

Each subdirectory holds its own `docker-compose.yml` (copied from this repo's
`stacks/`) plus any bind-mounted config/data — which is exactly what
`scripts/restic-backup.sh` backs up.
