# Phase 0 — Prep, Backup, Drives, Write Debian ISO to USB

## Goal

Get the physical materials and safety nets in place before touching the T480's disk.

## Prerequisites

- The ThinkPad T480 itself, charger, and a way to reach it with a keyboard temporarily
  (this phase happens before SSH exists)
- A spare USB stick (8GB+) for the Debian installer
- An external USB drive for backups (see `docs/00-architecture.md` — ideally a second
  one for Jellyfin media, but one is enough to start)
- Another machine (the Omarchy laptop) to write the installer image

## Steps

1. Back up anything currently on the T480 you care about — it will be wiped.
2. Download the Debian 12 "netinst" or full installer ISO from
   https://www.debian.org/distrib/ (verify the checksum/signature against the page).
3. Identify the USB stick's device name **before** writing anything:
   ```
   lsblk
   ```
   Confirm by size/label which entry is the USB stick. Do not proceed until you're sure.
4. Write the ISO (replace `/dev/sdX` with the confirmed device — this erases it):
   ```
   sudo dd if=debian-12.x.x-amd64-netinst.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```
5. Label and set aside the external backup drive — it isn't used until phase 10, but
   grab it now so it's not "a project for later."

## Verification

- `lsblk` shows the installer USB with a filesystem/partition matching the ISO.
- You can boot a spare machine (or the T480 itself, briefly) from the USB to confirm
  it's not corrupt, without actually installing.

## Troubleshooting

- **Wrong device wiped**: this is why `lsblk` immediately before `dd` is non-negotiable
  — there's no undo. See `docs/troubleshooting.md`.
- **ISO won't boot**: re-download and re-verify the checksum; a partial download is the
  most common cause.
