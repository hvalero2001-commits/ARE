# Changelog

All relevant changes to ARE (Abuse Reputation Engine) will be documented in this file.

The project follows versioning based on stable releases.

---

# v2.8.3

**Date:** 2026-10-24

## Summary

Documentation-only patch: English becomes the canonical documentation language. No code changes.

## What's new

* `README.md` and 13 documents under `docs/` are now in English (`docs/TODO.md`, the internal work log, stays in Spanish). `README.md` is a concise landing page; the full previous README lives in `README.es.md`.
* The original Spanish documents are preserved unchanged as `README.es.md` and `docs/*.es.md` (`README.es.md` only adds a language switch).
* `PROJECT.md`: the English version fixes an unclosed code block in the original (it made the rest of the document render as code).
* The release package built from this tag is the first to ship the English documentation; the `v2.8.2` package still carries the Spanish documents.

## Validation

Each `.es.md` was compared byte for byte against the previous version of its document: identical, except `README.es.md` (language switch only). Headings and code blocks were checked pair by pair.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync;
* apt-get/dnf/yum.

---

# v2.8.2

**Date:** 2026-09-26

## Summary

`install_install_configs()` now merges new variables from the template into an existing configuration file, instead of leaving them undefined — a direct consequence of the `v2.8.1` fix (which stopped overwriting existing configs).

## What's new

* New function `install_config_merge()`: appends to the existing config only the `KEY=value` variables present in the template and absent there, without touching any existing one.
* Does not apply to files that are not entirely `KEY=value` (`whitelist.conf`, `jail_scale.conf`) — they behave exactly as before.

## Validation

Tested in isolation (test files in `/tmp`, without touching `/opt/are`) and in real production (`upgrade`/`verify`, with no regressions and no missing variables at this time).

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync;
* apt-get/dnf/yum.

---

# v2.8.1

**Date:** 2026-09-26

## Summary

Patch — fixes the Installer Engine: `upgrade` overwrote `config.conf`/`whitelist.conf` with the outdated template, and several product files lost their execute permission on every operation.

## Fixes

* `install_install_configs()` unconditionally overwrote existing configuration files in `upgrade` mode — it caused real loss of configuration in production (log paths, whitelist sync, mail-antivirus, office IPs) during this patch's own validation. Fixed: `upgrade` now preserves an existing configuration file, just like `install`.
* `templates/config/config.conf` was missing the Whitelist Auto-Sync and mail-antivirus variables, the root cause of the overwrite — completed.
* `admin.sh`, `database.sh`, `manifest/product.sh`, and `infrastructure/restore_ipsets.sh` lost their execute permission on every `install`/`upgrade`/`repair` because they were not declared in `PRODUCT_EXECUTABLE_FILES` — added.
* `are-installer` rejected `upgrade`/`repair` when the source directory and the active installation directory are the same (a git checkout used as the active installation) — it now recognizes the case and skips the copy instead of aborting.
* Version synchronization (`VERSION`, `config.conf`, `templates/config/config.conf`, `manifest/product.sh`), never applied when tagging `v2.8.0`.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync;
* apt-get/dnf/yum.

---

# v2.8.0

**Date:** 2026-09-26

## Summary

Adds the `MALWARE` category to the reputation model with a real data source: the `mail-antivirus` sensor, fed by Exim rejections via the `av_scanner` ACL (ClamAV for cPanel).

## mail-antivirus sensor

* Polling sensor over `exim_mainlog`, filtering `rejected after DATA:.*(virus|harmful content)` and extracting the source IP.
* `mail-antivirus` jail, named after Exim's generic ACL and not after the backend engine, so as not to couple to a specific antivirus.
* Validated with real rejection evidence (an EICAR test file via a genuine external SMTP connection) before writing the sensor.

## Validation

Confirmed against the real production `exim_mainlog` (`--dry-run`) and with `journalctl` evidence of the full pipeline (`FOUND → Score → Policy → Apply`) after activation.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync;
* apt-get/dnf/yum.

---

# v2.7.1

**Date:** 2026-09-03

## Summary

Patch — fixes a time-zone inconsistency in the reputation dashboard.

