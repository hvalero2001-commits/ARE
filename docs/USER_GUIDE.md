# ARE User Guide

## Introduction

This guide describes the operational use of ARE (Abuse Reputation Engine).

ARE processes security events, keeps persistent reputation and state information, evaluates the
configured policies, and applies decisions through the corresponding backend.

---

# Requirements

ARE must be installed and validated.

Verify the installation with:

```bash
are-installer verify
```

The official interface is available through:

```bash
are
```

---

# Command interface

ARE's operational commands are:

```text
are admin
are stats
are trends [days]
are top
are score <IP>
are events <IP>
are found <IP> <JAIL>
are ban <IP> <JAIL>
are unban <IP>
are external-unban <IP> [JAIL]
are policy-compare <IP>
are decay-dry-run
are decay-apply
```

The Installer Engine uses:

```text
are-installer
```

with the operations:

```text
are-installer install
are-installer upgrade
are-installer repair
are-installer verify
are-installer uninstall
```

The official entry point is installed as `/usr/local/sbin/are`, with the ARE Core in `/opt/are`.

---

# ARE ADMIN

Command-line administration interface:

```bash
are admin
```

Organized into seven branches:

```text
1) Jails / Profiles
2) Categories
3) Sensors
4) Policy
5) State / Reputation
6) Decay
7) Configuration
0) Exit
```

Each submenu offers `0) Back` to go up one level, and `x) Exit` as a shortcut to close the whole
program from anywhere in the navigation, without having to return to the root menu first.

Write operations (creating, modifying, or deleting a profile; running decay) are recorded in an
audit log, with user, date, and details of the action:

```text
/var/log/are/admin_audit.log
```

## Jails / Profiles

Manages the relationship between a jail (from Fail2Ban, or from a callback sensor such as
`mod_evasive`) and its reputation category, weight, confidence, and decay.

```text
1) List
2) Create
3) Modify
4) Delete
5) Validate
6) Export
7) Import
```

When creating or modifying a profile, the system assists with choosing weight and confidence: a
curated reference scale if one exists for the category, or statistics (minimum, maximum, average)
computed over the profiles that already exist in that category.

`Export` generates a timestamped file in `${ARE_DATA}/backups/jail_profiles/`, with all of the
server's profiles. `Import` lets you select one of those files and apply it, asking once whether
to overwrite or keep the profiles that already exist locally. This mechanism lets you replicate
profile calibration across servers without recreating them one by one.

## Categories

Read-only view of the reputation category catalog and its configured thresholds, and of the
per-category accumulated scores for a specific IP.

## Sensors

Status and configuration of the active sensors (Fail2Ban and SpamAssassin by polling,
`apache_evasive` by callback), read dynamically from the sensor registry.

```text
1) Status
2) Configuration
3) Enable/Disable
```

`Enable/Disable` turns a sensor on or off. For polling-pattern sensors, it controls their systemd
timer directly. For callback-pattern sensors (`apache_evasive`), the registry entry is marked, but
the actual effect still depends on configuration outside ARE (see Roadmap).

## Policy

Read-only view of the Policy Engine's effective configuration: global thresholds, per-category
thresholds, recidivism multipliers, and Ban Lifecycle levels. The validation option checks that
the thresholds are in ascending order and that each category with a defined threshold has its
corresponding rule implemented.

## State / Reputation

```text
1) Query IP
2) Events
3) Top
4) Statistics
5) Trends
```

`Trends` shows the daily evolution of activity (total events, by action type, and distinct IPs)
over a configurable window of days.

## Decay

```text
1) Status
2) Dry-run
3) Run
```

## Configuration

```text
1) View
2) Validate
3) System status
```

---

# Statistics

Query general system information:

```bash
are stats
```

The `stats` command provides operational system information.

Among the information included in the Dashboard is jail activity.

The `TOP JAILS` section uses the `events` table as its source and excludes internal events such as
`fail2ban` and `policy_apply`.

---

# Trends

Query the daily evolution of recorded activity:

```bash
are trends [days]
```

By default it shows the last 7 days. Each row includes total events, a breakdown by action type
(`FOUND`, `BAN`, `EXTERNAL_UNBAN`), and the distinct IPs involved that day.

---

# Top threats

Query the top addresses by reputation:

```bash
are top
```

---

# Query reputation

Query the reputation of an IP address:

```bash
are score <IP>
```

Example:

