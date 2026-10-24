# ARE Installation Guide

## Introduction

This document describes the installation lifecycle of ARE (Abuse Reputation Engine).

ARE v2 consolidates the product's own identity and structure, replacing the historical layout
used by `f2b-ipset` in v1.1. The installation structure, the managed components, and their
locations are defined by `manifest/product.sh`.

The Installer Engine manages these operations:

```text
install
upgrade
repair
verify
uninstall
```

These operations keep the product Core, the configuration, and the persistent data separate.

---

# Requirements

ARE requires a Linux system with:

* Bash
* SQLite 3
* IPSet
* systemd
* `root` privileges

Fail2Ban and ModSecurity are ARE integrations. They do not replace the base dependencies that
the Installer verifies directly.

Since v2.3, if a required dependency is missing, the Installer itself installs it automatically
using the system's native package manager (`apt-get`, `dnf`, or `yum`, in that order of
preference) — see the "Remote installation" section below.

---

# Installation structure

The official ARE v2 structure is:

```text
/opt/are
    Product Core and components

/opt/are/config
    Product configuration

/var/lib/are
    Persistent data

/var/lib/are/are.db
    ARE database

/var/log/are
    Logs

/usr/local/sbin
    Official executable links

/etc/systemd/system
    systemd units

/etc/logrotate.d
    logrotate configuration
```

This structure is part of the official definition of ARE v2.

The persistent database used by ARE v2 is:

```text
/var/lib/are/are.db
```

Among others, the structure includes the tables:

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

`reputation_scores` stores the per-category score in normalized form, which makes it possible to
add new reputation categories without changing the database schema or the code of the query
functions.

The historical data from the previous structure was migrated into ARE's new persistent database
during the evolution toward v2.

---

# Product Manifest

The file:

```text
manifest/product.sh
```

is the official reference the Installer uses to determine the components managed by ARE.

The Manifest centralizes:

* product identity and version;
* installation structure;
* configuration;
* persistent data;
* systemd units;
* executable links;
* executable files;
* logrotate configuration;
* exclusions.

The Installer uses the values defined by the Manifest instead of maintaining a second,
independent definition of the product structure.

---

# Source tree

The install, upgrade, and repair operations use the source tree that contains `are-installer`.

The source tree must be different from the installed target.

This lets an upgrade copy the Core from a source version over an existing installation without
using the live installation as the origin.

If the source tree and the target resolve to the same directory, the operation must abort with
an error.

---

# Initial installation

Installation is run with:

```bash
are-installer install
```

The operation corresponds to a fresh installation.

The general flow is:

```text
Check root
       |
       v
Check dependencies
       |
       v
Prepare environment
       |
       v
Detect state
       |
       v
Create structure
       |
       v
Install Core
       |
       v
Install initial configuration
       |
       v
Create official links
       |
       v
Apply permissions
       |
       v
Initialize database
       |
       v
Prepare logging
       |
       v
Install systemd
       |
       v
Install logrotate
       |
       v
Validate installation
```

The `install` operation is only for a fresh installation.

If ARE is already installed, use:

```bash
are-installer upgrade
```

If the installation is incomplete, use:

```bash
are-installer repair
```

---

# Remote installation