## Fixes

* `dashboard/score.sh` displayed `Last event` in UTC and
  `Last activity` in local time for the same internal timestamp,
  with no label indicating it — it could lead to misreading the real
  order of events when comparing against an external report.
  `db_get_last_event()`/`db_get_events()` fixed to use local time
  in both cases, consistent with each other.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync;
* apt-get/dnf/yum.

---

# v2.7.0

**Date:** 2026-08-28

## Summary

Keeps the whitelist up to date against IP lists published by third parties, with no manual intervention — and adds a generic mechanism for optional systemd units, which are always installed but only activated if the administrator configures them.

## Automatic whitelist synchronization

* A block delimited by markers inside `whitelist.conf` itself — replaced on every run without touching any manual entry made by the administrator.
* Generic: the source URL (IPv4/IPv6) is configurable, not tied to any specific provider in the code.
* Validation before writing — it never empties the whitelist on a download failure or a change in the provider's format.
* Daily timer, optional — installed in every update but not enabled automatically.

## Installer Engine: optional systemd units

`PRODUCT_SYSTEMD_UNITS_OPTIONAL` — a new, generic mechanism for any unit that depends on explicit administrator configuration before it makes sense. It is copied in every install/upgrade, but not enabled automatically, avoiding log noise for anyone who does not need it. `uninstall` extended to also clean up these units.

## Validation

Real synchronization run against the public Cloudflare API: 22 genuine ranges (15 IPv4 + 7 IPv6) applied correctly. Timer confirmed active with `systemctl status`.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync;
* apt-get/dnf/yum.

---

# v2.6.0

**Date:** 2026-08-28

## Summary

Allows reputation to be shared between servers in the same fleet, automatically filtered by each receiving server's role.

## Export / Import reputation between servers

Arising directly from the validation of v2.5: a confirmed attack against one server does not mean the same malicious infrastructure will not attack other servers in the fleet through a different surface.

* Export filtered by category and configurable minimum score, avoiding the export of isolated low-value events.
* Reputation accumulates on import, it is not overwritten — it reuses the same function any real sensor uses.
* Automatic relevance filter by the server's role: a category is applied on import only if it already has presence in the local `jail_profile`.
* Two new options under the "Status / Reputation" branch of ARE ADMIN.

## Validation

Tested in real production with genuine data from the scraping attack detected in v2.5: export of 1192 real IPs, and import confirming both paths of the relevance filter without aborting the rest of the file on a non-applicable category.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync;
* apt-get/dnf/yum.

---

# v2.5.0

**Date:** 2026-08-28

## Summary

Adds a new sensor to the Sensor Framework: behavior correlation across multiple distinct IPs, capable of detecting threats that Fail2Ban cannot see by design (isolated evaluation per individual IP).

## Web Correlation Sensor

Arising from a real investigation into a confirmed distributed catalog-scraping attack in production, with evidence gathered before writing code: verification that the existing `apache-badbots` filter detected none of that traffic, real per-minute correlation across dozens of distinct IPs, and `whois` confirmation of datacenter/proxy infrastructure as the origin.

* Groups events by a configurable path marker (by default, `cart`) and time window, counting the distinct IPs involved — without tying itself to a specific business or site.
* Reports each IP of the correlated group to the existing contract (`are.sh found <IP> <JAIL>`), without introducing a new "group/campaign" concept into the data model.
* Registered in `sensor_registry` — visible and controllable from ARE ADMIN with no additional code.
* Dedicated log, following the precedent of `apache_evasive.sh`/`mod_evasive_report.log`.

## Validation

Correlation logic tested in isolation before touching production. A real run against the full `access_log` confirmed groups of more than 100 distinct IPs per minute, matching the already-known real attack. The complete historical backlog (more than 14,000 unique IPs) was processed in production without loss of progress.

## Documentation

Full audit of the `# RFC` section of `docs/TODO.md`: 4 entries (`RFC-001`, `RFC-003`, `RFC-004`, `RFC-006`) remained marked as draft despite being effectively resolved, two of them absorbed by a later RFC without ever being referenced back. Corrected with real evidence of when and how they were completed. A real contradiction found and resolved between `PHILOSOPHY.md` and `PROJECT.md` (two completely different lists of project "principles") — `PHILOSOPHY.md` remains the single source.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync;
* apt-get/dnf/yum.

