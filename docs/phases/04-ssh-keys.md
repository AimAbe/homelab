# Phase 4 — SSH Keys, Hardened sshd, Client Shortcut

## Goal

Key-only SSH access from the Omarchy laptop, with password auth disabled on the lab
machine.

## Prerequisites

- Phase 3 done
- **Keep your current SSH session to the lab open for all of this phase** — don't close
  it until a brand-new connection with the new setup succeeds.

## Steps

1. On the Omarchy laptop, generate a key if you don't already have one for this purpose:
   ```
   ssh-keygen -t ed25519 -C "omarchy-to-homelab" -f ~/.ssh/homelab_ed25519
   ```
2. Copy the public key to the lab machine:
   ```
   ssh-copy-id -i ~/.ssh/homelab_ed25519.pub <user>@<lab-ip>
   ```
3. **In a new terminal** (keep the old session open), confirm key-based login works:
   ```
   ssh -i ~/.ssh/homelab_ed25519 <user>@<lab-ip>
   ```
4. Only after step 3 succeeds, harden `sshd_config` on the lab machine
   (`/etc/ssh/sshd_config`):
   ```
   PasswordAuthentication no
   PermitRootLogin no
   ```
5. Restart sshd:
   ```
   sudo systemctl restart ssh
   ```
6. **In yet another new terminal**, verify you can still log in with the key before
   closing your original session. If this fails, use the still-open original session to
   revert the config.
7. On the Omarchy laptop, add a shortcut to `~/.ssh/config`:
   ```
   Host homelab
       HostName <lab-ip-or-tailscale-name-later>
       User <user>
       IdentityFile ~/.ssh/homelab_ed25519
   ```
   Now `ssh homelab` just works.

## Verification

- `ssh homelab` logs in without a password prompt.
- `ssh -o PasswordAuthentication=yes <user>@<lab-ip>` is refused (password auth is off).

## Troubleshooting

- **Locked out after restarting sshd**: this is exactly why the original session stays
  open — use it to fix `sshd_config` and `sudo systemctl restart ssh` again.
- **`ssh-copy-id` not found on Omarchy/Arch**: it's in the `openssh` package, which
  should already be installed; otherwise copy the `.pub` file's contents manually into
  `~/.ssh/authorized_keys` on the lab machine.
