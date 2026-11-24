# Phase 21 — Oracle 19c DBA Lab (KVM virtual machine)

## Goal

A real Oracle Database 19c install on Oracle Linux 8, running as a KVM virtual machine
on the T480, used to work through DBA skills end to end: install, instance management,
multitenant, security, storage, SQL/PL-SQL, RMAN backup and recovery, tuning and
patching.

This phase was added out of numeric order to prepare for an Oracle 19c DBA role. It
runs **right after phase 7 (Docker)** and before phase 8 (monitoring) — see the pacing
schedule. The fuller task list, with the resume bullet each part earns, lives in the
Notion note *Junior Database Administrator → Oracle 19c Home Lab — Build Checklist*.
Only add a resume bullet once you've genuinely finished that part.

## Why a VM and not a container

The job lists "installation, configuration, and patching" of 19c. A container image
skips the install, the OS prep and OPatch — the exact parts you'll be asked about. So
19c gets a full VM. (For quick SQL-only practice later, an Oracle Database Free
container is fine on top of this, not instead of it.)

## Prerequisites

- Phase 7 done (Docker works; the host is hardened and on Tailscale)
- VT-x enabled in the BIOS (phase 1 didn't cover this): ThinkPad BIOS →
  **Security → Virtualization → Intel Virtualization Technology: Enabled**
  (VT-d too, while you're there)
- A free Oracle account (needed to download 19c)
- ~70 GB free on the SSD, and 8 GB of RAM to give the VM while it runs

## Resource budget

| | RAM | Disk |
|---|---|---|
| Oracle VM (while running) | 8 GB | 60 GB qcow2 |
| Debian host + Docker practice | ~8 GB left | rest of the SSD |

The VM is **not** set to autostart. Start it when you study, shut it down after
(`virsh shutdown ol8-oracle`), so the RAM goes back to the Docker stacks once those
exist.

## Steps

### O0 — KVM host and Oracle Linux 8 VM

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
3. Download the Oracle Linux 8 DVD ISO (free, from yum.oracle.com) to
   `/var/lib/libvirt/images/`.
4. Create the VM headless, with the installer on the serial console:
   ```
   sudo virt-install \
     --name ol8-oracle --memory 8192 --vcpus 2 \
     --disk path=/var/lib/libvirt/images/ol8-oracle.qcow2,size=60,format=qcow2 \
     --location /var/lib/libvirt/images/OracleLinux-R8-U*-x86_64-dvd.iso \
     --os-variant ol8.0 --network network=default \
     --graphics none --extra-args 'console=ttyS0,115200n8 inst.text'
   ```
   Pick a minimal install, set a static IP on the `default` network (or note its
   DHCP address with `virsh domifaddr ol8-oracle`), and enable SSH.
5. Add the VM to `~/.ssh/config` on the lab host as `ol8` and SSH in.
6. OS prep inside the VM:
   ```
   sudo dnf install -y oracle-database-preinstall-19c
   ```
   This creates the `oracle` user, `oinstall`/`dba` groups, kernel parameters and
   limits. Review what it changed in `/etc/sysctl.d/` and `/etc/security/limits.d/`.
7. Download Oracle Database 19c for Linux x86-64 (`LINUX.X64_193000_db_home.zip`) and
   copy it to the VM.

- [ ] VM boots, `ssh ol8` works, preinstall RPM completed cleanly, zip staged

### O1 — Install and configure 19c

- [ ] Unzip into `ORACLE_HOME` and run `./runInstaller` (software only), with
      `ORACLE_BASE`, `ORACLE_HOME` and the inventory set
- [ ] Create a CDB with one PDB using `dbca`
- [ ] Configure the listener; `lsnrctl status` shows the services
- [ ] Configure `tnsnames.ora`; connect with SQL\*Plus
- [ ] Set up `oraenv` and a systemd unit (or `dbstart`) for startup
- [ ] Install the HR and SH sample schemas

Connecting from your laptop (SQL Developer, Toad trial) without exposing anything — an
SSH tunnel through the lab over Tailscale:
```
ssh -L 1521:<vm-ip>:1521 homelab
```
then point the client at `localhost:1521`.

### O2 — Instance management

- [ ] Step through `STARTUP NOMOUNT` → `MOUNT` → `OPEN`
- [ ] Each shutdown mode, including recovering after `ABORT`
- [ ] PFILE ↔ SPFILE; change a parameter with each `SCOPE`
- [ ] Find and read the alert log and a trace file in the ADR
- [ ] Query `V$SGA`, `V$SGASTAT`, `V$PROCESS`, `V$PARAMETER`

### O3 — Multitenant

- [ ] `SHOW CON_NAME`, `V$PDBS`, `V$CONTAINERS`
- [ ] Create a PDB from `PDB$SEED`; clone a PDB
- [ ] Open/close and `SAVE STATE`
- [ ] Unplug to XML and plug back in
- [ ] `ALTER SESSION SET CONTAINER`

### O4 — Users, privileges, security

- [ ] Local vs common (`C##`) users
- [ ] Roles; system/object privileges; `WITH ADMIN OPTION` / `WITH GRANT OPTION`
- [ ] A profile with password complexity and resource limits
- [ ] Lock, unlock, expire, reset accounts
- [ ] A least-privilege read-only reporting account
- [ ] Unified auditing policy; query `UNIFIED_AUDIT_TRAIL`

### O5 — Storage

- [ ] Permanent, temporary and undo tablespaces
- [ ] Add/resize data files; autoextend
- [ ] Offline/online, read-only
- [ ] `ALTER DATABASE MOVE DATAFILE`
- [ ] A tablespace-usage script (`DBA_DATA_FILES` + `DBA_FREE_SPACE`) — save it in
      `oracle/sql/` in this repo

### O6 — Schema objects, SQL, PL/SQL

- [ ] Tables, all constraint types (enable/disable/defer), index types
- [ ] Views, sequences, synonyms, an audit-column trigger
- [ ] 100+ queries against HR/SH (joins, subqueries, `MERGE`, `CONNECT BY`, analytics)
- [ ] PL/SQL: procedures, functions, a package, cursors, exception handling
- [ ] `FLASHBACK TABLE` from the recycle bin

Weekday evenings are fine for O6 — it's the part that's mostly typing SQL.

### O7 — RMAN backup and recovery

- [ ] Archivelog mode; fast recovery area
- [ ] RMAN retention, channels, controlfile autobackup
- [ ] Level 0 and level 1 backups; `VALIDATE`, `CROSSCHECK`, `LIST`, `REPORT NEED BACKUP`
- [ ] **Delete a data file and recover it**
- [ ] **Recover from a lost control file**
- [ ] **Point-in-time recovery to an SCN or timestamp**
- [ ] **Full restore end to end**
- [ ] A cron'd Bash backup script with logging — save it in `oracle/scripts/`

Don't skip the bold ones. Taking a backup proves nothing; the restore is the skill.
Take a VM snapshot first (`virsh snapshot-create-as ol8-oracle pre-o7`) so a bad
drill costs you minutes, not the install.

### O8 — Performance

- [ ] `EXPLAIN PLAN` / `DBMS_XPLAN`
- [ ] Make a slow query, fix it with an index, prove it with the plan
- [ ] `DBMS_STATS`
- [ ] AWR and ASH reports (lab-only — these need the Diagnostics Pack licence in
      production)
- [ ] Blocking sessions and waits via `V$SESSION`, `V$LOCK`
- [ ] SQL Tuning Advisor

### O9 — Patching

- [ ] `opatch lsinventory`
- [ ] Apply a Release Update or one-off patch. RUs need My Oracle Support access —
      ask whether Halvik has a CSI you can use. If not, document the procedure and
      practise the `opatch` prerequisite checks.
- [ ] `datapatch` and confirm in `DBA_REGISTRY_SQLPATCH`

## Verification

- `ssh ol8` works from the lab; `lsnrctl status` lists the CDB and PDB services
- SQL Developer on the laptop connects through the SSH tunnel, off home Wi-Fi
- Every checkbox above is ticked, and the scripts are committed under `oracle/`
- You've done at least one full RMAN restore from scratch

## Later phases that build on this

When the homelab picks back up, these make the Oracle lab part of the rest of it:

- **Phase 8 (monitoring):** add an Oracle exporter (e.g. `oracledb_exporter`) to the
  Prometheus stack and a Grafana dashboard for sessions, tablespace use and waits
- **Phase 10 (restic):** include the RMAN backup directory in the restic backup
- **Phase 17 (alerting):** a tablespace-usage alert to ntfy, with a runbook entry
- **Phase 20 (Ansible):** codify the KVM host packages and VM definition

## Troubleshooting

- **`virt-install` says KVM isn't available:** VT-x is off in the BIOS, or you
  haven't logged back in since joining the `kvm` group.
- **19.3 `runInstaller` fails its OS check on Oracle Linux 8:** a known issue with the
  19.3 base release on OL8. Common workarounds are `export CV_ASSUME_DISTID=OEL7.8`
  before running it, or installing with `-applyRU` and a newer RU. Check Oracle's
  current install notes before relying on either.
- **Host feels sluggish:** the VM has half the RAM. Shut it down when you're not
  studying.
- **Client can't connect:** check the tunnel is up, the listener is running
  (`lsnrctl status`), and `firewalld` in the VM allows 1521
  (`sudo firewall-cmd --add-port=1521/tcp --permanent && sudo firewall-cmd --reload`).