```bash
are score 192.168.1.10
```

Reputation information is kept in SQLite along with the data for hosts, events, jails, jail
profiles, and sanction state.

ARE's persistent structure includes:

```text
hosts
events
config
jails
reputation
reputation_scores
jail_profile
sanction_state
```

`reputation_scores` keeps the per-category score in normalized form (one row per IP and
category), which makes it possible to add new categories without changing the database structure
or the code of the functions that query it.

The database is located at:

```text
/var/lib/are/are.db
```

---

# Query events

Query the recorded events for an IP address:

```bash
are events <IP>
```

Example:

```bash
are events 192.168.1.10
```

Events make up the activity history ARE processes, and are also used by the jail statistics and
the time-based trends.

---

# Process a FOUND event

Manually process a `FOUND` event:

```bash
are found <IP> <JAIL>
```

Example:

```bash
are found 192.168.1.10 modsec-protocol
```

The processing flow of a `FOUND` event is:

```text
FOUND
  │
  ▼
Reputation
  │
  ▼
State
  │
  ▼
Policy (per-category evaluation)
  │
  ▼
Apply
```

The `JAIL` must have a managed profile (see ARE ADMIN, Jails / Profiles). A jail without a profile
is discarded without generating an event, with no need to keep a fixed list in the sensor's code.

---

# Ban

Process a ban event:

```bash
are ban <IP> <JAIL>
```

The jail provides the context ARE uses to process the event.

Enforcement decisions include `FILTER`, `TEMP_BAN`, and `BAN`.

The backend uses separate sets for filtering and blocking, for both IPv4 and IPv6.

When the computed sanction exceeds the maximum timeout IPSet supports, the system automatically
clamps the applied duration to that limit and records the situation in the log.

---

# Unban

Remove an active sanction:

```bash
are unban <IP>
```

The `UNBAN` flow is part of the lifecycle of IP addresses and of the backend.

---

# External unban

Process an `EXTERNAL_UNBAN` event:

```bash
are external-unban <IP> [JAIL]
```

External `UNBAN` events are recorded as:

```text
EXTERNAL_UNBAN
```

`EXTERNAL_UNBAN` does not directly release the IP address.

ARE re-evaluates the address through the Policy Engine and applies the resulting decision.

---

# Compare policy decisions

Run the active decision engine and a reference evaluation on the same IP at the same time, without
applying any decision:

```bash
are policy-compare <IP>
```

Useful for validating the Policy Engine's behavior against real production data before adopting a
change to configuration or thresholds.

---

# Reputation Decay

ARE provides Reputation Decay to progressively reduce the reputation of IP addresses with no
recent activity.

The documented parameters are:

```text
DECAY_MIN_AGE=86400
DECAY_FACTOR=0.95
```

This corresponds to a minimum of 24 hours without activity and an initial reduction factor of
`0.95`.

The reduction is computed on the IP's aggregate total score and redistributed proportionally
across its active categories, so that an IP with activity spread across several categories does
not decay faster than one with activity concentrated in a single category, given the same total
score.

## Simulation

View the candidate IPs without changing reputation:

```bash
are decay-dry-run
```

The simulation shows the candidates and the estimated score.

## Applying

Apply the decay:

```bash
are decay-apply
```

The operation:

* reduces the score, redistributed proportionally across categories;
* updates the state;
* re-evaluates the Policy Engine;
* updates `last_decay`;
* avoids applying multiple reductions within the same window.

Decay does not directly make changes to the firewall. Automatic release only happens when the
policy returns `ALLOW`; `WATCH`, `FILTER`, `TEMP_BAN`, and `BAN` do not trigger automatic release.

The mechanism is integrated with systemd through:

```text
are-fail2ban-decay.service
are-fail2ban-decay.timer
```

---

# Sensors

## Fail2Ban (polling pattern)

ARE maintains a sensor for Fail2Ban that reads the log periodically.

The events the sensor processes are:

```text
FOUND
EXTERNAL_UNBAN
```

The sensor uses a persistent cursor to process new events, and validates each jail dynamically
against `jail_profile` — a jail without a managed profile is discarded.

## SpamAssassin (polling pattern)

ARE maintains a sensor for SpamAssassin that reads the MTA log periodically (adapter implemented
and validated: Exim). It classifies messages flagged as spam into three severity bands by score,
each with its own managed profile. It reports to the `SOCIAL` category.

