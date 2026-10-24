# ARE Roadmap

## Introduction

This document defines the planned evolution of ARE (Abuse Reputation Engine).

The Roadmap describes the project's technical direction and serves as a reference for planning new
capabilities without compromising the stability of the core.

Versions represent technical goals, not release dates.

Every new feature must respect the project's architecture and official methodology.

---

# Project status

Latest stable release:

```text
v2.8.3
```

Status:

```text
Production
```

The current stable version is running on the main production server and continues to be
consolidated and maintained. The technical detail of each version is documented in `docs/TODO.md`.

---

# v1.0.x

## Goal

Building and stabilizing the ARE core.

## Status

✔ Completed

## Capabilities added

* Reputation Engine
* State Engine
* Policy Engine
* Firewall Backend
* SQLite
* Dashboard
* Fail2Ban integration
* ModSecurity integration
* IPv4 support
* IPv6 support

---

# v1.1

## Goal

Consolidate the product and extend its operational lifecycle.

## Status

✔ Completed

## Features

### Installer Engine

* install
* upgrade
* repair
* verify
* uninstall
* installation-state detection
* persistent-configuration protection
* persistent-data preservation
* installation validation
* uninstallation preserving configuration, data, and logs

The `install`, `upgrade`, and `repair` operations use a source Core separate from the live
installation when they need to copy the product's components.

Automatic package generation, download, extraction, and staging are not part of the current
Installer.

### Sensor Framework

* sensor architecture
* first official Fail2Ban Sensor (`FOUND`)
* processing through a persistent offset
* `--dry-run` execution
* `--execute` execution

### Installer Manifest

* official definition of the managed components
* centralized product structure

### Dashboard

* TOP JAILS
* statistics expansion
* separation between events and reputation

### Reputation Engine

New categories:

* ANOMALY
* MALWARE
* DOS
* SOCIAL

### Documentation

* complete reorganization
* documentation normalization
* documentation in sync with the code

---

# v2.0

## Goal

Consolidate the product's own identity (migration from `f2b-ipset`), add a complete administration
interface, and evolve the decision engine from a total-score model to a per-category evaluation one.

## Status

✔ Completed — released as an official release (`v2.0.0`)

## Features added

They replace and go beyond what was originally planned for `v1.2`/`v1.3` in this same document
(Decay Engine, dynamic rules, category correlation, expanded metrics) — see full detail in
`docs/CHANGELOG.md` and `docs/TODO.md`.

### Product Manifest and Installer

* `manifest/product.sh` as the single source of truth for the product's components
* official installation in `/opt/are`, leaving behind the historical `f2b-ipset` identity

### Reputation Decay

* complete Decay Engine (`dry-run` / `apply`), with scheduled execution via systemd

### Administration Interface (ARE ADMIN)

* complete CLI (`are.sh admin`), 7 branches: Jails/Profiles, Categories, Sensors, Policy,
  State/Reputation, Decay, Configuration
* audit log of write operations
* banner with server identification, for multi-node environments

### Category-based Policy Engine

* per-category risk evaluation, with its own rule and a configurable threshold per category
* recidivism risk multiplier
* safety floor: never less strict than the aggregate total score
* comparison tool (`policy-compare`) to validate the engine before applying it in production

### mod_evasive integration

* Apache anti-flood protection incorporated into ARE's reputation model (DOS category), replacing a
  fixed-duration block disconnected from the system

### Consolidation

* removal of the code from earlier generations of the Policy Engine

---

# v2.1

## Goal

Advanced profile management, extensibility of the reputation model, operational visibility, and
hardening of the Firewall Backend persistence.

## Status

✔ Completed — released as an official release (`v2.1.0`)

## Features added

### Jails / Profiles

* Export / Import `jail_profile` between servers, with conflict resolution and auditing

### Sensors

* `apache_evasive.sh` formalized as an official framework sensor — the second documented pattern
  (callback, invoked directly by Apache), alongside the existing one (polling, Fail2Ban)
* the Fail2Ban jail filter replaced by a dynamic query against `jail_profile`, instead of a fixed
  list in the code

### Reputation model

* migration of the category model from fixed columns to a normalized schema (`reputation_scores`),
  allowing new categories to be added as a data operation, with no schema migration or code changes
