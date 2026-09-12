# Phase 5 — Tailscale (Lab + Omarchy + Phone)

## Goal

Reach the lab from anywhere, by hostname, without any port forwarding — this phase
delivers the "get off home Wi-Fi" milestone.

## Prerequisites

- Phase 4 done (SSH key auth working)
- A Tailscale account (personal tailnet is fine)

## Steps

1. On the lab machine:
   ```
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   ```
   Follow the printed URL to authenticate the device to your tailnet.
2. Install Tailscale on the Omarchy laptop (Arch package or the same install script) and
   `tailscale up` there too.
3. Install the Tailscale app on your phone from the app store and sign into the same
   tailnet.
4. In the Tailscale admin console (https://login.tailscale.com/admin):
   - Enable **MagicDNS** for the tailnet.
   - Disable **key expiry** for the lab machine specifically (Machines → homelab → Disable
     key expiry) so it doesn't silently drop off the tailnet after 180 days.
5. Update `~/.ssh/config` on the Omarchy laptop to use the MagicDNS name:
   ```
   Host homelab
       HostName homelab
       User <user>
       IdentityFile ~/.ssh/homelab_ed25519
   ```

## Verification

- `tailscale status` on any device shows all three (lab, laptop, phone) online.
- **Switch the laptop to a phone hotspot (off the home Wi-Fi)** and run `ssh homelab` —
  this is the milestone moment: if it connects, remote access genuinely works.
- From the phone's Tailscale app, confirm the lab machine shows as reachable.

## Troubleshooting

- **`ssh homelab` fails off the home network**: check `tailscale status` on the lab
  machine — the daemon may need `sudo systemctl restart tailscaled` after a reboot if it
  didn't come up automatically (`systemctl enable tailscaled` if not already enabled).
- **MagicDNS name doesn't resolve**: confirm MagicDNS is actually toggled on in the
  admin console, and that the client device's `tailscale status` shows it connected to
  the same tailnet.
