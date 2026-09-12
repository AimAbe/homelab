# restic One-Time Setup

Run this once, when the external backup drive is connected, before the nightly timer
(phase 10) has anything to run against.

1. Find and mount the external USB drive:
   ```
   lsblk
   sudo mkdir -p /mnt/backup
   sudo mount /dev/sdX1 /mnt/backup
   ```
   Add it to `/etc/fstab` for it to persist across reboots (use the drive's UUID via
   `blkid`, not `/dev/sdX1`, since device names can shift).
2. Install restic:
   ```
   sudo apt install -y restic
   ```
3. Pick a strong repository password and store it outside of git:
   ```
   echo "<a long random passphrase>" > ~/.restic-password
   chmod 600 ~/.restic-password
   ```
4. Initialize the repository:
   ```
   export RESTIC_REPOSITORY="/mnt/backup/restic-repo"
   export RESTIC_PASSWORD_FILE="$HOME/.restic-password"
   restic init
   ```
5. Do a manual first run of `scripts/restic-backup.sh` to confirm it works before
   automating it:
   ```
   ~/homelab-repo/scripts/restic-backup.sh
   restic snapshots
   ```

**Never commit `~/.restic-password` or the repo's actual data to git** — only the
script and these instructions belong in version control.
