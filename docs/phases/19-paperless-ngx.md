# Phase 19 — Paperless-ngx (Documents)

## Goal

A searchable archive of household paperwork (bills, statements, school forms,
receipts). Scan or photograph a document, Paperless OCRs it, and every word becomes
searchable at `http://paperless.homelab`.

## Prerequisites

- Phase 15 done (DNS)
- Phase 10 backups working. This stack holds documents you can't regenerate, so
  backups matter more here than anywhere else in the lab.

## Steps

1. Copy the stack, create secrets, start it:
   ```
   scp -r stacks/paperless homelab:~/homelab/
   ssh homelab
   cd ~/homelab/paperless && cp .env.example .env && vim .env
   mkdir -p data media export consume pgdata redisdata
   docker compose up -d
   ```
   The first start takes a minute or two (database migrations).
2. Log in at `http://paperless.homelab` with the admin user from `.env`. Then remove
   `PAPERLESS_ADMIN_PASSWORD` from `.env`, since it's only used on first start.
3. Getting documents in. Any of these works:
   - Drag and drop into the web UI.
   - Drop files into `~/homelab/paperless/consume/` (handy from code-server or `scp`).
   - Phone: a Paperless mobile app pointed at `http://paperless.homelab`, which
     scans and uploads directly.
4. Set up a few **tags** and **correspondents** (e.g. "utilities", "medical", "taxes").
   Paperless learns to auto-assign them as you go.
5. Update the backup script on the lab from this repo (`scripts/restic-backup.sh`). It
   now runs Paperless's exporter before each backup.

## Verification

- Upload a PDF and search for a word in it. It's found.
- `docker compose exec -T webserver document_exporter ../export` completes, and
  `~/homelab/paperless/export/` contains your documents plus `manifest.json`.
- The next nightly restic run includes `~/homelab/paperless/export`
  (`restic ls latest | grep paperless`).

## Troubleshooting

- **Web UI 502 at first:** the webserver is still migrating. Check
  `docker logs -f paperless`.
- **Files in `consume/` aren't picked up:** check ownership. `USERMAP_UID/GID` must
  match your user (`id -u`). If yours isn't 1000, change both in the compose file.
- **High memory during OCR of big scans:** expected spikes. One worker with two threads
  is already the conservative setting for this machine.
- **Restoring:** start a fresh stack, then
  `docker compose exec -T webserver document_importer ../export`.
