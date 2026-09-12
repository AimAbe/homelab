# Phase 6 — UFW Firewall

## Goal

Default-deny inbound, with Tailscale trusted broadly and a LAN SSH fallback in case
Tailscale ever breaks.

## Prerequisites

- Phase 5 done
- Know your actual LAN subnet: `ip a` on the lab machine, look at the wired/Wi-Fi
  interface's address (e.g. `192.168.1.0/24`) — **use your real subnet below, not the
  example.**

## Steps

1. Install and check UFW's default state:
   ```
   sudo apt install -y ufw
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   ```
2. Trust the Tailscale interface broadly:
   ```
   sudo ufw allow in on tailscale0
   ```
3. Allow SSH from the LAN subnet only, as a fallback if Tailscale ever misbehaves —
   **replace with your actual subnet**:
   ```
   sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
   ```
4. Enable UFW (do this over a session you can recover — see caution below):
   ```
   sudo ufw enable
   ```
5. Confirm rules:
   ```
   sudo ufw status verbose
   ```

## Verification

- `ssh homelab` over Tailscale still works.
- `ssh <user>@<lab-lan-ip>` from a machine on the same physical LAN still works.
- From an external network with no Tailscale connection, port 22 is unreachable
  (e.g. `nmap -p 22 <public-ip>` from outside — or simpler, just trust that nothing is
  forwarded on the router, since nothing has been port-forwarded at any point in this
  plan).

## Troubleshooting

- **Locked out after `ufw enable`**: if you got the subnet wrong, you may lose LAN SSH
  access. Physical access to the machine (keyboard + monitor) is the recovery path —
  `sudo ufw disable` locally, fix the rule, re-enable.
- **Tailscale SSH stops working**: confirm `tailscale0` still shows in
  `ip a` and the `ufw allow in on tailscale0` rule is present in `ufw status verbose`.
