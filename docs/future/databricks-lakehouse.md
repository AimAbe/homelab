# Future project: observability lakehouse on Databricks

> **Status: planned. Start after the Compose consolidation stretch**
> (pacing schedule weekends 16–19), once Prometheus, Loki and the alerts are stable.
> Full plan with diagram: [Claude doc](https://claude.ai/artifact/GFEPKJJeqyxVfCAHZgGduQ).

Export the lab's own metrics and logs to Databricks Free Edition, process them in a
bronze/silver/gold pipeline, and deploy everything from GitHub through CI/CD. It turns
the data engineering with Databricks training into a working SRE project: collect,
process, monitor, alert, ship changes safely.

The lab keeps Prometheus + Grafana for live monitoring. Databricks adds long-term
history, trend analysis and a data-engineering pipeline on top. It doesn't replace them.

## Architecture

```
T480 (Compose)                      Databricks Free Edition            GitHub
┌───────────────────────────┐       ┌──────────────────────────┐      ┌──────────────────┐
│ Prometheus ─┐             │ push  │ Volume: landing (JSONL)  │      │ homelab-lakehouse│
│ Loki ───────┼─> exporter ─┼──────>│   -> bronze (Auto Loader)│<─────│ repo + Actions   │
│ HTTP checks ┘  + buffer   │ 15min │   -> silver -> gold      │deploy│ lint/test/deploy │
└───────────────────────────┘       │   -> dashboard + alerts  │      └──────────────────┘
                                    └──────────────────────────┘
```

- **Data flows one way, out.** The exporter pushes files with the Databricks CLI.
  Databricks never pulls from the lab, so this keeps the no-port-forwarding rule.
  Free Edition only allows outbound access to trusted domains anyway.
- **Code flows one way, in.** Every pipeline, job, dashboard and alert is defined in a
  Databricks Asset Bundle and deployed by GitHub Actions, never by hand in the UI.

## Where the code lives

A separate repo, `homelab-lakehouse`, holds the pipeline, bundle config and CI. This
repo gets only the exporter stack (`stacks/lakehouse-exporter/`, added in phase 2
below), so it deploys with Ansible like everything else.

```
homelab-lakehouse/
├── databricks.yml          # bundle: targets dev + prod
├── resources/              # pipeline.yml, jobs.yml, dashboard.yml
├── src/                    # bronze.py, silver.py, gold.sql
├── tests/                  # unit/ + sample_data/
├── docs/runbooks/
└── .github/workflows/      # ci.yml (PR), deploy.yml (main)
```

## Phases

### 0 — Accounts and tooling

- [ ] Sign up for Databricks Free Edition with a personal email (not work); verify via
      LinkedIn to raise some limits
- [ ] Install the Databricks CLI on the laptop; `databricks auth login`
- [ ] Create schema `homelab` and Volume `homelab.raw.landing`
- [ ] Create the `homelab-lakehouse` GitHub repo

**Done when:** `databricks fs ls` shows the empty Volume.

### 1 — Bundle skeleton and CI

- [ ] `databricks bundle init` (default Python template); commit it
- [ ] `dev` and `prod` targets, separated by schema prefix (Free Edition = one workspace)
- [ ] PR workflow: `ruff`, `pytest`, `databricks bundle validate`
- [ ] Merge-to-`main` workflow: `databricks bundle deploy -t prod`
- [ ] Databricks host and token as GitHub Actions secrets (confirm PATs work on Free
      Edition; fall back to OAuth if not)

**Done when:** a merged PR deploys a hello-world job without touching the UI.

### 2 — Exporter on the T480

- [ ] `stacks/lakehouse-exporter/`: a small Python container on the `monitoring`
      network that, every 15 minutes:
    - queries Prometheus (`/api/v1/query_range`) for node_exporter and cAdvisor
      series: CPU, memory, disk, container restarts
    - queries Loki (`/loki/api/v1/query_range`) for error-level log lines since the
      last run
    - runs HTTP checks against the `*.homelab` services
    - writes JSON Lines to a local buffer folder, then uploads with `databricks fs cp`
- [ ] Buffer keeps files until upload succeeds, so a quota day or outage loses nothing
- [ ] Databricks token in `stacks/lakehouse-exporter/.env` (gitignored; commit
      `.env.example`)
- [ ] Unit tests for the query and parse code
- [ ] Add the stack to the Ansible `stacks` role

**Done when:** new files land in the Volume on schedule for 48 hours straight.

### 3 — Bronze, silver, gold

- [ ] One Lakeflow declarative pipeline (Free Edition allows one active per type)
- [ ] Bronze: Auto Loader reads the Volume incrementally, with ingest time + source file
- [ ] Silver: typed columns, dedup, UTC timestamps; bad rows to a quarantine table via
      expectations
- [ ] Gold: hourly uptime % per service, errors by service, p95 CPU/memory, disk fill
      trend, container restarts
- [ ] Scheduled a few times a day to stay inside free compute limits

**Done when:** gold tables refresh on schedule and expectations report data quality.

### 4 — Dashboard and alerts

- [ ] AI/BI dashboard on gold: uptime by service, error trend, resources, last-seen time
- [ ] SQL alerts: service under 99% for a day, disk over 85%, no new data in 60 minutes
      (the exporter itself is down)
- [ ] Dashboard and alerts defined in the bundle, deployed through CI
- [ ] A runbook section per alert, same format as [`docs/runbooks.md`](../runbooks.md)

**Done when:** you stop a service on purpose and the alert fires.

### 5 — Harden the pipeline

- [ ] CI integration test: deploy to `dev`, run the pipeline on sample data, assert row
      counts, tear down
- [ ] Branch protection on `main`: PR required, checks must pass
- [ ] Pin CLI and package versions; enable Dependabot
- [ ] Gold table tracking the pipeline's own SLOs (freshness, job success rate)

**Done when:** a broken change is blocked by CI before it reaches `prod`.

### 6 — Write it up

- [ ] README with the diagram, setup steps, dashboard screenshot
- [ ] Blog posts on aimen.dev: the architecture; CI/CD with Asset Bundles; designing
      around free-tier limits
- [ ] Short screen recording: stop a service, alert fires, follow the runbook
- [ ] Resume and LinkedIn bullet

## Free Edition limits and how the design handles them

| Limit | Handling |
|---|---|
| Outbound internet limited to trusted domains | Lab pushes in; nothing pulls from home |
| Serverless compute only, limited size and usage | Small batches, a few runs a day, incremental loads |
| Daily quota; compute stops for the day if exceeded | Exporter buffers locally; next run catches up |
| One SQL warehouse, 2X-Small | Dashboard reads only small gold tables |
| One active pipeline per type | Bronze, silver and gold in one pipeline |
| Max 5 concurrent job tasks | Jobs run in sequence |
| One workspace | `dev` and `prod` split by schema |
| Python and SQL only (no R or Scala) | No impact |
| Non-commercial; inactive accounts may be deleted | Personal project; the repo rebuilds the workspace in one deploy |

Source: [Databricks Free Edition limitations](https://docs.databricks.com/aws/getting-started/free-edition-limitations)
