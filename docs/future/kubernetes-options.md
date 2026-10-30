# Future decision: how to learn Kubernetes

> **Status: undecided — revisit during the Compose consolidation stretch**
> (pacing schedule weekends 16–19). Phase 14 (k3s) stays in the plan as-is until then.

Kubernetes is a learning goal for this lab. Phase 14 covers the basics, but it's
scheduled last and assumes stopping the Docker stacks to free ports 80/443/3000. Two
ways to go further or start sooner are on the table.

## Option 1 — Sandbox on the laptop, starting any time

A throwaway cluster on the Omarchy laptop with **kind** or **k3d** (Kubernetes inside
Docker containers). It runs alongside the lab plan without touching the T480.

- About an hour a week: deploy, scale, roll back, break and fix apps with `kubectl`
- Later, port a Compose stack (Homepage or ntfy) to Kubernetes manifests, then a
  Helm chart
- Optional goal: the CKAD certification, which fits backend roles

**Pros:** start now, zero risk to the lab, rebuild in a minute.
**Cons:** not "real" infrastructure, and nothing runs there long-term.

## Option 2 — k3s alongside Compose on the T480

Instead of stopping the Docker stacks (phase 14's default), run k3s next to them:

- Install with `--disable traefik` and give k3s ingress different ports, or route
  `*.k8s.homelab` through the existing Traefik
- Move one or two services (e.g. Homepage, ntfy) from Compose to k3s for real
- Next step: GitOps. Argo CD or Flux deploying from the Gitea repo
- Ansible (phase 20) installs and configures k3s

**Pros:** the most realistic setup and the strongest portfolio piece.
**Cons:** competes for 16 GB of RAM with Jellyfin and Paperless, and it's more
complex to run.

## What to check before deciding

- **Memory headroom:** Grafana's memory panel over a normal week. Option 2 wants
  roughly 2–4 GB free beyond everyday peaks.
- **Comfort with Compose:** the phase 14 readiness signal (add, change, verify and
  back up a service without looking anything up).
- **Job search needs:** if postings you're targeting keep asking for Kubernetes,
  start option 1 right away regardless.

The two options aren't exclusive. Option 1 can start any time, and option 2 can
follow it.
