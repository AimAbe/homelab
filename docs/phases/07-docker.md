# Phase 7 — Docker, Docker Compose, Directory Layout

## Goal

Docker installed from the official repo (not Debian's older packaged version), plus
the directory structure this whole repo's `stacks/` assume.

## Prerequisites

- Phase 6 done

## Steps

1. Install Docker from the official repository (per current Docker docs — commands
   below match Debian 12 as of this writing, double-check
   https://docs.docker.com/engine/install/debian/ for changes):
   ```
   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   sudo chmod a+r /etc/apt/keyrings/docker.gpg
   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
     $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt update
   sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```
2. Add your user to the `docker` group so `sudo` isn't needed for every command:
   ```
   sudo usermod -aG docker $USER
   ```
   Log out and back in (or `newgrp docker`) for this to take effect.
3. Create the working directory layout used by every stack in this repo:
   ```
   mkdir -p ~/homelab/{monitoring,gitea,portainer,traefik,jellyfin,code-server,obsidian}
   ```
4. Free practice before stacking anything on top — get comfortable with the basics:
   ```
   docker run --rm hello-world
   docker run -it --rm alpine sh
   docker volume create test-vol
   docker network create test-net
   docker ps -a
   docker image ls
   ```
   Clean up when done (`docker volume rm test-vol`, `docker network rm test-net`).

## Verification

- `docker compose version` and `docker ps` both run without `sudo`.
- `docker run --rm hello-world` prints the confirmation message.
- `~/homelab/` has the expected subdirectories.

## Troubleshooting

- **`docker: permission denied`**: the group membership hasn't taken effect yet in your
  current shell — log out/in, or `newgrp docker` for the current session.
- **`docker compose` not found**: confirms the plugin package
  (`docker-compose-plugin`) — the old standalone `docker-compose` (with a hyphen) binary
  is a different, older tool; this repo uses the `docker compose` (space) plugin syntax
  throughout.