---

# v2.4.1

**Date:** 2026-08-24

## Summary

A fix patch over v2.4.0, found when validating a real
`upgrade --remote` against a published release for the first time.

## Fixes

* `are.sh` did not check for root privileges — a run without
  `sudo` failed silently, with no message, instead of indicating
  the problem clearly.
* `scripts/install.sh` and `scripts/build-package.sh` did not have
  execute permission after each `install`/`upgrade` — the product
  manifest copied them but never declared them as executables,
  breaking `upgrade --remote` on every cycle.

## Process note

The initial `v2.4.1` package was published with `PRODUCT_VERSION`
still at `2.4.0`, unsynchronized — the generated package name did not
match the one the remote-install bootstrap expected based on the tag.
Fixed by synchronizing the project's 4 version files and republishing
the same tag.

---

# v2.4.0

**Date:** 2026-08-23

## Summary

A version focused on completing the extensible reputation model and, above all, on fixing the remote installation so it actually works end to end — the previous version had considered it validated without ever having tested it without manual intervention.

## Complete extensible reputation model

Fourth and final phase of the migration started in v2.1: the redundant category columns in `reputation` (and `total_score`, derived) removed entirely. The per-category score has lived only in `reputation_scores` since then.

* New installations no longer create the redundant columns, on any SQLite version — the real limitation only applied to removing them from an already-existing database.
* Six statistics functions rewritten to compute over the normalized schema.

## Remote installation fixed at its root

Found when validating a genuinely clean installation for the first time, without any manual command between the installer and the verification, on two different distros.

* The Installer never created the IPSet sets or the firewall rules — it silently depended on someone running `are.sh` manually after installing.
* Four systemd units had a hard dependency on external services (Fail2Ban, Exim) that may legitimately not be installed — a pure mail server, with no Fail2Ban, was left with a broken installation.
* `reputation_scores` was not created on a new installation with no prior data.

## Simplified uninstall

`uninstall` removes Core, data, and logs without keeping anything by default — whoever wants to preserve information does so on their own before uninstalling.

## Fixes

* `are.sh` did not check for root privileges — a run without `sudo` failed silently, with no message.

## Documentation

A real contradiction between `PHILOSOPHY.md` and `PROJECT.md`, each with its own list of project "principles", with barely any overlap between them — fixed: `PHILOSOPHY.md` remains the single source, `PROJECT.md` references it instead of duplicating it.

## Process note

This version exists in large part because the remote installation, considered closed and documented in v2.3.0, had never actually been tested end to end. Every prior validation included manual commands during testing, hiding real Installer failures. The `v2.3.0` tag was fixed and republished several times on the same day this was discovered, before deciding to formalize the pending work as this version.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync;
* apt-get/dnf/yum.

---

# v2.3.0

**Date:** 2026-08-23

## Summary

A version focused on operational sensor administration from ARE ADMIN, closing out the Installer Engine's self-update line, and a round of production fixes with confirmed and reverted real impact.

## Enable/disable sensors

ARE ADMIN adds direct operational control over each sensor, with dynamic registration — a new sensor appears in the menu on its own, with no additional code.

* Polling sensors (Fail2Ban, SpamAssassin): enable/disable directly controls their systemd timer.
* Callback sensor (apache_evasive): enable/disable via a flag file, without touching Apache/mod_evasive's external configuration.
* Auto-provisioning of profiles when enabling SpamAssassin, idempotent.
* New view: Fail2Ban jails with real activity that do not yet have a managed profile — read-only, with no automatic creation of category or weight.

## Closing out the self-update line

The Installer Engine completes its path toward independence from git: query for available updates, remote update of an existing installation, and auto-installation of missing system dependencies.

## Expanded visibility

Automatic detection of anomalies in the daily per-category trends, comparing the day's activity against the recent average — with no new instrumentation, reusing already-existing data.

## Fixes

