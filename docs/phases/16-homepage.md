# Phase 16 — Homepage Dashboard

## Goal

One start page at `http://home.homelab`. It has a tile for every service with a live
up/down dot, host CPU/RAM/temperature/disk at a glance, and widgets for Jellyfin,
AdGuard, Paperless and Traefik. Pin it to your phone's home screen.

## Prerequisites

- Phase 15 done, so `home.homelab` resolves everywhere

## Steps

1. Review `stacks/homepage/config/services.yaml`. Remove tiles for anything you haven't
   deployed yet. Otherwise they'll show as down, which is accurate but noisy.
2. Copy the stack and create the secrets file:
   ```
   scp -r stacks/homepage homelab:~/homelab/
   ssh homelab
   cd ~/homelab/homepage && cp .env.example .env && vim .env
   ```
   Fill in only the keys you have now. A blank key just shows an error on that widget.
3. Start it:
   ```
   docker compose up -d
   ```
4. Iterate. Homepage reloads its YAML on change, so edit
   `~/homelab/homepage/config/*.yaml` and refresh the browser. Copy edits you like back
   into this repo and commit them.

## Verification

- `http://home.homelab` loads, and every deployed service shows a green dot.
- Stop a container (`docker stop dozzle`). Its dot turns red on refresh. Start it again.
- The resources widget shows CPU, memory, temperature and both disks.

## Troubleshooting

- **"Host validation failed":** you're reaching it by a hostname not in
  `HOMEPAGE_ALLOWED_HOSTS`. Add it, comma-separated, in `docker-compose.yml`.
- **Every dot is grey or unknown:** Homepage can't reach the socket proxy. Run
  `docker logs homepage` and check that `config/docker.yaml` says `socket-proxy:2375`.
- **A widget errors:** check its key in `.env`. The widget URL uses the Docker service
  name (for example `http://jellyfin:8096`), so the target must be on the `proxy`
  network.