* fix for a truncation drift in the reputation calculation (storage and Decay calculation)
* proportional redistribution of the Decay Engine across categories, preventing the diversity of
  attack techniques from speeding up an IP's release

### Dashboard

* daily activity trends (events, bans, distinct IPs per day), the system's first time-based view

### Firewall Backend

* automatic restoration of the firewall state (`ipset`) from the database at system boot, preserving
  the exact remaining time of active temporary sanctions — previously, a server reboot could lose
  active sanctions before their deadline
* fix for an uncontrolled range limit in `ipset` that prevented correctly applying long-duration
  sanctions (the highest recidivism level before the permanent sanction)

---

# v2.2

## Goal

Add a new real data source to the reputation model (SOCIAL category), complete the category
threshold catalog, and resolve the friction of distributing the product to other servers in the
fleet.

## Status

✔ Completed — released as an official release (`v2.2.0`)

## Features added

### SpamAssassin Sensor

* `SOCIAL` category with a real sensor, fed by SpamAssassin scores over outgoing mail traffic,
  classified into three severity bands calibrated by `jail_profile`
* MTA-adapter architecture — the only implemented and validated adapter: Exim
* `policy/rules/social.sh`, existing from an earlier project phase with no defined threshold, active
  for the first time

### Category catalog

* all 9 categories of the reputation model have a defined threshold — including `MALWARE`, calibrated
  proactively despite having no local sensor, as a generic-engine decision useful for any server with
  real malware surface

### Dashboard

* trend breakdown by category and CSV export, extending the time-based view added in v2.1

### Packaging and distribution

* a packaging script that generates a distributable artifact from the product manifest, with
  integrity verification
* automation of package generation and publication on each tagged version
* one-line remote installation, without depending on cloning the repository

## Pending, out of scope for this version

* Installer self-update phase against the releases repository (`apt`/`yum` style) — resolved in v2.3
* enable/disable sensors from ARE ADMIN, with auto-provisioning of `jail_profile` on enable —
  resolved in v2.3
* full integration of `mod_evasive` as the only blocking path — ongoing research suggests the real
  threat pattern of servers behind a proxy like Cloudflare (distributed traffic, not concentrated
  floods from a single IP) may not match what this sensor is designed to detect; with no real
  trigger evidence to date
* removal of the redundant category columns in `reputation` (postponed due to the SQLite version
  limitation on the production server, with no date)

---

# v2.3

## Goal

Operational sensor administration from ARE ADMIN, closing the Installer Engine's self-update line,
and expanded visibility with anomaly detection.

## Status

✔ Completed — released as an official release (`v2.3.0`)

## Features added

### Enable/disable sensors

* dynamic sensor registry (`sensor_registry`), read by ARE ADMIN with no new code per added sensor
* polling sensors (Fail2Ban, SpamAssassin): enable/disable controls the systemd timer directly
* callback sensor (`apache_evasive`): enable/disable through a flag file, without touching the
  external Apache/mod_evasive configuration — only the block and the report to ARE are stopped, with
  an email notice instead
* auto-provisioning of `jail_profile` on enabling SpamAssassin, idempotent
* detection of Fail2Ban jails with real activity but no managed profile, read-only — with no
  auto-creation of category or weight

### Closing the self-update line

* available-version query against the releases API, without touching the system
* remote update of an existing installation, reusing the existing bootstrap
* automatic installation of missing system dependencies (apt-get/dnf/yum)

### Expanded visibility

* automatic anomaly detection in the daily per-category trends, comparing the day's activity against
  the recent average

## Fixes

* the release-publication workflow failed if the GitHub Release did not already exist
* extraction of the remote-installation package failed on servers with `/tmp` mounted without execute
  permission
* the SpamAssassin sensor could reprocess the same log stretch on overlapping runs, inflating an IP's
  reputation
* reverting a sanction did not persist the change in the sanction state, risking its re-application
  after a system reboot
* the SpamAssassin sensor delegated to the tool's internal verdict instead of deciding by its own risk
  criterion, losing real events

---

# v2.4

## Goal