* The release-publishing workflow failed if the GitHub Release did not already exist.
* Extraction of the remote-install package failed on servers with `/tmp` mounted without execute permission.
* The SpamAssassin sensor could reprocess the same stretch of the log on overlapping runs, inflating an IP's reputation.
* Reverting a sanction did not persist the change in the sanction state, exposing it to being reapplied after a system reboot.
* The SpamAssassin sensor delegated to the tool's internal verdict instead of deciding by its own risk criterion, missing real events with a score above the configured threshold.

## Documentation

Closing of a documented-threshold synchronization task, resolved incidentally in a previous version without being recorded at the time. A reference pattern documented for future external-IDS sensors.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync;
* apt-get/dnf/yum.

---

# v2.2.0

**Date:** 2026-08-21

## Summary

A version focused on adding a new real data source to the reputation model, completing the category catalog, and resolving the friction of distributing the product to other servers in the fleet.

## SpamAssassin sensor

The first heuristic category of the v2.2 line. `SOCIAL` now has a real sensor, fed by SpamAssassin scores over outbound mail traffic, classified into three severity bands calibrated by jail_profile.

* MTA-adapter architecture — the only adapter implemented and validated: Exim. Adding another MTA is adding a function, not rewriting the sensor.
* Automation via systemd timer, with an explicit dependency on the real mail service instead of the generic one used by the rest of the sensors.
* `policy/rules/social.sh`, existing since an earlier phase of the project with no defined threshold, becomes active for the first time.

## Complete category catalog

The 9 categories of the reputation model now all have a defined threshold — including `MALWARE`, calibrated proactively despite not having a local sensor, as a conscious generic-engine decision: useful for any server with a real malware surface, not only this one.

## Expanded time-based visibility

The daily-trends view, added in the previous version, is extended with a per-category breakdown and CSV export — with no new instrumentation, reusing exclusively the already-existing data.

* The per-category breakdown revealed real activity spikes that were previously undetectable, correlated with windows of direct exposure without edge protection.

## Packaging and distribution

The installation engine, existing since earlier versions, adds its first real distribution layer.

* A packaging script that generates a distributable artifact from the product manifest, with integrity verification.
* Automation of package generation and publishing on each tagged version.
* One-line remote installation, without depending on cloning the repository.

## Fixes

* An observation about synchronization between Fail2Ban and the decision engine, open since an early version of the project, closed with accumulated evidence of sustained real operation.
* An incomplete product manifest after adding the SpamAssassin sensor: two files were left without execute permission in a new installation — fixed and verified before affecting any real installation.

## Documentation

Consistency review across technical-history entries: reordering of an out-of-sequence entry, closing of already-resolved pending items still documented as open, and synchronization of the version number across the different sources of that data.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity;
* Exim;
* rsync.

---

# v2.1.0

**Date:** 2026-08-20

## Summary

A structural consolidation version over v2.0. It adds cross-server profile administration, an extensible per-category reputation model with no schema migration, time-based visibility of system activity, Firewall Backend persistence across reboots, a formalized second sensor pattern, and a full review of the project documentation.

## Cross-server profile administration

Export and import of `jail_profile` is added from ARE ADMIN, allowing profile calibration to be replicated between servers without recreating them manually.

* Export with an automatically generated file name, without overwriting previous backups.
* Import with file selection from a numbered list and conflict resolution in a single step (overwrite or keep).
* Both operations audited.

## Extensible reputation model

Per-category reputation storage transitions from fixed columns in the `reputation` table toward a normalized schema, `reputation_scores`, where adding a new category is a data operation and not a structure or code migration.

* Read and write functions rewritten over the new schema, validated in production with no observable change in behavior.
* `db_add_score()` replaces nine per-category assignment branches with a single generic statement.
* `total_score` is always derived as the sum of the categories, structurally eliminating the possibility of it drifting out of sync with the real data.
* The Decay Engine redistributes the reduction proportionally across categories, instead of truncating each one independently.

## Second sensor: callback pattern

`apache_evasive.sh` is formalized as an official framework sensor, invoked directly by Apache/`mod_evasive` at the moment of the event, alongside the already-existing polling pattern (Fail2Ban).

