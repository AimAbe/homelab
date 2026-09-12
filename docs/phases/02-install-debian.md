# Phase 2 — Install Debian 12

## Goal

A minimal, headless Debian 12 install with SSH access and no desktop environment.

## Prerequisites

- Phase 0 (installer USB) and phase 1 (BIOS) done
- A wired Ethernet connection is easiest for the install itself (Wi-Fi firmware can
  complicate a minimal install — switch to Wi-Fi/Tailscale later if wired isn't
  practical long-term)

## Steps

1. Boot from the installer USB (`F12` for a one-time boot menu on most ThinkPads).
2. Use the standard (non-graphical) installer for a lighter footprint — either works.
3. Hostname: `homelab` (referenced throughout this repo and used for Tailscale MagicDNS
   later).
4. Partitioning: guided, use entire disk, is fine for a lab machine — no need for
   complex LVM/encryption schemes unless you want the practice.
5. **Software selection screen**: uncheck every desktop environment. Check only:
   - SSH server
   - standard system utilities
6. Create your user account and set a strong password (SSH key-only login comes in
   phase 4 — password auth is still the only option until then).
7. Install the GRUB bootloader to the primary disk.
8. Reboot, remove the USB.

## Verification

- Machine boots to a text login prompt, no GUI.
- From another machine on the same LAN: `ssh <user>@<lab-ip>` logs in (find the IP via
  the router's DHCP client list, or `ip a` on the lab machine directly).

## Troubleshooting

- **No network after install**: if you used Wi-Fi, Debian's installer needs non-free
  firmware for the T480's wireless card — easier to install wired, then add Wi-Fi later
  if needed (though Tailscale + wired Ethernet is the recommended long-term setup for a
  stationary lab machine).
- **Can't SSH in**: confirm `openssh-server` was actually selected in software
  selection; `sudo systemctl status ssh` on the machine directly if you still have
  physical access.