Complete the extensible reputation model (RFC-008), and fix the remote installation so it really
works end to end, with no manual intervention — validated with real clean installations on two
different distros.

## Status

✔ Completed — released as an official release (`v2.4.0`)

## Features added

### Complete extensible reputation model (RFC-008, Phase 4)

* the 9 redundant category columns and `total_score` removed from the `reputation` table — the
  per-category score lives only in `reputation_scores` (normalized) from then on
* 6 statistics functions rewritten to compute over `reputation_scores`, without depending on removed
  columns
* new installations no longer create the redundant columns at all, regardless of the server's SQLite
  version

### Remote installation fixed at the root

* the Installer never created the IPSet sets or the firewall rules during installation — it depended
  on someone running `are.sh` manually afterward. Fixed to initialize them as part of `install` /
  `upgrade` / `repair` itself
* the 4 polling-sensor `.service` units had a hard dependency on external services (Fail2Ban, Exim)
  that may not be installed — a legitimate server without those tools ended up with a broken
  installation. Softened to an ordering dependency, not a blocking one
* `reputation_scores` was not created on a genuinely new installation with no prior data

### Simplified uninstallation

* `uninstall` removes Core, data, and logs — preserving nothing by default; whoever wants to preserve
  information does so on their own before uninstalling

### Other fixes

* `are.sh` did not check for root privileges — a run without `sudo` failed silently, with no message,
  instead of clearly indicating the problem

## Process note

This version revealed that the remote installation, documented as validated at the close of
`v2.3.0`, had in fact never been tested end to end without manual intervention — each previous
validation included commands run by hand during testing, hiding real failures in the Installer.
Fixed with real clean installations, repeated until confirming 11/11 with no manual step between the
installation and the verification.

---

# v2.5

## Goal

Add a new sensor to the Sensor Framework capable of detecting a type of threat Fail2Ban cannot see by
design: behavior correlation across multiple distinct IPs, instead of isolated per-IP evaluation.

## Status

✔ Completed — released as an official release (`v2.5.0`)

## Features added

### Web Correlation Sensor

Arising from real research into a confirmed distributed catalog-scraping attack in production, with
evidence gathered before writing a single line of code: `fail2ban-regex` confirming the existing
filter detected none of that traffic, real per-minute correlation across dozens of distinct IPs, and
`whois` confirming datacenter/proxy infrastructure as the origin.

* Groups events by a configurable path marker (default, `cart` — generalizing the sensor to any site
  with an e-commerce catalog/cart, not tied to a specific business) and a time window, counting the
  distinct IPs involved.
* Reports each IP in the correlated group to the existing contract (`are.sh found <IP> <JAIL>`),
  without introducing a new "group/campaign" concept in the data model — all the correlation
  complexity stays encapsulated inside the sensor.
* Registered in `sensor_registry` (`RFC-017`) — visible and controllable from ARE ADMIN with no extra
  code, the same generic mechanism as the rest of the polling sensors.
* A dedicated log, following the precedent already set by `apache_evasive.sh` /
  `mod_evasive_report.log`.

## Validation

Correlation logic tested in isolation before touching production; a real run against the full
`access_log` confirmed genuine groups of more than 100 distinct IPs per minute, matching the already
known real attack. The full historical backlog (more than 14,000 unique IPs) processed in production
with no loss of progress.

---

# v2.6

## Goal

Allow sharing reputation between servers in the same fleet — a malicious IP already confirmed on one
server should not have to accumulate evidence from scratch on the next one.

## Status

✔ Completed — released as an official release (`v2.6.0`)

## Features added

### Export / Import reputation between servers

Arising directly from the validation of the previous version: a confirmed attack against one server
does not mean the same malicious infrastructure will not attack other servers in the fleet through a
different surface.

* Export filtered by category (checklist, default `BOT`/`RECON`/`EXPLOIT`) and a configurable minimum
  score, avoiding exporting isolated low-value events.
* Reputation accumulates on import, it is not overwritten — the same function any real sensor uses,
  with no new conflict mechanism to learn.
* Automatic relevance filter by server role: a category is only applied on import if it already has
  presence in the local `jail_profile` — without the administrator having to manually decide which
  server needs which category.
* Two new options in ARE ADMIN's "State / Reputation" branch.

