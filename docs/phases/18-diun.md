# Phase 18 — Diun (Image Update Notifications)

## Goal

Know when your containers have updates, without auto-updating them. Every Saturday
morning Diun checks each running container's image and sends the list of what's
newer to ntfy. Updating stays a deliberate, observed step. That's patch management:
read the release notes, update, verify in Grafana, roll back if needed.

## Prerequisites

- Phase 17 done (ntfy, plus the write-only `bot` token)

## Steps

1. Copy the stack and add the token:
   ```
   scp -r stacks/diun homelab:~/homelab/
   ssh homelab
   cd ~/homelab/diun && cp .env.example .env && vim .env
   docker compose up -d
   ```
2. Weekly routine when the notification arrives:
   ```
   cd ~/homelab/<stack>
   docker compose pull && docker compose up -d
   docker image prune -f
   ```
   Then watch Grafana and Dozzle for a few minutes. Note what you updated in your
   Obsidian log or a commit message.

## Verification

- `docker logs diun` shows the configured schedule and the containers it found.
- Force a check now: `docker exec diun diun image list` lists watched images. To test
  delivery, temporarily set `DIUN_WATCH_FIRSTCHECKNOTIF: "true"`, run
  `docker compose up -d --force-recreate`, and you'll get a notification for every
  image. Set it back afterwards.

## Notes

- Almost everything here uses `:latest`, so Diun reports when the image behind
  `latest` changes. Postgres in the Paperless stack is pinned to `16` on purpose.
  Major Postgres upgrades need a dump/restore, so treat that notification as a
  planned task, not a routine pull.
- **Graduating to Renovate:** once you're using Gitea Actions, Renovate can open
  update PRs against this repo with pinned versions instead. That's a good
  consolidation-month project.
- To skip a container, add the label `diun.enable=false` to it.
