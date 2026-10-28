# Future project: homelab-agent

> **Status: planned, not started.** Pick this up after the Compose consolidation
> stretch (weekends 12–15) — it builds on Docker, Traefik, Jellyfin and Grafana
> already being in place.

## Goal

A conversation-friendly AI agent I can talk to from my phone that's connected to the
lab: "is everything healthy?", "why is Jellyfin down?", "how full is the media
drive?", "restart code-server."

## Design

The T480 can't run a capable LLM locally (CPU-only, 16 GB RAM), so the lab hosts the
**tools** and a hosted model handles the conversation.

```
Phone ──► chat client ──► hosted LLM ──► MCP server on T480 ──► docker-socket-proxy ──► Docker
                                                └──► host disk (read-only), media mount
```

- **MCP server** (`stacks/homelab-agent/`): Python + FastMCP, Streamable HTTP on port
  8000, routed by Traefik at `agent.homelab`.
- **Least privilege:** talks to Docker through `docker-socket-proxy` (containers +
  restart only), never the raw socket. Host filesystem mounted read-only.
- **Safe writes:** every write tool needs an allow-list entry *and* `confirm=True`,
  which the agent only sends after I explicitly agree.

### Starter tools

| Tool | What it does | Risk |
|---|---|---|
| `container_status` | Lists containers, state, health | read-only |
| `tail_logs` | Last N log lines (capped at 200) | read-only |
| `disk_usage` | Free space on `/` and the media drive | read-only |
| `restart_container` | Restarts an allow-listed container, requires `confirm=True` | write |

## Phone access — options

1. **Claude app custom connector (fastest):** needs a public HTTPS URL, so publish only
   this service through a Cloudflare Tunnel with Cloudflare Access (OAuth) in front.
   This is the one exception to "nothing exposed to the open internet" — decide
   deliberately.
2. **Tailnet-only:** run Open WebUI on the lab (phone PWA) pointed at a hosted model
   API, with this MCP server attached. Nothing public.
3. **Build my own client (portfolio piece):** FastAPI + Claude tool-use loop, fronted
   by a Telegram bot or small PWA, over Tailscale.

Plan: build the MCP server first and validate it with option 1 or 2, then build
option 3 on top of the same server.

## Milestones

- [ ] Server runs; tools verified with MCP Inspector (`npx @modelcontextprotocol/inspector`)
- [ ] Reachable at `http://agent.homelab/mcp` over Tailscale
- [ ] Talking to it from my phone via one of the options above
- [ ] Jellyfin tools (recently added, search) via its REST API
- [ ] Prometheus metrics per tool call → Grafana dashboard
- [ ] Logs in Loki; incident drill: break a container, diagnose it from my phone
- [ ] Custom FastAPI client (option 3)
