# Phase 12 — Media Server (Jellyfin)

## Goal

Self-hosted, open-source media streaming, reachable remotely over Tailscale with no
account or cloud dependency (the reason Jellyfin was chosen over Plex — see
`docs/00-architecture.md`).

## Prerequisites

- Phase 11 done (Traefik), for the `jellyfin.homelab` hostname
- An external drive for media — ideally separate from the restic backup drive so a
  large media library doesn't compete with backup space; if only one drive is
  available, partition it or accept the tradeoff consciously

## Steps

1. Mount the media drive:
   ```
   lsblk
   sudo mkdir -p /mnt/media
   sudo mount /dev/sdX1 /mnt/media
   ```
   Add to `/etc/fstab` by UUID (`blkid`) so it survives reboots.
2. Copy over your media library (or start adding to it directly on `/mnt/media`).
3. Copy and start the stack:
   ```
   scp -r stacks/jellyfin homelab:~/homelab/
   ssh homelab 'cd ~/homelab/jellyfin && docker compose up -d'
   ```
4. Visit `http://jellyfin.homelab` (Traefik, phase 11, is a prerequisite here — no port
   is published directly on the host in this stack's compose file), complete the setup
   wizard, and point a library at `/media` (the path inside the container).
5. In Jellyfin's playback settings, enable hardware acceleration → Intel QuickSync
   (QSV) — the T480's Intel UHD 620 handles light transcoding this way; expect it to
   struggle with more than one or two simultaneous transcoded streams.

## Verification

- A video plays back in the Jellyfin web UI.
- **Off home Wi-Fi**, a video streams from a phone or laptop over Tailscale, via
  `jellyfin.homelab` with the `/etc/hosts` entry set (phone: fall back to accessing
  Traefik directly by IP:80 with a Host header, or add a `ports:` mapping to the
  Jellyfin service temporarily, until real internal DNS exists).
- `docker exec jellyfin ls /dev/dri` shows the render device, confirming hardware
  transcoding access.

## Troubleshooting

- **No `/dev/dri` in the container**: the host kernel needs the `i915` driver loaded
  (`lsmod | grep i915`) — should be automatic on Debian with the T480's iGPU, but worth
  checking if hardware transcoding silently falls back to CPU.
- **Playback stutters remotely**: Tailscale's throughput depends on the path between
  devices (direct vs. relayed — `tailscale status` shows which); also check whether
  Jellyfin is transcoding at all versus direct-playing, in the playback session info.
- **Media not showing up in a library**: confirm the container actually sees new files
  (`docker exec jellyfin ls /media`) — a stale bind mount or wrong path is the usual
  cause.
