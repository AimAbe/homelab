# Phase 3 — Updates, Toolkit, Unattended-Upgrades, Disable Lid-Suspend

## Goal

A patched, low-maintenance base system that won't fall asleep on you and won't silently
drift out of date.

## Prerequisites

- Phase 2 done, SSH access working (password auth for now)

## Steps

1. Update everything:
   ```
   sudo apt update && sudo apt full-upgrade -y
   ```
2. Install a basic toolkit:
   ```
   sudo apt install -y curl wget git vim htop tmux unzip ca-certificates gnupg lsb-release
   ```
3. Enable unattended security upgrades:
   ```
   sudo apt install -y unattended-upgrades apt-listchanges
   sudo dpkg-reconfigure -plow unattended-upgrades
   ```
   Review `/etc/apt/apt.conf.d/50unattended-upgrades` — decide deliberately whether
   automatic reboots for kernel updates are acceptable (see
   `docs/troubleshooting.md`).
4. Disable lid-suspend, since this runs headless with the lid closed:
   ```
   sudo sed -i 's/^#\?HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
   sudo sed -i 's/^#\?HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' /etc/systemd/logind.conf
   sudo systemctl restart systemd-logind
   ```
5. Mask sleep/suspend targets so nothing else can put it to sleep either:
   ```
   sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
   ```

## Verification

- Close the lid with the machine powered and plugged in — it stays up (`ssh` still
  works from another machine).
- `systemctl status sleep.target` shows `masked`.
- `sudo unattended-upgrade --dry-run --debug` runs without error.

## Troubleshooting

- **Still suspends on lid close**: confirm you're on AC power (some configs only ignore
  lid-close on AC, not battery — irrelevant here since it's always plugged in, but worth
  checking `HandleLidSwitchExternalPower` too if present in your logind.conf).
- **Unattended-upgrades rebooted unexpectedly**: see `docs/troubleshooting.md`.