## Time-based visibility

The system's first time-based view: daily activity trends (events, bans, distinct IPs per day).

## Persistent Firewall Backend

* Automatic restoration of the firewall state (`ipset`) from the database at system boot, preserving the exact remaining time of active temporary sanctions — before, a server reboot could lose active sanctions without serving out their term.
* Fix of an uncontrolled range limit in `ipset`, which prevented long-duration sanctions from being applied correctly.

## Category-based Policy Engine

* Each category has its own rule, with a configurable threshold in `policy.conf`.
* A recidivism risk multiplier is added, applied to IPs in an observation or active-sanction state.
* The final decision is never less strict than the total-score evaluation, preserving the already-validated behavior of the previous engine as a safety floor.
* An engine-comparison command is added, to validate the new engine's behavior against real data before applying it in production.

## mod_evasive integration

Apache's anti-flood protection (`mod_evasive`) now reports to ARE as the DOS category, adding accumulable reputation, gradual recovery via Decay, and sanction escalation via Ban Lifecycle, replacing a fixed-duration block.

## Policy Engine consolidation

The Policy Engine code from previous generations, left unused after the category-based engine was added, is removed.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity.

---

# v2.0.0

**Date:** 2026-08-15

## Summary

Second major version of ARE.

Version 2.0 consolidates the product's own identity, abandons the historical `f2b-ipset` structure, and establishes `/opt/are` as the official ARE installation. It also adds the ARE ADMIN administration interface, a decision engine based on per-category risk evaluation, and the integration of Apache's anti-flood protection into the ARE reputation model.

## Product structure

The official structure is defined through `manifest/product.sh`.

Main components:

* `/opt/are` — product;
* `/opt/are/config` — configuration;
* `/var/lib/are` — persistent data;
* `/var/log/are` — logs;
* `/usr/local/sbin` — executable links;
* `/etc/systemd/system` — services;
* `/etc/logrotate.d` — logrotate configuration.

The operational database is established at:

```text
/var/lib/are/are.db
```

## Product Manifest

`manifest/product.sh` is established as the official definition of the components managed by ARE.

It defines:

* product name;
* version;
* structure;
* files;
* configuration;
* persistent data;
* services;
* executable links;
* executables;
* logrotate;
* exclusions.

The product version is established at `2.0.0`.

## Installer Engine

The Installer Engine manages:

* `install`;
* `upgrade`;
* `repair`;
* `verify`;
* `uninstall`.

`install`, `upgrade`, and `repair` use the same Installer Core.

The operations use `manifest/product.sh` as the source of the components managed by ARE.

## Official links

The following links are established:

```text
/usr/local/sbin/are
/usr/local/sbin/are-installer
/usr/local/sbin/are-fail2ban-sensor
```

The main command is defined as:

```text
/usr/local/sbin/are -> /opt/are/are.sh
```

## Persistent data

ARE v2 uses:

```text
/var/lib/are/are.db
```

The database contains:

* `hosts`;
* `events`;
* `config`;
* `jails`;
* `reputation`;
* `jail_profile`;
* `sanction_state`.

The persistent structure is separated from the product Core.

## Reputation Engine

The reputation model added in v1.1 is kept.

Categories:

* RECON;
* EXPLOIT;
* CREDENTIAL;
* PROTOCOL;
* BOT;
* ANOMALY;
* MALWARE;
* DOS;
* SOCIAL.

## Reputation Decay

The operational Reputation Decay cycle is added via systemd.

Units:

```text
are-fail2ban-decay.service
are-fail2ban-decay.timer
```

The service runs the phases:

* dry-run;
* apply.

The mechanism uses:

```text
MIN_AGE=86400
FACTOR=0.95
```

The scheduled execution was verified with successful completion.

## Fail2Ban Sensor

The Sensor Framework is kept with the official Fail2Ban sensor.

Events processed:

* `FOUND`;
* `EXTERNAL_UNBAN`.

The sensor uses a persistent offset and allows execution in dry-run or execute mode.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* ip6tables;
* systemd;
* Fail2Ban;
* ModSecurity.