## Validation

Tested in real production with genuine data from the scraping attack detected in the previous
version: export of 1192 real IPs, and an import confirming the two paths of the relevance filter (a
category with local presence was applied, one without local presence was skipped without aborting
the rest of the file).

---

# v2.7

## Goal

Keep the whitelist up to date against IP lists published by third parties (e.g. Cloudflare), without
manually copy/pasting each time the provider changes its ranges.

## Status

✔ Completed — released as an official release (`v2.7.0`)

## Features added

### Automatic whitelist synchronization

* a block delimited by markers inside `whitelist.conf` itself — replaced on each run without touching
  any manual administrator entry.
* generic: the source URL (IPv4/IPv6) is configurable, not hardcoded to Cloudflare.
* validation before writing — it never empties the whitelist on a download failure or a change in the
  provider's format.
* a daily timer, optional — installed on every update but not enabled automatically, since it
  requires explicit configuration before making sense.

### `PRODUCT_SYSTEMD_UNITS_OPTIONAL` (Installer Engine)

A new, generic mechanism for any future unit that depends on explicit administrator configuration:
it is copied on every installation, but not enabled automatically — keeping those who do not need it
from ending up with a timer running for nothing.

## Validation

A real synchronization run against Cloudflare's public API: 22 genuine ranges (15 IPv4 + 7 IPv6)
applied correctly, matching the ones the administrator already had noted by hand. Active timer
confirmed with `systemctl status`.

## Patch v2.7.1

Fix for a time-zone inconsistency in the reputation dashboard (`Last event` in UTC, `Last activity`
in local time, for the same timestamp) — see `BUG-034` in `docs/TODO.md` for the full detail,
including the investigation of a real incident that exposed the problem.

---

# v2.8

## Goal

Add the `MALWARE` category to the reputation model with a real data source — until this version, that
category's threshold had been calibrated since v2.2 (`TASK-018`) with no sensor feeding it.

## Status

✔ Completed — released as an official release (`v2.8.0`)

## Features added

### `mail-antivirus` sensor (MALWARE category)

Arising from the installation of ClamAV for cPanel (WHM plugin) to scan incoming mail via Exim.
Design validated with real rejection evidence (an EICAR test file, via a genuine external SMTP
connection) before writing the sensor — see `TASK-023` in `docs/TODO.md` for the full detail.

* A polling sensor (same pattern as `syslog.sh` / `spamassassin.sh`), it filters
  `rejected after DATA:.*(virus|harmful content)` in `exim_mainlog` and extracts the source IP.
* The `mail-antivirus` jail, named after Exim's generic ACL (`av_scanner`) and not after the backend
  engine (ClamAV), so as not to couple to a specific antivirus engine.
* Validated directly against the real production `exim_mainlog` (`--dry-run`) and with `journalctl`
  evidence of the full pipeline (`FOUND → Score → Policy → Apply`) after activation.

## Process note

This version was developed and validated directly on `main` (the production server), without
simulating mail traffic in the lab VMs — those VMs do not run real Exim/ClamAV, and had already
served their real purpose (validating the remote-installation mechanics, `TASK-020` / `TASK-021` /
`BUG-029` / `BUG-031`), not simulating services they do not have. It also exposed that, in this work
environment, `/opt/are` on `main` is at the same time the git checkout — so `are-installer upgrade`
did not apply there (it rejected source=target) and the activation of the new systemd pieces was done
manually. Fixed at the root in `v2.8.1` (`TASK-024`): the Installer now recognizes that scenario and
synchronizes permissions/systemd/config without trying to copy the file tree over itself.

## Patch v2.8.1

Fix of the Installer Engine for the scenario where the active installation is at the same time the
git checkout (see `TASK-024` in `docs/TODO.md`), and version synchronization
(`VERSION` / `config.conf` / `manifest/product.sh`), never applied when tagging `v2.8.0`.

During the production validation itself, a more serious problem was found, unrelated to the patch's
original objective: `install_install_configs()` unconditionally overwrote `config.conf` and
`whitelist.conf` on every `upgrade`, copying the outdated template — it caused real loss of live
configuration (log paths, Cloudflare whitelist sync, office IPs, mail-antivirus) during the
validation itself. Fixed at the root: `upgrade` no longer overwrites an existing configuration file,
the same as `install` — it is always preserved, without exception. See `TASK-024` in `docs/TODO.md`
for the full detail of the incident and the fix.

