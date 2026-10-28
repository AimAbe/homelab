# ThinkPad T480 Homelab

A headless home lab built on a repurposed ThinkPad T480, accessible remotely over
Tailscale via CLI and web UIs — no port forwarding, nothing exposed to the open
internet.

Nothing has been built yet. This repo is the runbook: follow the phases in order,
check off milestones as you go, and keep this repo updated (commit as you complete
each phase) so it doubles as a record of what's actually running on the machine.

## Goals

- Docker / container practice
- Kubernetes learning (k3s, later — deliberately last)
- Observability & DevOps practice (Prometheus + Grafana)
- Self-hosted apps
- A coding/dev environment reachable over SSH
- Media server (Jellyfin)
- Remote access to an Obsidian vault

## Architecture at a glance

See [`docs/00-architecture.md`](docs/00-architecture.md) for the full decisions table
and rationale. Short version:

| Layer | Choice |
|---|---|
| Base OS | Debian 12, minimal, no desktop |
| Remote access | Tailscale + SSH (keys only) |
| Containers | Docker + Docker Compose |
| Reverse proxy | Traefik |
| Observability | Prometheus, Grafana, node_exporter, cAdvisor, Loki |
| Obsidian sync | Gitea + Obsidian Git plugin |
| Media | Jellyfin |
| Dev environment | tmux + neovim over SSH, plus code-server |
| Backups | restic → external USB drive |
| Kubernetes | k3s (after a month+ of Compose-only operation) |

## How to use this repo

1. Work through `docs/phases/` in numeric order — each phase is Goal → Prerequisites →
   Steps → Verification → Troubleshooting.
2. Follow the suggested cadence in [`docs/pacing-schedule.md`](docs/pacing-schedule.md)
   rather than rushing — especially don't jump to k3s (phase 14) early.
3. Compose stacks referenced by the phase docs live in `stacks/<name>/docker-compose.yml`
   — copy each to the lab machine (e.g. `~/homelab/<name>/`) when you reach that phase.
4. Hit a snag? Check [`docs/troubleshooting.md`](docs/troubleshooting.md) first.

## Future projects

Not part of the phase plan yet — pick these up after the Compose consolidation stretch.

- **homelab-agent** — a phone-accessible conversational AI agent backed by an MCP
  server on the lab. Plan: [`docs/future/homelab-agent.md`](docs/future/homelab-agent.md);
  starter stack: [`stacks/homelab-agent/`](stacks/homelab-agent/).

## The milestone

Get off your home Wi-Fi (e.g. use a phone hotspot) and load `http://homelab:3000` (or,
once phase 11 is done, `http://grafana.homelab`). If Grafana renders, you have a
genuinely remote-accessible lab.

## Caveat

These docs describe a common home-lab architecture and starter configs, refined through
conversation with Claude — not vetted by an infrastructure professional. Cross-check
version-sensitive install steps (Tailscale, Docker, k3s, Traefik, Helm charts) against
current official docs before running them, since commands and recommended practices
change over time.