---

# v1.1.0

**Date:** 2026-07

## Summary

The first version focused on consolidating the product's operational lifecycle.

Version 1.1 adds the Installer Engine, the Sensor Framework, the expansion of the reputation model, and various architectural improvements without modifying ARE's decision core.

---

## New features

### Installer Engine

The Installer Engine is added with the operations:

* install
* upgrade
* repair
* verify
* uninstall

Main characteristics:

* automatic detection of the installation state;
* protection of the persistent configuration;
* preservation of the persistent data;
* installation validation;
* uninstall preserving configuration, data, and logs;
* reuse of a common Installer Core across the install, upgrade, and repair operations.

The `install`, `upgrade`, and `repair` operations require the Core used as the source to be different from the active installation directory.

The current mechanism does not include generation, download, extraction, or automatic staging of external packages.

---

### Sensor Framework

The first official implementation of the Sensor Framework is added.

Available sensor:

* Fail2Ban Sensor

Events processed:

* `FOUND`
* `EXTERNAL_UNBAN`

The sensor allows processing new Fail2Ban events via a persistent offset file.

Processing can run in `--dry-run` or `--execute` mode.

The framework allows adding new sensors without modifying ARE's core.

---

### Reputation Engine

Expansion of the reputation model.

Supported categories:

* RECON
* EXPLOIT
* CREDENTIAL
* PROTOCOL
* BOT
* ANOMALY
* MALWARE
* DOS
* SOCIAL

---

### Dashboard

Improvements added:

* TOP JAILS
* display of all categories
* statistical improvements
* separation between events and reputation
* operational improvements

---

### Product Manifest

`manifest/product.sh` is added as the official definition of the components managed by ARE.

It centralizes:

* product structure;
* files;
* directories;
* configuration;
* services;
* links;
* executables;
* exclusions;
* persistent components.

---

### Installer Manifest

The Installer Engine uses the Manifest as the reference for the components managed by the product.

The duplication of internal lists is removed.

---

## Improvements

* consolidation of the product's operational lifecycle;
* separation between Core, configuration, and persistent data;
* persistent official links;
* preservation of configuration during maintenance operations;
* reuse of the Installer Core;
* automatic validation after the install, upgrade, and repair operations.

---

## Fixes

* fix of the `total_score` calculation;
* fix of the reputation categories;
* reorganization of the Dashboard;
* reorganization of the Backend;
* cleanup of the initialization process;
* removal of Installer duplications;
* preservation of configuration during upgrades;
* handling of incomplete installations via the `repair` operation.

---

## Architecture

The architecture remains based on:

* Sensor Framework;
* Reputation Engine;
* State Engine;
* Policy Engine;
* Firewall Backend.

The Installer Engine is officially added as responsible for the product lifecycle.

---

## Compatibility

* Linux
* SQLite
* IPSet
* iptables
* ip6tables
* systemd
* Fail2Ban
* ModSecurity

---

# v1.0.1

**Date:** 2026-07-05

## Summary

The first maintenance update of ARE, focused on stabilizing the system core and completing the IP address lifecycle.

## New features

* Complete implementation of the `UNBAN` flow.
* Integration of the backend with IPSet for IP address removal.
* Reorganization of the Policy Engine.
* Centralization of the backend initialization.
* Reorganization of the project documentation.

## Fixes

* Fixed the missing `handle_unban()`.
* Removed the double initialization of IPSet and Firewall.
* Cleanup and modularization of the backend.

## Architecture

* Reorganization of the `policy/rules/` module.
* Separation of the backend initialization process.

---

# v1.0.0

**Date:** 2026-07-05

## Summary

The first stable version of ARE.

## Main features

* Reputation Engine.
* State Engine.
* Policy Engine.
* IPSet-based Firewall Backend.
* Persistence via SQLite.
* Dashboard.
* Fail2Ban integration.
* ModSecurity integration.
* IPv4 and IPv6 support.

## Status

Initial stable version used in production.

---

## License

GPL v3

---

> 🇪🇸 Versión en español (referencia): [`CHANGELOG.es.md`](CHANGELOG.es.md)