Since v2.3, ARE does not require cloning the repository with git in order to install. A brand-new
server, with no ARE files present at all, can be installed with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/hvalero2001-commits/ARE/main/scripts/install.sh | sudo bash
```

The `sudo` goes at the end of the pipe (applied to `bash`, not to `curl`) — otherwise root
privilege would not reach the script that actually performs the installation.

This bootstrap (`scripts/install.sh`):

1. queries the GitHub API for the latest published release (or a specific version, via the
   `ARE_VERSION` environment variable);
2. downloads the corresponding `.tar.gz` package;
3. verifies its checksum (`.sha256`);
4. extracts it to a temporary directory;
5. delegates to `are-installer install` from that extracted tree.

The same mechanism can upgrade an existing installation:

```bash
curl -fsSL https://raw.githubusercontent.com/hvalero2001-commits/ARE/main/scripts/install.sh | sudo bash -s -- upgrade
```

or, equivalently, from an already-active installation:

```bash
are-installer upgrade --remote
```

which internally delegates to the same bootstrap, without duplicating the download-and-verify
logic.

## Checking whether a newer version exists

Read-only, without downloading or changing anything:

```bash
are-installer check-updates
```

It compares the installed version (`PRODUCT_VERSION`, read from the active manifest itself)
against the latest published release, and reports whether a newer one is available.

## Missing dependencies

The dependency auto-installer (see the "Requirements" section) runs automatically, without
prompting, during `install`, `upgrade`, and `repair` — on both the remote path and the local
source-tree path. `bash` and `systemctl` are excluded from this mechanism: their absence would
mean a system in a state that needs manual intervention, not a blind automatic install.

---

# Initial configuration

Configuration is part of the product-managed area but is kept separate from the operational Core.

During a fresh installation, the configuration files defined by the Manifest are created.

An existing configuration must not be replaced arbitrarily during maintenance operations.

Separating Core, configuration, and persistent data is one of the principles established for
ARE v2.

---

# Executable links

ARE v2 provides the following official commands:

```text
are
are-installer
are-fail2ban-sensor
```

The links are managed by the Product Manifest.

The main command is established as:

```text
/usr/local/sbin/are -> /opt/are/are.sh
```

The Installer also ensures `/usr/local/sbin` is on `root`'s `PATH` during the operations:

```text
install
upgrade
repair
```

The `PATH` modification is applied idempotently.

**Note:** this `PATH` change is written to `/root/.bash_profile`, and only **new** terminal
sessions opened after the installation read it automatically (a new `ssh`, for example). A
terminal that was already open before installing/upgrading ARE does not reload its in-memory
`PATH` on its own; it requires a manual `source /root/.bash_profile`, or simply opening a new
session.

---

# Upgrade

An upgrade is run with:

```bash
are-installer upgrade
```

The operation requires an existing installation.

The source tree used for the upgrade must correspond to the version you want to install and must
be different from the installed tree.

The process updates the components managed by the Manifest and preserves the persistent data.

The goal of `upgrade` is to update the Core without arbitrarily replacing:

```text
configuration
database
historical reputation
persistent state
```

ARE v2 explicitly defines `upgrade` as the operation meant to update an existing installation
while keeping the persistent data.

Alternatively, `are-installer upgrade --remote` performs the same operation without needing a
local source tree — see the "Remote installation" section. **Warning:** this variant does not
compare the installed version against the available one before acting; it always applies the
latest published release, which can downgrade an installation on a newer development branch.
Verify with `are-installer check-updates` before using `--remote` if that is a concern.

---

# Repair

A repair is run with:

```bash
are-installer repair
```

It is meant for an existing installation that does not meet the conditions required to be
considered complete.

The goal is to rebuild whatever managed components are necessary to recover a working
installation.

Repair preserves the system's persistent information.

Do not use `repair` as a substitute for `upgrade` when a complete installation already exists.

---

# Verification

Verification is run with:

```bash
are-installer verify
```

The operation first determines the state of the installation.

A valid installation must have the components required by the Product Manifest and the elements
needed to function.

Verification checks, as applicable:

* component integrity;
* official links;
* executable commands;
* permissions;
* database;
* IPSet sets;
* systemd units;
* logrotate configuration;
* functional runtime execution.

Validating an installation does not deliberately modify its configuration or its persistent data.

---

# Systemd

ARE v2 uses systemd to integrate the product's operational components.

The Reputation Decay mechanism is part of the v2 operational cycle through:

```text
are-fail2ban-decay.service
are-fail2ban-decay.timer
```

The service runs the phases:

```text
dry-run
apply
```

The Firewall Backend restoration at system boot, introduced in v2.1, runs exactly once per boot
through:

```text
are-restore-ipsets.service
```

This service repopulates the IPSet sets from the database, since IPSet does not natively keep its
contents across reboots.

The Installer manages the units declared by the Product Manifest.

---

# Fail2Ban

ARE maintains the Sensor Framework for the Fail2Ban integration.

The events processed by the sensor are:

```text
FOUND
EXTERNAL_UNBAN
```

The sensor uses a persistent offset to process new events, and validates each jail dynamically
against `jail_profile`.

The Fail2Ban integration lets external events feed into ARE's operational flow without turning
Fail2Ban into the product's central reputation mechanism.

---

# Uninstall

Uninstallation is run with:

```bash
are-installer uninstall
```

Its goal is to remove the ARE-managed components from the system.

The operation removes the Core components, executable links, systemd units, and logrotate
configuration managed by the product.

Persistent data is not part of the normal Core removal.

Therefore, uninstallation separately preserves:

```text
configuration
persistent data
database
historical reputation
logs
```

Separating installed software from persistent data makes it possible to remove ARE without
automatically deleting the system's historical information.

---

# Evolution from v1.1

ARE v2 is built on the functional foundation developed in the v1.1 branch.

The v1.1 branch introduced the initial Sensor Framework for Fail2Ban and consolidated the
reputation model that v2 later continues.

The evolution toward v2 mainly changes the product's identity and operational structure:

```text
ARE v1.1
    |
    | historical f2b-ipset structure
    v
ARE v2.0
    |
    +-- /opt/are
    +-- /opt/are/config
    +-- /var/lib/are
    +-- /var/log/are
    +-- Product Manifest
    +-- Installer Engine
    +-- Reputation Decay
    +-- ARE ADMIN
```

Version 2.0 officially establishes `/opt/are` as the product Core and `/var/lib/are` as the
persistent data location.

---

# Usage

## Install

From an independent source tree:

```bash
are-installer install
```

Or remotely, without git or a local source tree (see "Remote installation"):

```bash
curl -fsSL https://raw.githubusercontent.com/hvalero2001-commits/ARE/main/scripts/install.sh | sudo bash
```

## Upgrade

From the source tree of the version you want to install:

```bash
are-installer upgrade
```

Or remotely:

```bash
are-installer upgrade --remote
```

## Repair

From a valid source tree:

```bash
are-installer repair
```

## Verify

```bash
are-installer verify
```

## Check for available updates

```bash
are-installer check-updates
```

## Uninstall

```bash
are-installer uninstall
```

---

# Maintenance principle

The Installer Engine keeps three areas separate:

```text
Product Core
       |
       +---- configuration
       |
       +---- persistent data
```

Maintenance operations must act only on the components corresponding to the requested operation.

The Product Manifest is the single reference for the components the Installer manages, while the
persistent information stays separate from the Core.

ARE v2 thus continues the evolution begun in v1.1 without conflating the Installer documentation
with the script's internal implementation documentation.

---

> 🇪🇸 Versión en español (referencia): [`INSTALL.es.md`](INSTALL.es.md)
