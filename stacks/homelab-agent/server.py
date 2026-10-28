"""Homelab MCP server: exposes safe, focused tools for an AI agent."""
import os
import shutil

import docker
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("homelab", host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
client = docker.from_env()

# Only these containers can be restarted. Keep this list short and explicit.
RESTARTABLE = set(filter(None, os.getenv("RESTARTABLE", "").split(",")))
# Paths (as mounted in the container) to report disk usage for.
DISK_PATHS = os.getenv("DISK_PATHS", "/host").split(",")


@mcp.tool()
def container_status() -> list[dict]:
    """List all containers with their state and health."""
    out = []
    for c in client.containers.list(all=True):
        health = c.attrs.get("State", {}).get("Health", {}).get("Status", "n/a")
        out.append({"name": c.name, "status": c.status, "health": health,
                    "image": c.image.tags[0] if c.image.tags else c.image.short_id})
    return out


@mcp.tool()
def tail_logs(container: str, lines: int = 50) -> str:
    """Return the last N log lines (max 200) from a container."""
    lines = max(1, min(lines, 200))
    return client.containers.get(container).logs(tail=lines).decode(errors="replace")


@mcp.tool()
def disk_usage() -> list[dict]:
    """Report used/free space for the configured mount points."""
    report = []
    for p in DISK_PATHS:
        u = shutil.disk_usage(p)
        report.append({"path": p, "total_gb": round(u.total / 1e9, 1),
                       "used_gb": round(u.used / 1e9, 1),
                       "free_pct": round(u.free / u.total * 100, 1)})
    return report


@mcp.tool()
def restart_container(container: str, confirm: bool = False) -> str:
    """Restart an allow-listed container. Must be called with confirm=True
    after the user has explicitly agreed."""
    if container not in RESTARTABLE:
        return f"'{container}' is not on the restart allow-list."
    if not confirm:
        return f"Ask the user to confirm restarting '{container}', then call again with confirm=True."
    client.containers.get(container).restart(timeout=30)
    return f"Restarted '{container}'."


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
