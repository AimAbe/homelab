# Phase 21 — Oracle 19c DBA Lab (KVM virtual machine)

> **Position in sequence:** after phase 7 (Docker), before phase 8 (monitoring).
> It's numbered 21 only because it was added after phases 0–20 were written.
>
> **Status:** not started
> <!-- update as you go: not started | in progress (O4) | complete -->

## Goal

A real Oracle Database 19c install on Oracle Linux, running as a KVM virtual machine on
the T480, used to work through DBA skills end to end: install, Oracle Net, instance
management, multitenant, security, storage, SQL/PL-SQL, moving data, RMAN backup and
recovery, tuning, patching, Data Guard, and monitoring the database with Prometheus and
Grafana.

It serves two targets that overlap but aren't the same:

- **The job** (Oracle 19c DBA supporting HA/DR databases): leans on RMAN, multitenant,
  patching and Data Guard.
- **The 1Z0-082 exam** (Oracle Database Administration I): about half SQL, half
  foundational administration. O1's Oracle Net work, O2, O5, O6 and O6b carry most of
  its weight.

Each section has a checklist and the resume bullet it earns. **Add a bullet to your
resume only after you've genuinely finished that section.**

Keep a dated entry in [`oracle/JOURNAL.md`](../../oracle/JOURNAL.md) for every
session: what you did, what broke, how you fixed it. It's your exam revision, your
"tell me about a time you troubleshot a database" stories, and evidence of sustained
work.

## Why a VM and not a container

The job lists "installation, configuration, and patching" of 19c. A container image
skips the install, the OS prep and OPatch — the parts you'll be asked about. So 19c
gets a full VM. (For quick SQL practice an Oracle Database Free container is fine on
top of this, not instead of it.)

## Prerequisites

