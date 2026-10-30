# Phase 20 — Ansible (Infrastructure as Code)

## Goal

Turn this runbook into code. One command, `ansible-playbook site.yml`, brings a fresh
Debian install to the state phases 3–19 describe: patched, hardened, firewalled,
Docker installed, every stack deployed. The repo becomes the source of truth for the
lab, not just documentation of it.

This is the capstone of the Compose consolidation stretch. You've done each step by
hand, so now you can read every task and know exactly what it does.

## Prerequisites

- Phases 3–19 done by hand at least once
- Ansible on the **laptop** (the control node). Nothing extra is needed on the lab:
  ```
  sudo pacman -S ansible        # Omarchy/Arch; or: pipx install ansible
  cd ansible && ansible-galaxy collection install -r requirements.yml
  ```

## What's automated (and what isn't)

| Role | Mirrors | Notes |
|---|---|---|
| `base` | Phase 3 | Packages, unattended-upgrades, lid switch, masked sleep targets |
| `ssh` | Phase 4 | sshd drop-in (`sshd_config.d/10-homelab.conf`), validated before restart |
| `tailscale` | Phase 5 | Package only. `sudo tailscale up` login stays manual |
| `firewall` | Phase 6 | UFW defaults, `tailscale0`, LAN SSH fallback |
| `docker` | Phase 7 | Official Docker repo, Compose plugin, docker group |
| `stacks` | Phases 8–19 | Creates shared networks, checks secrets exist, copies `stacks/`, `docker compose up` |

Left manual on purpose: BIOS and OS install, SSH key creation, Tailscale login, restic
repo init, and creating secret files (`.env`, auth files). Secrets never go in git.

## Steps

1. Edit `ansible/group_vars/lab.yml`:
   - `lab_user`: your Debian username on the lab
   - `lan_subnet`: your real LAN subnet (same as phase 6)
   - `homelab_stacks`: comment out anything you haven't deployed
2. Test connectivity:
   ```
   cd ansible
   ansible lab -m ping
   ```
3. **Dry run first.** Always. It shows exactly what would change:
   ```
   ansible-playbook site.yml --check --diff --ask-become-pass
   ```
   On a machine you built by hand, this should show very few changes. Each change is
   either drift (something you did by hand differently) or a gap in the playbook.
   Investigate each one before running for real.
4. Apply:
   ```
   ansible-playbook site.yml --ask-become-pass
   ```
5. Run it again. The second run should report **`changed=0`**. That's idempotency, and
   it's the property that makes IaC trustworthy.
6. New workflow from now on: edit a compose file in the repo, commit, then
   `ansible-playbook site.yml --tags stacks`. No more `scp`.

## Verification

- A second run shows `changed=0`.
- **The real test (rebuild drill):** during the consolidation stretch, reinstall Debian
  on the T480 (or a VM). Do the manual bits (phases 1–2, keys, `tailscale up`), restore
  secrets and data from restic, run the playbook, and you're back. Time it. That number
  is a great résumé line.

## Troubleshooting

- **"Missing .../.env" assertion:** expected on a fresh machine. Create the file from
  its `*.example` (or restore it from restic) and re-run.
- **`--check` fails on the Docker tasks on a brand-new machine:** check mode can't
  install the Docker repo and then use it in the same dry run. Run the `docker` tag for
  real first, then check the rest.
- **Locked out after the firewall role:** `lan_subnet` was wrong. Recovery is the same
  as phase 6 (physical console, `sudo ufw disable`).
- **`ansible-lint`:** run it from `ansible/` before committing playbook changes. It
  catches most mistakes early, and it's a natural first job for Gitea Actions CI.
