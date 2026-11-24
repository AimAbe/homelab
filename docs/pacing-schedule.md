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
| 5 | **Phase 21 — Oracle 19c lab, O0–O1:** VT-x, KVM, Oracle Linux 8 VM, 19c install, Oracle Net | Database up, `lsnrctl status` clean, **`post-install` snapshot taken** |
| 6 | Phase 21, O2–O3: instance lifecycle, data dictionary, multitenant | Unplug a PDB and plug it back in |
| 7 | Phase 21, O4–O5: security, storage, undo | Tablespace-usage script committed to `oracle/sql/` |
| 8–9 | Phase 21, O6 + O6b: SQL, PL/SQL, Data Pump, SQL\*Loader (any gap, all week) | Every O6 topic ticked; a Data Pump `REMAP_SCHEMA` import works |
| 10 | Phase 21, O7: RMAN, then the recovery drills | **Full database restored from backup, from scratch** — the week that matters most |
| 11 | Phase 21, O8 + O11: tuning; exporter, Prometheus, Grafana | A slow query fixed with an index; the tablespace alert fires and clears |
| 12 | Phase 21, O9 + start O10: OPatch checks and patching runbook; build the standby | `DGMGRL> SHOW CONFIGURATION` reports `SUCCESS` |
| 13 | Phase 21, O10 finish; **sit 1Z0-082** | Switchover done and reversed |
| 14–15 | Phase 8: Prometheus + Grafana + exporters stack | **Load `http://homelab:3000` off Wi-Fi — the original milestone** |
| 16 | Phase 9: Gitea + Obsidian Git sync | Vault pushes and pulls cleanly between Obsidian and the lab |
| 17 | Phase 11: Traefik reverse proxy in front of Grafana + Gitea | `grafana.homelab` resolves and works from the admin laptop |
| 18 | Phase 12: Jellyfin behind Traefik | A test video streams remotely over Tailscale |
| 19 | Phase 13: tmux/neovim workflow + code-server behind Traefik | Comfortable editing lab configs both over plain SSH and in the browser |
| 20 | Phase 10: Portainer, Dozzle, restic backups to USB, Loki | First successful `restic snapshots` listing; logs visible in Loki/Grafana |
| 21 | Phase 15: AdGuard Home | **`grafana.homelab` loads on your phone, off Wi-Fi** — `/etc/hosts` entries deleted |
| 22 | Phase 17: Alertmanager + ntfy, read through the runbooks | `docker stop jellyfin` buzzes your phone; starting it sends "Resolved" |
| 23 | Phase 16: Homepage + phase 18: Diun | `home.homelab` pinned to your phone; first Saturday update notification arrives |
| 24 | Phase 19: Paperless-ngx | A scanned document is searchable, and shows up in `restic ls latest` |
| 25–28 | **Compose consolidation month(s)** — no new services. Break things on purpose and fix them *using the alerts and runbooks*, practice day-to-day `docker compose` operations, do the weekly Diun update routine, tune Grafana dashboards and alert thresholds, restore a backup as a drill. **Capstone: phase 20 — codify it all in Ansible, then do the rebuild drill** | Playbook second run reports `changed=0`; lab rebuilt from scratch with Ansible + restic |
| 29+ | Phase 14: k3s, kubectl, Helm, kube-prometheus-stack | First `kubectl get nodes` over Tailscale |

Notes:

- **Weekends 5–13 (phase 21, Oracle 19c lab) were added to prepare for an Oracle DBA
  role and the 1Z0-082 exam, and deliberately come first.** They're weeks, not just
  weekends: the long-block sections (O0, O1, O7, O9, O10) go on weekends, the rest fits
  weekday evenings, and the SQL in O6/O6b fits any gap. Book the exam for week 13
  before you start. No new homelab services during this stretch; the homelab resumes
  at phase 8 on weekend 14 (retire the O11 mini-stack then). Shut the Oracle VM down
  when you're not studying — it takes 8 GB of RAM.
- Weekends 17–19 (Traefik, Jellyfin, dev environment) are new additions versus the
  original plan — they exist specifically to give more Docker Compose reps before the
  "consolidation month," since more comfort with Compose was an explicit goal.
- Weekends 21–24 (AdGuard, alerting, Homepage/Diun, Paperless) were added later as
  phases 15–19. AdGuard comes first because everything after it uses `*.homelab` on
  the phone; alerting comes next because every service after it is then monitored.
- The consolidation stretch (25–28) is intentionally open-ended. A good signal you're
  ready for phase 14 is being able to add or change a service, verify it in Grafana/Loki,
  and back it up — all without looking anything up — and having rebuilt the lab once
  with Ansible (phase 20).
- During consolidation, also decide how to approach Kubernetes (laptop sandbox,
  k3s alongside Compose, or phase 14 as written). See
  `future/kubernetes-options.md`.
- k3s and the Docker stacks will contend for ports 80/443/3000 on the same machine —
  when you get to phase 14, expect to either stop the Docker stacks that use those ports
  or reassign them. Covered in `phases/14-k3s.md`.