- Phase 7 done (Docker works; the host is hardened and on Tailscale)
- VT-x enabled in the BIOS (phase 1 didn't cover this): ThinkPad BIOS →
  **Security → Virtualization → Intel Virtualization Technology: Enabled**
  (VT-d too, while you're there)
- A free Oracle account (needed to download 19c)
- ~90 GB free on the SSD: 60 GB for the VM disk plus room for snapshots to grow
- 8 GB of RAM to give the VM while it runs
- **1Z0-082 booked, dated about 9 weeks after you start O0.** A paid, fixed date is
  what turns the plan into a finished one, and "scheduled for [date]" is a concrete
  thing to tell HR.

### Licensing

The Oracle Database 19c and Oracle Linux software is used under Oracle's free
developer (OTN) licence for personal learning only. The lab runs entirely on personal
hardware, holds only Oracle's sample schemas and made-up data, and is never connected
to anything work-related. AWR/ASH (O8) and Active Data Guard (O10) are separately
licensed options in production; they're used here only to learn them.

### Decision: Oracle Linux 7 or 8

Decide before downloading anything. The 19.3 base release (what Oracle's free download
page has offered) predates OL8 and fails its OS prerequisite check there.

| | Oracle Linux 8 (**chosen**) | Oracle Linux 7 |
|---|---|---|
| Install of 19.3 | Needs `export CV_ASSUME_DISTID=OEL7.8` before `runInstaller` (step O1.1) | Installs without workarounds |
| Closeness to current federal environments | Closer | Older; past standard support |
| Cost | Budget **two evenings** for O1 | One evening |

OL8 is the default here because it's closer to what a current shop runs, and the
workaround is one environment variable. `-applyRU` (installing with a newer Release
Update) isn't an option without My Oracle Support access. If O1 turns into a fight,
switch to OL7: everything after O1 is identical. Before downloading, check whether
Oracle's download page now offers a newer 19.x base release than 19.3.

## Resource budget

| Component | RAM | Disk |
|---|---|---|
| Oracle VM (while running) | 8 GB | 60 GB qcow2, plus snapshot growth |
| Debian host + Docker | ~8 GB left | rest of the SSD |

The VM is **not** set to autostart. Start it when you study and shut it down after
(`virsh shutdown ol8-oracle`), so the RAM goes back to the Docker stacks.

A RAM upgrade to 32 GB (the T480 has two SO-DIMM slots) would let O10 use two VMs
instead of two instances in one, and would help every later phase too.

## Snapshots

Take a VM snapshot at each of these points, so a bad drill costs minutes instead of a
reinstall:

| Name | When |
|---|---|
| `post-install` | As soon as O1 verifies. Your most valuable restore point. |
| `pre-o7` | Before the RMAN recovery drills |
| `pre-o9` | Before patching (a half-patched Oracle Home is painful) |
| `pre-o10` | Before Data Guard changes the archive destinations |

```
virsh snapshot-create-as ol8-oracle post-install
virsh snapshot-list ol8-oracle
virsh snapshot-revert ol8-oracle post-install
virsh snapshot-delete ol8-oracle pre-o7      # once you no longer need it
```

Snapshots live inside the qcow2 and grow it. Check `df -h` on the host and delete the
ones you're done with.

## When to do which section

The lab is built to survive an irregular shift schedule:

| Type | Sections | Session | When |
|---|---|---|---|
| Needs a long block | O0, O1, O7, O9, O10 | 3–4 hours | Weekend or day off |
| Fits an evening | O2, O3, O4, O5, O8, O11 | 60–90 min | Weekday |
| Fits anywhere | O6, O6b | Even 30 min | Any gap |

O6 and O6b are about half the exam. Don't let the DBA sections crowd them out.

## Steps

### O0 — KVM host and Oracle Linux VM

1. Confirm the CPU exposes virtualization (non-zero output):
   ```
   grep -cE '(vmx|svm)' /proc/cpuinfo
   ```
2. Install KVM and libvirt on the Debian host:
   ```
   sudo apt install -y qemu-system-x86 libvirt-daemon-system libvirt-clients virtinst
   sudo usermod -aG libvirt,kvm $USER     # log out and back in
   virsh -c qemu:///system net-start default
   virsh -c qemu:///system net-autostart default
   ```
3. Give the VM a fixed address with a DHCP reservation on libvirt's `default` network,
   rather than a static IP inside the guest. The address stays stable, `virsh
   domifaddr` keeps working, and phase 20 (Ansible) can manage it from the host. The
   MAC must match the one in step 5:
   ```
   virsh -c qemu:///system net-update default add ip-dhcp-host \
     "<host mac='52:54:00:19:c0:01' name='ol8-oracle' ip='192.168.122.19'/>" \
     --live --config
   ```
4. Download the Oracle Linux 8 DVD ISO (free, from yum.oracle.com) to
   `/var/lib/libvirt/images/`.
5. Create the VM headless, with the installer on the serial console:
   ```
   sudo virt-install \
     --name ol8-oracle --memory 8192 --vcpus 2 \
     --disk path=/var/lib/libvirt/images/ol8-oracle.qcow2,size=60,format=qcow2 \
     --location /var/lib/libvirt/images/OracleLinux-R8-U*-x86_64-dvd.iso \
     --osinfo detect=on,require=off \
     --network network=default,mac=52:54:00:19:c0:01 \
     --graphics none --extra-args 'console=ttyS0,115200n8 inst.text'
   ```
   (`--osinfo detect=on,require=off` avoids depending on whether your `osinfo-db`
   knows `ol8.0`; `virt-install --osinfo list | grep ol8` shows what it knows.)
   Pick a minimal install with DHCP networking, and enable SSH.
6. Add the VM to `~/.ssh/config` on the lab host as `ol8` (`HostName 192.168.122.19`)
   and SSH in.
7. OS prep inside the VM:
   ```
   sudo dnf install -y oracle-database-preinstall-19c
   ```
   This creates the `oracle` user, the `oinstall`/`dba` groups, kernel parameters and
   limits. Read what it changed in `/etc/sysctl.d/` and `/etc/security/limits.d/` —
   that's an interview question.
8. Download Oracle Database 19c for Linux x86-64 and copy it to the VM.

- [ ] VM boots at 192.168.122.19, `ssh ol8` works, preinstall RPM completed cleanly,
      installer zip staged

> **Resume bullet:** Provisioned and configured an Oracle Linux 8 KVM virtual
> environment for Oracle Database 19c, including kernel parameter tuning, OS user and
> group setup, and storage preparation.

### O1 — Install, configure, Oracle Net

Install:

- [ ] O1.1 Unzip into `ORACLE_HOME`, `export CV_ASSUME_DISTID=OEL7.8` (OL8 only), run
      `./runInstaller` (software only) with `ORACLE_BASE`, `ORACLE_HOME` and the
      inventory set
- [ ] O1.2 Create a CDB with one PDB using `dbca`
- [ ] O1.3 Set up `oraenv` and a systemd unit (or `dbstart`) for startup
- [ ] O1.4 Install the HR and SH sample schemas
- [ ] O1.5 Enable EM Express on port 5500 (`DBMS_XDB_CONFIG.SETHTTPSPORT(5500)`) —
      the small sibling of Cloud Control, which the job lists as preferred
- [ ] O1.6 **Snapshot `post-install`**

Oracle Net — 1Z0-082 tests this harder than the install:

- [ ] O1.7 Configure the listener; `lsnrctl status` / `lsnrctl services`; dynamic vs
      static service registration
- [ ] O1.8 Connect three ways: `tnsnames.ora` (local naming), Easy Connect
      (`host:port/service`), and a `TNS_ADMIN` override
- [ ] O1.9 Dedicated vs shared server: enable shared server, connect with each, and
      see the difference in `V$SESSION.SERVER` and `V$PROCESS`
- [ ] O1.10 Find the listener log, and a failed connection's error in it
- [ ] O1.11 Open 1521 and 5500 in the VM's firewall:
      `sudo firewall-cmd --add-port={1521,5500}/tcp --permanent && sudo firewall-cmd --reload`

Connecting from your laptop (SQL Developer, Toad trial, EM Express) without exposing
anything — an SSH tunnel over Tailscale:
```
ssh -L 1521:192.168.122.19:1521 -L 5500:192.168.122.19:5500 homelab
```
Two hops are involved: the tunnel ends at the lab host, and the host forwards to the
VM, which it can reach because it runs libvirt's `192.168.122.0/24` network. Point the
client at `localhost:1521`, and the browser at `https://localhost:5500/em`.

> **Resume bullets:** Installed and configured Oracle Database 19c on Oracle Linux,
> including Oracle Home setup, database creation via DBCA, and multitenant container
> configuration. · Configured Oracle Net — listener, static and dynamic service
> registration, local naming and Easy Connect, dedicated and shared server — and
> validated connectivity from SQL\*Plus, SQL Developer, Toad and EM Express.

### O2 — Instance management and the data dictionary

- [ ] Step through `STARTUP NOMOUNT` → `ALTER DATABASE MOUNT` → `ALTER DATABASE OPEN`
- [ ] Each shutdown mode (`NORMAL`, `TRANSACTIONAL`, `IMMEDIATE`, `ABORT`), including
      the instance recovery after `ABORT`
- [ ] PFILE ↔ SPFILE; change a parameter with `SCOPE=MEMORY`, `SPFILE` and `BOTH`
- [ ] Find and read the alert log and a trace file in the ADR (`adrci`)
- [ ] Memory and processes: `V$SGA`, `V$SGASTAT`, `V$PROCESS`, `V$PARAMETER`
- [ ] The dictionary model: `DICTIONARY`, `DBA_` vs `ALL_` vs `USER_` (same query as
      three users), `CDB_` views, static dictionary vs dynamic `V$` views,
      `V$FIXED_TABLE`

> **Resume bullet:** Managed Oracle instance lifecycle across NOMOUNT, MOUNT and OPEN
> states, initialization parameters via SPFILE and PFILE, and diagnostics through the
> alert log, trace files and ADR.

### O3 — Multitenant

- [ ] `SHOW CON_NAME`, `V$PDBS`, `V$CONTAINERS`
- [ ] Create a PDB from `PDB$SEED`; clone a PDB
- [ ] Open/close and `SAVE STATE`
- [ ] Unplug to an XML manifest and plug back in
- [ ] `ALTER SESSION SET CONTAINER`

> **Resume bullet:** Administered Oracle multitenant architecture: created PDBs from
> seed, cloned PDBs, managed open-state persistence, and performed unplug/plug
> operations.

### O4 — Users, privileges, security

- [ ] Local vs common (`C##`) users; see where each is visible
- [ ] Roles; system and object privileges; `WITH ADMIN OPTION` vs `WITH GRANT OPTION`
- [ ] A profile with password complexity and resource limits
- [ ] Lock, unlock, expire, reset accounts
- [ ] A least-privilege read-only reporting account
- [ ] Unified auditing: create an audit policy, query `UNIFIED_AUDIT_TRAIL`
- [ ] Review privileges via `DBA_SYS_PRIVS`, `DBA_TAB_PRIVS`, `DBA_ROLE_PRIVS`

> **Resume bullets:** Administered common and local users, roles, profiles, and
> system/object privileges under least-privilege principles. · Implemented unified
> auditing policies and reviewed audit trail output to verify access controls.

### O5 — Storage and undo

- [ ] Permanent, temporary and undo tablespaces
- [ ] Add/resize data files; autoextend
- [ ] Offline/online; read-only
- [ ] `ALTER DATABASE MOVE DATAFILE` (online)
- [ ] Undo management: `UNDO_RETENTION`, `RETENTION GUARANTEE`, read `V$UNDOSTAT`;
      provoke `ORA-01555 snapshot too old` with a tiny undo tablespace and explain why
      it happened (read consistency)
- [ ] Deferred segment creation: create a table and check `DBA_SEGMENTS` before and
      after the first insert
- [ ] Resumable space allocation: `ALTER SESSION ENABLE RESUMABLE`, fill a tablespace,
      watch `DBA_RESUMABLE`, add space, see the statement continue
- [ ] Write a tablespace-usage script (`DBA_DATA_FILES` + `DBA_FREE_SPACE`) and commit
      it to `oracle/sql/`
- [ ] Drop a tablespace including contents and data files

> **Resume bullets:** Managed permanent, temporary and undo tablespaces, including
> data file sizing, autoextend, online relocation and undo retention. · Developed SQL
> scripts to monitor tablespace utilization, free space and growth.

### O6 — Schema objects, SQL, PL/SQL

Tick each topic once you've written queries for it against HR or SH and can explain
the output. Keep the queries in `oracle/sql/practice/`.

Schema objects:

- [ ] Tables and data types; `ALTER TABLE` add/modify/drop column
- [ ] All constraint types, including `ON DELETE CASCADE`; enable, disable, defer
- [ ] Indexes: B-tree, composite, unique, bitmap, function-based
- [ ] Views (`WITH CHECK OPTION`, `WITH READ ONLY`), sequences, synonyms
- [ ] Global temporary tables vs private temporary tables (`ORA$PTT_`)
- [ ] A DML trigger that fills audit columns
- [ ] `FLASHBACK TABLE ... TO BEFORE DROP` from the recycle bin

Oracle-dialect SQL (where exam points are won or lost):

- [ ] Null functions: `NVL`, `NVL2`, `COALESCE`, `NULLIF`
- [ ] `DECODE` vs `CASE`
- [ ] Conversion and format models: `TO_CHAR`, `TO_DATE`, `TO_NUMBER`, `fm`/`RR`/`YYYY`
- [ ] Date arithmetic: `SYSDATE`, `ADD_MONTHS`, `MONTHS_BETWEEN`, `TRUNC`/`ROUND` on dates
- [ ] Joins: ANSI (inner, left/right/full outer, cross, `NATURAL`, `USING`) and the
      legacy `(+)` syntax
- [ ] Subqueries: single-row, multi-row (`IN`, `ANY`, `ALL`), correlated, `EXISTS`
- [ ] Set operators: `UNION`, `UNION ALL`, `INTERSECT`, `MINUS`
- [ ] Grouping: `GROUP BY`, `HAVING`, `ROLLUP`, `CUBE`, `GROUPING SETS`, `GROUPING()`
- [ ] Row limiting: `ROWNUM` vs `FETCH FIRST ... ROWS ONLY` / `OFFSET`
- [ ] Analytic functions: `RANK`, `DENSE_RANK`, `ROW_NUMBER`, `LAG`/`LEAD`, `OVER (PARTITION BY ...)`
- [ ] Hierarchical queries: `CONNECT BY`, `START WITH`, `LEVEL`
- [ ] DML: `INSERT ALL`, `MERGE`, transactions, `SAVEPOINT`, `ROLLBACK TO`
- [ ] SQL\*Plus: substitution variables (`&`, `&&`, `DEFINE`, `ACCEPT`), `SET`/`COLUMN` formatting

PL/SQL:

- [ ] Anonymous blocks, procedures, functions, a package
- [ ] Explicit and implicit cursors; cursor `FOR` loops
- [ ] Exception handling, including a user-defined exception

> **Resume bullets:** Created and managed tables, indexes, constraints, views,
> sequences, synonyms and triggers. · Wrote SQL and PL/SQL against Oracle sample
> schemas, including outer joins, correlated subqueries, analytic and hierarchical
> queries, and stored procedures with exception handling.

### O6b — Moving data

- [ ] Directory objects: `CREATE DIRECTORY`, `GRANT READ, WRITE`
- [ ] Data Pump export and import: full schema, single table, `REMAP_SCHEMA`,
      `INCLUDE`/`EXCLUDE`; read the log
- [ ] Data Pump over a database link with `NETWORK_LINK` (PDB to PDB)
- [ ] SQL\*Loader: write a control file, load a CSV, read the bad and discard files;
      conventional vs direct path
- [ ] External tables: `ORGANIZATION EXTERNAL` with the `ORACLE_LOADER` driver over
      the same CSV

> **Resume bullet:** Moved data between schemas and pluggable databases using Data
> Pump, SQL\*Loader and external tables.

### O7 — RMAN backup and recovery

- [ ] **Snapshot `pre-o7`**
- [ ] Archivelog mode; fast recovery area
- [ ] RMAN retention policy, channels, controlfile autobackup
- [ ] Level 0 and level 1 backups; `BACKUP VALIDATE`, `CROSSCHECK`, `LIST BACKUP`,
      `REPORT NEED BACKUP`
- [ ] **Delete a data file and recover it**
- [ ] **Recover from a lost control file**
- [ ] **Point-in-time recovery to an SCN or timestamp**
- [ ] **Full restore end to end**
- [ ] A cron'd Bash backup script with logging, committed to `oracle/scripts/`

Don't skip the bold ones. Taking a backup proves nothing; the restore is the skill,
and "have you ever actually done a recovery?" is a standard interview question.

> **Resume bullets:** Configured RMAN backup strategies in archivelog mode, including
> full and incremental backups, retention policies and the fast recovery area. ·
> Performed data file, control file, point-in-time and full database recoveries. ·
> Automated scheduled RMAN backups with Bash and cron.

### O8 — Performance

- [ ] `EXPLAIN PLAN` and `DBMS_XPLAN.DISPLAY` / `DISPLAY_CURSOR`
- [ ] Write a slow query, fix it with an index, prove it with the plan output
- [ ] `DBMS_STATS`: gather table and schema statistics
- [ ] Generate and read an AWR report; look at ASH data (licensing: see above)
- [ ] Blocking sessions and waits via `V$SESSION`, `V$LOCK`, `V$SESSION_WAIT`
- [ ] SQL Tuning Advisor on a problem statement

> **Resume bullets:** Analyzed query performance using execution plans, optimizer
> statistics, AWR/ASH and SQL Tuning Advisor, and fixed inefficient SQL through
> indexing and rewrites. · Diagnosed blocking locks and wait events with dynamic
> performance views.

### O9 — Patching

Release Updates need My Oracle Support access, which a personal lab won't have. Don't
ask to borrow an employer's support account: those are tied to customer contracts, and
the ask is likely to be refused. Work through these fallbacks instead, in order:

- [ ] **Snapshot `pre-o9`**
- [ ] OPatch tooling on the existing install: `opatch lsinventory`,
      `opatch prereq CheckConflictAgainstOHWithDetail`, `opatch util cleanup`;
      query `DBA_REGISTRY_SQLPATCH` and know what `datapatch` would do
- [ ] **Out-of-place patching, if a newer 19.x base is downloadable:** install it as a
      second Oracle Home, move the database to it, run `datapatch`. This is the
      modern patching model.
- [ ] **Optional:** a few hours on an Oracle Cloud Base Database Service trial, where
      the patching is real
- [ ] Write the Release Update procedure, including standby-first patching for O10,
      as a runbook: `oracle/runbooks/patching.md`

Write the resume claim to match what you actually did. "Documented the Release Update
procedure and ran OPatch prerequisite checks" is true and defensible. "Applied a
Release Update" is only true if you did.

> **Resume bullet (adjust to what you did):** Performed Oracle patch-readiness checks
> with OPatch, [executed out-of-place patching between Oracle Homes,] and documented
> the Release Update and standby-first patching procedure.

### O10 — Data Guard (high availability and disaster recovery)

HA/DR is the job posting's first responsibility, and standby-first patching is how
"near zero downtime patching" works. This section is the biggest single gain for the
job.

**Resources:** with the 8 GB VM, run the standby as a **second instance in the same
VM** — its own `db_unique_name` and data files, about 2.5–3 GB SGA each, shrinking the
primary's memory first. It teaches the same redo transport, broker and switchover
mechanics; it just loses the "two hosts" realism. With a 32 GB RAM upgrade, use two
VMs at 6 GB each instead.

- [ ] **Snapshot `pre-o10`**
- [ ] On the primary: `FORCE LOGGING`, standby redo logs, `db_unique_name`,
      `log_archive_config`, `log_archive_dest_2`
- [ ] Static listener registration for the standby
- [ ] Create a physical standby with
      `RMAN DUPLICATE TARGET DATABASE FOR STANDBY FROM ACTIVE DATABASE`
- [ ] Enable the Data Guard Broker; build the configuration in `DGMGRL`;
      `SHOW CONFIGURATION` reports `SUCCESS`
- [ ] Check redo transport and apply lag: `V$DATAGUARD_STATS`, `V$ARCHIVED_LOG`,
      `V$DATABASE` (`DATABASE_ROLE`, `PROTECTION_MODE`)
- [ ] Protection modes: switch between Maximum Performance and Maximum Availability,
      and explain the trade-offs, including Maximum Protection's
- [ ] **Switchover, then switch back**
- [ ] Open the standby read-only (Active Data Guard concepts; licensing: see above)
- [ ] Add standby-first patching to `oracle/runbooks/patching.md`

> **Resume bullets:** Configured an Oracle Data Guard physical standby for HA/DR,
> including redo transport, Data Guard Broker management and protection modes, and
> performed switchover and switchback. · Monitored redo transport and apply lag with
> Data Guard views and DGMGRL.

### O11 — Monitoring Oracle with Prometheus and Grafana

This is where your day job meets the new skill: production monitoring is what you
already do, and the posting asks for someone who "monitors DB performance, logs, disk
space and bottlenecks." A small version runs now, before phase 8 builds the full
monitoring stack.

Stack: [`stacks/oracle-monitoring/`](../../stacks/oracle-monitoring/) — Oracle's
database exporter, Prometheus and Grafana, kept small on purpose. Grafana is at
`http://homelab:3000` over Tailscale.

- [ ] Create a monitoring user in the PDB with only what the exporter needs
      (`CREATE SESSION`, `SELECT_CATALOG_ROLE`)
- [ ] Copy `.env.example` to `.env`, bring the stack up, and check
      `curl -s localhost:9161/metrics | grep oracledb_up` on the host returns `1`
- [ ] Prometheus target `oracledb` is `UP`
- [ ] A Grafana dashboard with 4–5 panels: up/down, sessions, tablespace used %, top
      wait classes, activity
- [ ] The tablespace alert rule fires when you fill a test tablespace past 85%, and
      clears when you add space
- [ ] Read the [OracleDown](../runbooks.md#oracledown) and
      [OracleTablespaceFull](../runbooks.md#oracletablespacefull) runbooks, and follow
      one while the alert is firing

When phase 8 arrives, fold the exporter into the main `monitoring` stack and retire
this one. In phase 17 the alert gets routed to your phone through ntfy.

> **Resume bullet:** Instrumented an Oracle 19c database with Prometheus and Grafana,
> including dashboards for sessions, tablespace utilization and wait events, alerting
> on tablespace growth, and an on-call runbook.

## Verification

- `ssh ol8` works from the lab; `lsnrctl status` lists the CDB and PDB services
- SQL Developer on the laptop connects through the SSH tunnel, off home Wi-Fi
- At least one full RMAN restore done from scratch
- `DGMGRL> SHOW CONFIGURATION` reports `SUCCESS`, and a switchover has been done and
  reversed
- The Grafana dashboard shows live Oracle metrics, and the tablespace alert has fired
  and cleared
- Every checkbox ticked, scripts and runbooks committed under `oracle/`, and
  `oracle/JOURNAL.md` has an entry per session
- The status line at the top of this file says **complete**

## Later phases that build on this

- **Phase 8 (monitoring):** move the O11 exporter into the main Prometheus stack
- **Phase 10 (restic):** include the RMAN backup directory in the restic backup
- **Phase 17 (alerting):** route the tablespace alert to ntfy
- **Phase 20 (Ansible):** codify the KVM packages, the DHCP reservation and the VM
  definition

## Troubleshooting

- **`virt-install` says KVM isn't available:** VT-x is off in the BIOS, or you haven't
  logged back in since joining the `kvm` group.
- **`runInstaller` fails its OS check on OL8:** `CV_ASSUME_DISTID=OEL7.8` wasn't
  exported in the same shell. If it still fails, see the OL7/OL8 decision above.
- **VM didn't get 192.168.122.19:** the MAC in `virt-install` doesn't match the DHCP
  reservation. Compare with `virsh domiflist ol8-oracle` and
  `virsh net-dumpxml default`.
- **Host feels sluggish:** the VM has half the RAM. Shut it down when you're not
  studying.
- **Client can't connect:** check the tunnel is up, the listener is running
  (`lsnrctl status`), and the VM's firewall allows 1521 (O1.11).
- **Host disk filling up:** old snapshots. `virsh snapshot-list ol8-oracle`, then
  delete the ones you no longer need.
- **Exporter shows `oracledb_up 0`:** wrong connect string or password in `.env`, or
  the monitoring user lacks `CREATE SESSION`. Test with
  `sqlplus monitor/<pw>@192.168.122.19:1521/<pdb-service>` from the VM.
