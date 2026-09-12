# Phase 9 — Obsidian Vault Sync via Gitea

Obsidian is a desktop/mobile app, not a browser app — "remote access" here means the
vault's files sync through the lab via git, and you open them in the local Obsidian app
on whatever device you're using. Gitea was chosen over Syncthing for the more
educational, real-git workflow.

## Goal

A private git remote (Gitea) on the lab, with the Obsidian vault pushing/pulling
through it via the Obsidian Git community plugin.

## Prerequisites

- Phase 8 done (port 3001 is used specifically because Grafana holds 3000)

## Steps

1. Copy the stack and bring it up:
   ```
   scp -r stacks/gitea homelab:~/homelab/
   ssh homelab 'cd ~/homelab/gitea && docker compose up -d'
   ```
2. Visit `http://homelab:3001`, complete Gitea's first-run install wizard (SQLite is
   fine for this scale), and create your admin account.
3. In Gitea, create a new private repository, e.g. `obsidian-vault`.
4. On each device that runs Obsidian:
   - Install the **Obsidian Git** community plugin (Settings → Community plugins).
   - Point your vault's `.git` remote at the Gitea repo, e.g.:
     ```
     git remote add origin http://homelab:3001/<you>/obsidian-vault.git
     ```
     (or over Tailscale from anywhere: `http://homelab:3001/...` works the same, since
     `homelab` resolves via MagicDNS wherever Tailscale is connected).
   - Configure the plugin's auto-pull-on-open and auto-commit-and-push-on-interval
     settings to taste.
5. Push the vault's initial commit from the first device, then clone/pull on any other
   device.

## Verification

- Editing a note on one device, then opening Obsidian on another, shows the change
  after a sync interval (or manual "commit and sync" via the plugin's command palette
  entry).
- `git log` inside the vault on any device shows commits from the Obsidian Git plugin.

## Troubleshooting

- **Auth prompts every push**: set up a Gitea access token or SSH key instead of
  password auth for the git remote — the plugin supports either.
- **Merge conflicts between devices**: expected occasionally with git-based sync if two
  devices edit offline at the same time — resolve like any git conflict; Obsidian Git
  surfaces conflicted files rather than silently corrupting them.
- **Can't reach `http://homelab:3001` off Wi-Fi**: confirm Tailscale is connected on
  that device — same as any other lab service.
