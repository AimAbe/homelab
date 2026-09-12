# Phase 13 — Dev Environment (tmux/neovim + code-server)

## Goal

A comfortable way to edit code and configs on the lab machine two ways: a terminal
workflow over plain SSH (the daily driver, matching existing CLI comfort), and an
optional browser-based VS Code for when a GUI editor is preferred.

## Prerequisites

- Phase 11 done (Traefik), for the `code.homelab` hostname
- `tmux` and `git` were already installed in phase 3; this phase adds an editor and,
  optionally, dotfiles

## Steps

### Terminal workflow

1. Install neovim (or your editor of choice):
   ```
   sudo apt install -y neovim
   ```
2. Optional: sync your dotfiles from the Omarchy machine via a personal git repo,
   rather than hand-configuring neovim/tmux from scratch:
   ```
   git clone <your-dotfiles-repo-url> ~/.dotfiles
   # then symlink or run whatever install script your dotfiles use
   ```
3. Start a persistent tmux session for lab work so it survives SSH disconnects:
   ```
   tmux new -s homelab
   ```
   Reattach anytime with `tmux attach -t homelab`.

### code-server (browser-based, optional)

1. Set a password and start the stack:
   ```
   scp -r stacks/code-server homelab:~/homelab/
   ssh homelab
   echo "CODE_SERVER_PASSWORD=<a strong password>" > ~/homelab/code-server/.env
   cd ~/homelab/code-server && docker compose up -d
   ```
2. Visit `http://code.homelab` (Traefik, phase 11, is a prerequisite — no port is
   published directly on the host, and `8080` is already taken by Traefik's own
   dashboard anyway) and log in with that password.
3. The `~/homelab` directory on the host is mounted into the container at
   `/home/coder/homelab`, so you can edit any stack's compose files or configs directly
   from the browser editor.

## Verification

- `tmux attach -t homelab` reattaches a session after disconnecting and reconnecting
  over SSH.
- `http://code.homelab` loads and prompts for the password set in `.env`.
- Editing a file in code-server and then `cat`-ing it over plain SSH shows the same
  content (confirms the bind mount is the same directory both ways).

## Troubleshooting

- **code-server password rejected**: confirm `.env` is in the same directory as
  `docker-compose.yml` when you run `docker compose up -d` — Compose only picks up a
  `.env` from the project directory.
- **Changes in code-server don't appear over SSH (or vice versa)**: check the volume
  mount path in `stacks/code-server/docker-compose.yml` matches where you expect on the
  host (`${HOME}/homelab`).
