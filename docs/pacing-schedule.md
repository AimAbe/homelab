# Suggested Pacing Schedule

This assumes a couple of hours here and there plus a longer session on weekends. It's a
guide, not a deadline — the important rule is the last one: **don't rush to
Kubernetes.** Spend real time operating the Compose stack before touching k3s.

| Weekend | Focus | Milestone |
|---|---|---|
| 1 | Phase 0–2: backup/prep, BIOS settings, Debian 12 install | Machine boots headless, SSH reachable on the LAN |
| 2 | Phase 3–4: updates/toolkit/hardening basics, SSH keys + sshd hardening | Password auth disabled, key-only login working |
| 3 | Phase 5–6: Tailscale on lab + laptop + phone, UFW firewall | **Get off home Wi-Fi and `ssh homelab` over Tailscale** |
| 4 | Phase 7: Docker + Compose install, directory layout, free practice (`docker run`, images, volumes, networks) | Comfortable with basic Docker commands before stacking anything on top |
| 5–6 | Phase 8: Prometheus + Grafana + exporters stack | **Load `http://homelab:3000` off Wi-Fi — the original milestone** |
| 7 | Phase 9: Gitea + Obsidian Git sync | Vault pushes and pulls cleanly between Obsidian and the lab |
| 8 | Phase 11: Traefik reverse proxy in front of Grafana + Gitea | `grafana.homelab` resolves and works from the admin laptop |
| 9 | Phase 12: Jellyfin behind Traefik | A test video streams remotely over Tailscale |
| 10 | Phase 13: tmux/neovim workflow + code-server behind Traefik | Comfortable editing lab configs both over plain SSH and in the browser |
| 11 | Phase 10: Portainer, Dozzle, restic backups to USB, Loki | First successful `restic snapshots` listing; logs visible in Loki/Grafana |
| 12 | Phase 15: AdGuard Home | **`grafana.homelab` loads on your phone, off Wi-Fi** — `/etc/hosts` entries deleted |
| 13 | Phase 17: Alertmanager + ntfy, read through the runbooks | `docker stop jellyfin` buzzes your phone; starting it sends "Resolved" |
| 14 | Phase 16: Homepage + phase 18: Diun | `home.homelab` pinned to your phone; first Saturday update notification arrives |
| 15 | Phase 19: Paperless-ngx | A scanned document is searchable, and shows up in `restic ls latest` |
| 16–19 | **Compose consolidation month(s)** — no new services. Break things on purpose and fix them *using the alerts and runbooks*, practice day-to-day `docker compose` operations, do the weekly Diun update routine, tune Grafana dashboards and alert thresholds, restore a backup as a drill. **Capstone: phase 20 — codify it all in Ansible, then do the rebuild drill** | Playbook second run reports `changed=0`; lab rebuilt from scratch with Ansible + restic |
| 20+ | Phase 14: k3s, kubectl, Helm, kube-prometheus-stack | First `kubectl get nodes` over Tailscale |

Notes:

- Weekends 8–10 (Traefik, Jellyfin, dev environment) are new additions versus the
  original plan — they exist specifically to give more Docker Compose reps before the
  "consolidation month," since more comfort with Compose was an explicit goal.
- Weekends 12–15 (AdGuard, alerting, Homepage/Diun, Paperless) were added later as
  phases 15–19. AdGuard comes first because everything after it uses `*.homelab` on
  the phone; alerting comes next because every service after it is then monitored.
- The consolidation stretch (16–19) is intentionally open-ended. A good signal you're
  ready for phase 14 is being able to add or change a service, verify it in Grafana/Loki,
  and back it up — all without looking anything up — and having rebuilt the lab once
  with Ansible (phase 20).
- During consolidation, also decide how to approach Kubernetes (laptop sandbox,
  k3s alongside Compose, or phase 14 as written). See
  `future/kubernetes-options.md`.
- k3s and the Docker stacks will contend for ports 80/443/3000 on the same machine —
  when you get to phase 14, expect to either stop the Docker stacks that use those ports
  or reassign them. Covered in `phases/14-k3s.md`.