## Apache / mod_evasive (callback pattern)

A sensor invoked directly by Apache the moment `mod_evasive` detects a flood, without waiting for a
periodic read cycle. It reports to the `DOS` category.

---

# Firewall Backend restoration

IPSet does not natively keep its contents across operating-system reboots. At boot, ARE restores
the active sanctions (permanent and temporary — preserving the exact remaining time of the latter)
and the IPs in filtering state, from the database — not from a frozen firewall snapshot.

This mechanism runs exactly once per boot, through:

```text
are-restore-ipsets.service
```

---

# Installer Engine

The Installer Engine manages the installation lifecycle through:

```bash
are-installer install
are-installer upgrade
are-installer repair
are-installer verify
are-installer uninstall
```

The operations use a single Installer Core and reuse its modules depending on the operation.

## Install

```bash
are-installer install
```

Installation creates the required structure, installs the Core, the configuration, the database,
the links, permissions, services, timers, and logrotate, and performs the final validation.

Installation must not use the same directory as both source and target.

## Upgrade

```bash
are-installer upgrade
```

`upgrade` requires an existing installation.

It updates the Core and the managed components without overwriting the existing persistent
configuration. The operation preserves the persistent data and updates the links, logging,
systemd, and logrotate.

## Repair

```bash
are-installer repair
```

`repair` acts on an incomplete installation.

It restores the necessary components and re-validates the installation.

## Verify

```bash
are-installer verify
```

Verification checks, among other things:

* file and directory integrity;
* links;
* permissions;
* SQLite structure;
* runtime;
* IPSet;
* systemd;
* logrotate.

The installation checks include the tables:

```text
config
hosts
jails
events
jail_profile
reputation
reputation_scores
sanction_state
```

## Uninstall

```bash
are-installer uninstall
```

Uninstallation removes the product's managed components, including the Core, systemd units, links,
and logrotate configuration.

Persistent data and configuration are preserved:

```text
Configuration
Data
Logs
```

---

# Configuration

ARE uses the following configuration files:

```text
config.conf
policy.conf
whitelist.conf
```

These files are treated as persistent configuration by the Installer Engine and are not
overwritten when administrator-managed configuration already exists.

The configuration links are part of the installation and are checked by `are-installer verify`.

---

# Main locations

Core:

```text
/opt/are
```

Persistent data:

```text
/var/lib/are
```

Logs:

```text
/var/log/are
```

Executable links:

```text
/usr/local/sbin
```

systemd units:

```text
/etc/systemd/system
```

---

# Operational flow

ARE's general flow is:

```text
Event
   │
   ▼
Reputation
   │
   ▼
State
   │
   ▼
Policy (per-category)
   │
   ▼
Ban Lifecycle
   │
   ▼
Apply
   │
   ▼
Firewall
```

Fail2Ban and Apache/mod_evasive act as event sources through the Sensor Framework.

ARE maintains the reputation and state, determines the decision through the Policy Engine, and
carries out the corresponding action through the backend.

---

# Best practices

* Verify the installation after maintenance operations.
* Keep the configuration protected.
* Keep backups of the persistent data.
* Periodically review events, statistics, and trends.
* Monitor the status of the sensors and the applied decisions.
* Use `policy-compare` before adopting threshold changes in production.
* Export the `jail_profile` catalog before major changes, so you can restore the calibration if
  something goes wrong.

---

# Troubleshooting

### Incomplete installation

Run:

```bash
are-installer verify
```

If the installation is detected as incomplete:

```bash
are-installer repair
```

### Existing installation

To upgrade an existing installation:

```bash
are-installer upgrade
```

### Query an IP

```bash
are score <IP>
```

### Query events

```bash
are events <IP>
```

### Query statistics

```bash
are stats
```

### Query decay

```bash
are decay-dry-run
```

### Compare the decision engine

```bash
are policy-compare <IP>
```

---

# References

For more information, see:

```text
README.md
docs/ARCHITECTURE.md
docs/DESIGN.md
docs/INSTALL.md
docs/BAN_LIFECYCLE.md
docs/DEVELOPMENT.md
docs/SECURITY.md
docs/CHANGELOG.md
docs/ROADMAP.md
```

This guide contains only procedures and capabilities backed by the documentation and the verified
implementations available for ARE.

---

> 🇪🇸 Versión en español (referencia): [`USER_GUIDE.es.md`](USER_GUIDE.es.md)