Also fixed, same patch: several product files (`admin.sh`, `database.sh`, `manifest/product.sh`,
`infrastructure/restore_ipsets.sh`) lost their execute permission on every `install` / `upgrade` /
`repair` because they were not declared in `PRODUCT_EXECUTABLE_FILES` — the same pattern as
`BUG-023` / `BUG-033`, added to the manifest.

Applied and validated in real production (`upgrade` run with the fix, a clean git tree at the end),
merged to `main` and published as the tag `v2.8.1`.

## Patch v2.8.2

A direct consequence of `v2.8.1`: by no longer overwriting an existing config on `upgrade`, a new
variable added in a future version to the template would never reach an already-installed server.
`install_install_configs()` now merges — it adds to the existing config only the variables missing
relative to the template, without touching or overwriting any existing one. It does not apply to
files that are not `KEY=value` (`whitelist.conf`, `jail_scale.conf`), which behave exactly as before.
See `TASK-025` in `docs/TODO.md`.

Validated in isolation (test files in `/tmp`) and in real production (`upgrade` / `verify`, no
regressions). Merged to `main` and published as the tag `v2.8.2`.

## Patch v2.8.3

Documentation-only patch. English becomes the canonical documentation language: `README.md` and 13 documents under `docs/` are now in English (`docs/TODO.md`, the internal work log, stays in Spanish), and the original Spanish versions are preserved unchanged as `README.es.md` and `docs/*.es.md`. No code changes. It is the first release package to ship the English documentation (the `v2.8.2` package still carries the Spanish documents). See `TASK-026` in `docs/TODO.md`.

Validated by comparing each `.es.md` byte for byte against the previous version of its document.

---

# Upcoming lines of work

## Additional sensors

Planned, with no implementation started:

* ModSecurity as its own sensor (today it reports indirectly via Fail2Ban jails)
* Suricata
* Zeek
* CrowdSec
* DNS
* external APIs

Evaluated and discarded: a "generic syslog" sensor with its own message contract (`ip=X jail=Y`). It
would ask each external tool to reformat its output into a format invented by ARE, duplicating logging
structures each tool already has — the very problem ARE exists to avoid, not to solve. The correct
path to add a new tool is still a sensor that reads that tool's real log as it is (the same criterion
as `spamassassin.sh` with the Exim log, and `mail_antivirus.sh` with `exim_mainlog`), not asking it
to speak ARE's language.

## Decision engine

* full integration of `mod_evasive` as the only blocking path (today it runs in double-write mode,
  direct ipset + report to ARE, as a transition measure) — see the research note in the v2.2 section

---

# Long-term vision

Broader architectural goals, with no concrete version planning yet. Their inclusion here does not
imply a commitment to implement them — they must be formally incorporated into a Roadmap version
before starting their development, according to the criteria in the following section.

## Alternative Firewall backends

* nftables
* firewalld
* pf
* Cloud Firewall

## Platform

* REST API
* Backend Manager (administration of multiple firewall backends)
* High availability
* Replication between nodes
* Distributed integration (multiple servers sharing reputation intelligence)

---

# Evolution principles

Every evolution must respect the following principles:

* stability before new features;
* architecture before implementation;
* reuse before duplication;
* documentation in sync;
* incremental evolution.

Major versions may introduce architectural changes when those have been previously analyzed and
documented.

---

# Criteria for adding features

Every new capability must:

* respond to a technical need;
* keep the existing architecture or formally justify any modification;
* be documented;
* have been validated;
* be part of the Roadmap before starting its implementation.

The presence of a feature in this document does not imply that it is implemented.

---

# Vision

ARE is evolving toward a reputation and decision platform capable of integrating multiple event
sources and multiple response mechanisms while keeping a single intelligence core.

The architecture will keep growing through decoupled, reusable, documented components.

---

> 🇪🇸 Versión en español (referencia): [`ROADMAP.es.md`](ROADMAP.es.md)
