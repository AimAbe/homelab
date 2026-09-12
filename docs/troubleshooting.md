# Troubleshooting Quick Reference

| Symptom | Likely cause | Fix |
|---|---|---|
| Locked out of SSH after hardening `sshd_config` | Bad config pushed before verifying a new session | Never close your existing session until a *new* `ssh` connection succeeds. If locked out, physical access + keyboard is the recovery path. |
| `dd` wiped the wrong disk | Wrong device picked for the install USB | Always run `lsblk` immediately before `dd` and triple-check the target device name. |
| Machine sleeps/suspends when the lid is closed | Lid-suspend not disabled, or a sleep target isn't masked | Re-check `phases/03-post-install-hardening.md` — `logind.conf` `HandleLidSwitch=ignore` and `systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target`. |
| Can't reach the lab except on the home LAN | Tailscale not installed/authed on a device, or MagicDNS off | `tailscale status` on both ends; confirm MagicDNS is enabled in the Tailscale admin console. |
| SSH works over Tailscale but not LAN (or vice versa) | UFW rule doesn't match the actual subnet, or `tailscale0` isn't trusted | `ufw status verbose`; confirm the LAN rule matches your real subnet (`ip a` on the LAN interface) and that `tailscale0` has a broad allow rule. |
| Grafana shows "no data" for every panel | Data source URL wrong | Grafana's Prometheus data source must be `http://prometheus:9090` (the Docker service name), **not** `localhost` or `127.0.0.1`. |
| `docker compose up` can't reach another stack's container by name | Containers on different Docker networks | Either put both stacks on the same external network (see `stacks/traefik/docker-compose.yml` for the pattern) or use the full network alias. |
| Traefik dashboard shows a service but the hostname 404s / doesn't resolve | `/etc/hosts` not updated on the client, or a label typo | Confirm `/etc/hosts` on the machine you're browsing from has the hostname pointed at the lab's Tailscale IP; check `docker logs traefik` for label parse errors. |
| k3s and a Docker stack both fail to bind port 80/443 | Port contention between k3s's Traefik/ingress and the Compose Traefik, or Grafana vs. something else on 3000 | Stop the conflicting Compose stack before starting k3s workloads, or move one of them to a different port — decide explicitly, don't let it silently fail. |
| `restic backup` fails with "repository already locked" | A previous run crashed or is still running | `restic unlock` (only after confirming no other backup is genuinely in progress). |
| Jellyfin transcoding is slow / video stutters | UHD 620 hardware transcoding not enabled, or too many concurrent streams | Enable QuickSync in Jellyfin's playback settings; keep expectations modest — this is a laptop iGPU, not a NAS with a dedicated transcode chip. |
| Unattended-upgrades rebooted the box unexpectedly | Automatic reboot enabled for kernel updates | Check `/etc/apt/apt.conf.d/50unattended-upgrades` — either accept scheduled reboots or set a fixed reboot time you're prepared for. |

If something isn't covered here, check the specific phase doc's own "Troubleshooting"
section first — this table is for cross-cutting issues, not phase-specific detail.
