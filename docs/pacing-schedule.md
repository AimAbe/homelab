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
| 5 | **Phase 21 — Oracle 19c lab, O0:** VT-x in BIOS, KVM/libvirt, Oracle Linux 8 VM, preinstall RPM | `ssh ol8` works; 19c zip staged in the VM |
| 6 | Phase 21, O1: install 19c, DBCA (CDB + PDB), listener, tnsnames, sample schemas | **SQL Developer on the laptop connects over the SSH tunnel, off Wi-Fi** |
| 7 | Phase 21, O2–O3: instance startup/shutdown stages, SPFILE/PFILE, alert log; multitenant | Unplug a PDB and plug it back in |
| 8 | Phase 21, O4: users, roles, profiles, unified auditing | Least-privilege reporting account works; audit trail shows its logins |
| 9 | Phase 21, O5: tablespaces and data files | Tablespace-usage script committed to `oracle/sql/` |
| 10–11 | Phase 21, O6: schema objects, SQL, PL/SQL (weekday evenings too) | 100+ queries and a working PL/SQL package |
| 12–13 | Phase 21, O7: RMAN — backups, then the recovery drills | **Full database restored from backup, from scratch** |
| 14 | Phase 21, O8: execution plans, stats, AWR/ASH, blocking sessions | A slow query fixed with an index, proven with plan output |
| 15 | Phase 21, O9: OPatch, a Release Update if you can get MOS access | `opatch lsinventory` and `DBA_REGISTRY_SQLPATCH` show the patch |
| 16–17 | Phase 8: Prometheus + Grafana + exporters stack | **Load `http://homelab:3000` off Wi-Fi — the original milestone** |
| 18 | Phase 9: Gitea + Obsidian Git sync | Vault pushes and pulls cleanly between Obsidian and the lab |
| 19 | Phase 11: Traefik reverse proxy in front of Grafana + Gitea | `grafana.homelab` resolves and works from the admin laptop |
| 20 | Phase 12: Jellyfin behind Traefik | A test video streams remotely over Tailscale |
| 21 | Phase 13: tmux/neovim workflow + code-server behind Traefik | Comfortable editing lab configs both over plain SSH and in the browser |
| 22 | Phase 10: Portainer, Dozzle, restic backups to USB, Loki | First successful `restic snapshots` listing; logs visible in Loki/Grafana |
| 23 | Phase 15: AdGuard Home | **`grafana.homelab` loads on your phone, off Wi-Fi** — `/etc/hosts` entries deleted |
| 24 | Phase 17: Alertmanager + ntfy, read through the runbooks | `docker stop jellyfin` buzzes your phone; starting it sends "Resolved" |
| 25 | Phase 16: Homepage + phase 18: Diun | `home.homelab` pinned to your phone; first Saturday update notification arrives |
| 26 | Phase 19: Paperless-ngx | A scanned document is searchable, and shows up in `restic ls latest` |
| 27–30 | **Compose consolidation month(s)** — no new services. Break things on purpose and fix them *using the alerts and runbooks*, practice day-to-day `docker compose` operations, do the weekly Diun update routine, tune Grafana dashboards and alert thresholds, restore a backup as a drill. **Capstone: phase 20 — codify it all in Ansible, then do the rebuild drill** | Playbook second run reports `changed=0`; lab rebuilt from scratch with Ansible + restic |
| 31+ | Phase 14: k3s, kubectl, Helm, kube-prometheus-stack | First `kubectl get nodes` over Tailscale |

Notes:

- **Weekends 5–15 (phase 21, Oracle 19c lab) were added to prepare for an Oracle DBA
  role, and deliberately come first.** No new homelab services during that stretch;
  the homelab resumes at phase 8 on weekend 16. The Oracle VM takes 8 GB of RAM while
  running, so shut it down when you're not studying. When you reach phases 8, 10, 17
  and 20, see "Later phases that build on this" in `phases/21-oracle-19c-lab.md`.

- Weekends 19–21 (Traefik, Jellyfin, dev environment) are new additions versus the
  original plan — they exist specifically to give more Docker Compose reps before the
  "consolidation month," since more comfort with Compose was an explicit goal.
- Weekends 23–26 (AdGuard, alerting, Homepage/Diun, Paperless) were added later as
  phases 15–19. AdGuard comes first because everything after it uses `*.homelab` on
  the phone; alerting comes next because every service after it is then monitored.
- The consolidation stretch (27–30) is intentionally open-ended. A good signal you're
  ready for phase 14 is being able to add or change a service, verify it in Grafana/Loki,
  and back it up — all without looking anything up — and having rebuilt the lab once
  with Ansible (phase 20).
- During consolidation, also decide how to approach Kubernetes (laptop sandbox,
  k3s alongside Compose, or phase 14 as written). See
  `future/kubernetes-options.md`.
- k3s and the Docker stacks will contend for ports 80/443/3000 on the same machine —
  when you get to phase 14, expect to either stop the Docker stacks that use those ports
  or reassign them. Covered in `phases/14-k3s.md`.
