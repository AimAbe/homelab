# Phase 15 — AdGuard Home (Internal DNS + Ad Blocking)

## Goal

Real internal DNS for the lab: `*.homelab` resolves on **every** Tailscale device,
phone included, so the `/etc/hosts` workaround from phase 11 goes away. You also get
network-wide ad and tracker blocking.

## Prerequisites

- Phase 11 done (Traefik)
- The lab's Tailscale IP: `tailscale ip -4` on the lab machine (a `100.x.y.z` address)

## Steps

1. Make sure nothing on the host already holds port 53:
   ```
   sudo ss -tulpn | grep ':53 '
   ```
   A minimal Debian 12 install normally has nothing there. If `systemd-resolved` shows
   up, set `DNSStubListener=no` in `/etc/systemd/resolved.conf` and restart it.
2. Copy and start the stack:
   ```
   scp -r stacks/adguard homelab:~/homelab/
   ssh homelab 'cd ~/homelab/adguard && docker compose up -d'
   ```
3. On the laptop, add `adguard.homelab` to `/etc/hosts` one last time (same pattern as
   phase 11), then open `http://adguard.homelab` for the setup wizard:
   - **Admin web interface:** All interfaces, port **3000**. Keep 3000, because that's
     the port the Traefik label points to.
   - **DNS server:** All interfaces, port 53.
   - Create the admin user. Homepage (phase 16) will use this login too.
4. **Settings → DNS settings → Upstream DNS servers.** Use encrypted upstreams, for
   example `https://dns.quad9.net/dns-query` and `https://cloudflare-dns.com/dns-query`.
   Choose "Parallel requests".
5. **Filters → DNS rewrites → Add:** domain `*.homelab`, answer `<lab Tailscale IP>`.
   This one record replaces every `/etc/hosts` line.
6. In the **Tailscale admin console → DNS:**
   - Under *Nameservers*, add a custom nameserver: `<lab Tailscale IP>`.
   - Turn on **Override DNS servers**, so tailnet devices send all DNS through AdGuard.
   - Leave MagicDNS on. The bare `homelab` name keeps working through it.
7. Remove the `*.homelab` lines from `/etc/hosts` on the laptop.

## Verification

- From the laptop: `dig grafana.homelab` returns the lab's Tailscale IP, and
  `/etc/hosts` no longer has those lines.
- **On your phone, off home Wi-Fi, with Tailscale on:** `http://grafana.homelab` loads.
  This fixes the long-standing phone caveat.
- AdGuard's dashboard shows queries arriving from your devices' `100.x` addresses, and
  the blocked-query count goes up.

## Troubleshooting

- **All DNS breaks on tailnet devices when the lab is down:** this is the trade-off of
  *Override DNS servers*. Every query goes to the lab. Quick fix: toggle Tailscale off
  on that device. If it gets annoying, add a public resolver as a second nameserver in
  the Tailscale console. You lose guaranteed blocking and `*.homelab` will resolve only
  sometimes.
- **`bind: address already in use` on port 53:** see step 1.
- **Wizard was set to port 80 by mistake:** edit `bind_port` under `http:` in
  `~/homelab/adguard/conf/AdGuardHome.yaml` (`address: 0.0.0.0:3000` on newer
  versions), then `docker compose restart`.
- **A site is broken by blocking:** Query Log → find the blocked domain → Unblock.
