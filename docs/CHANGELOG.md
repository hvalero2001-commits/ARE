# Changelog

All relevant changes to ARE (Abuse Reputation Engine) will be documented in this file.

The project follows versioning based on stable releases.

---

# v2.9.7

**Date:** 2026-11-24

## Summary

Documentation-only patch: records the first real detections of the Web Scanner sensor in production. No code changes.

## Changes

* `docs/TODO.md`: new entry `TASK-034` with the evidence; the open item of `TASK-028` ("observe the first real `web-scanner` event") and the pending item of `IDEA-013` ("run it as an enabled timer against a real production log") are closed.
* `docs/ROADMAP.md` / `.es.md`: the v2.9 validation note no longer says the detection-to-decision path is still to be observed.
* `docs/TODO.es.md` stays frozen at v2.8.3.

## Validation in production (2026-11-24)

* Two `FOUND` events from the `web-scanner` jail recorded by the enabled timer, on two different public IPs.
* For one of them the log shows the full first steps: `FOUND recibido: <IP> desde web-scanner`, then `Score FOUND aplicado: 7` — exactly what the jail calibration gives (weight 30 × confidence 0.90 × 0.25) — and the event in `events`. Afterwards the same IP was also reported by Fail2Ban jails (`recidive` and others), accumulated `RECON` 17, `EXPLOIT` 42 and `ANOMALY` 9 (total 68, `HIGH`) and escalated to `BAN_LEVEL_3`.
* On this server the sensor runs next to Fail2Ban and ModSecurity, so it overlaps with them; both paths feed the same reputation. It remains an optional unit for servers without that stack.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* systemd.

---

# v2.9.6

**Date:** 2026-11-24

## Summary

Code patch: the Installer's automatic dependency installation uses the right SQLite package name on RHEL-family distributions.

## Changes

* `are-installer`: `install_auto_install_dependencies()` passed the command name `sqlite3` as the package name to every package manager. The package is called `sqlite3` on Debian, Ubuntu and Kali (`apt-get`) but `sqlite` on AlmaLinux, Rocky, RHEL and Fedora (`dnf`/`yum`), so a clean install there could not resolve it. It now installs `sqlite` when the manager is `dnf` or `yum` and keeps `sqlite3` for `apt-get`; when both kinds of manager exist, `apt-get` wins, as before. Production was not affected because `sqlite3` was already installed.
* `docs/TODO.md`: new entry `TASK-033`. `docs/TODO.es.md` stays frozen at v2.8.3.

## Validation

The function was run in isolation with stub package managers: `apt-get` receives `sqlite3`, `dnf` and `yum` receive `sqlite`, `apt-get` takes precedence when several are present, and with none the error message still lists the missing packages. `bash -n` on the installer. The package name on the RHEL family was confirmed against a published installation guide for AlmaLinux 10; it has not been run on a clean AlmaLinux machine.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* systemd.

---

# v2.9.5

**Date:** 2026-11-24

## Summary

Code patch: the Web Scanner sensor can read several log files, and the enforcement idea behind a tunnel or proxy is discarded as out of scope.

## Changes

* `sensors/web_scanner.sh`: `WEB_SCANNER_LOG_FILE` accepts several paths and/or globs separated by spaces (on cPanel, `"/usr/local/apache/domlogs/*-ssl_log"` covers every domain). Each file keeps its own offset in `web_scanner.offsets/`; the count of distinct sensitive paths is made over the whole run, so an IP probing several domains accumulates across them. With a single path the behavior is unchanged: the previous `web_scanner.offset` file is adopted for the first log and then removed.
* `config/config.conf` and `templates/config/config.conf`: comment documenting the multi-log syntax.
* `IDEA-013`: the enforcement part (a backend for services published behind a tunnel or reverse proxy) is discarded. ARE targets servers whose firewall sees the real client address; the limitation stays documented as scope in `USER_GUIDE`, `ROADMAP`, `ARCHITECTURE` and `DESIGN`.
* `docs/TODO.md`: new entry `TASK-032`. `docs/TODO.es.md` stays frozen at v2.8.3.

## Validation

Tested in isolation with synthetic combined-format logs: an IP with 3 sensitive paths in each of two domains is reported (6 in total, none reaching the threshold of 5 alone); private addresses and an IP below the threshold are not reported; `--dry-run` writes no offsets; a second `--execute` with no new lines reports nothing; a truncated log restarts from the beginning; the legacy offset is adopted and removed.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* systemd.

---

# v2.9.4

**Date:** 2026-11-24

## Summary

Code patch: removes a dead command found during the v2.9.3 content audit.

## Changes

* `are.sh`: removed the `autoban` command. It called `auto_enforce_ban`, a function defined in no file of the product, so `are autoban` always ended with `command not found`. The command was not listed in `are help` nor in any document.
* `docs/TODO.md`: new entry `TASK-031`. `docs/TODO.es.md` stays frozen at v2.8.3.

## Compatibility

* Linux;
* SQLite;
* IPSet;
* iptables;
* systemd.

---

# v2.9.3

**Date:** 2026-11-24

## Summary

Documentation-only patch: removes statements that no longer matched the code, found by checking the content of each document against the real behavior (v2.9.2 had only aligned versions and sensor lists). No code changes.

## Changes

* `docs/INSTALL.md` / `.es.md` and `docs/USER_GUIDE.md` / `.es.md`: when the source tree and the installation are the same directory (a git checkout), the Installer skips the Core copy and runs the remaining steps; the documents said the operation must abort.
* `docs/INSTALL.md` / `.es.md`, `docs/ARCHITECTURE.md` / `.es.md` and `docs/DESIGN.md` / `.es.md`: `uninstall` removes everything (Core, persistent data and logs); the documents said it preserved configuration, database, reputation and logs.
* `docs/DESIGN.md` / `.es.md` (Section 13): the ARE ADMIN menu tree and branch descriptions now match the real menus (profile export/import, sensor enable/disable and unmanaged jails, trends, anomalies, reputation export/import, `x` to leave); the Policy branch is no longer described as pending.
* `docs/USER_GUIDE.md` / `.es.md`: removed the non-existent `are trends [days]` command (trends are reached only through ARE ADMIN → State / Reputation → Trends); added the existing `are status` and `are help` commands.
* `docs/TODO.md`: new entry `TASK-030`. `docs/TODO.es.md` stays frozen at v2.8.3.

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

# v2.9.2

**Date:** 2026-11-24

## Summary

Documentation-only patch: brings every project document in line with v2.9.1. No code changes.

## Changes

* `docs/ARCHITECTURE.md` / `.es.md`: the "extended that base with" list now covers v2.8 and v2.9; the introduction no longer stops at v2.6.
* `docs/DESIGN.md` / `.es.md`: new "Decisions consolidated in v2.8" and "in v2.9" sections; removed the closing sentence that still described v2.8 as in development.
* `docs/PROJECT.md` / `.es.md`: the implemented-capabilities list now includes the Web Correlation, Mail Antivirus and Web Scanner sensors.
* `docs/INSTALL.md` / `.es.md`: the Systemd section describes optional units and the Web Scanner enable steps.
* `README.md` / `README.es.md`: sensor lists include mail antivirus and web access logs.
* `docs/TODO.md`: new entry `TASK-029`. `docs/TODO.es.md` stays frozen at v2.8.3.

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

# v2.9.1

**Date:** 2026-11-24

## Summary

Documentation-only patch: completes the v2.9.0 documentation after the first run of the Web Scanner sensor on the production server. No code changes.

## Changes

* `docs/USER_GUIDE.md` / `.es.md`: the Sensors section now describes every sensor shipped to date (Web Correlation, `mail-antivirus` and Web Scanner were missing) and how to enable the optional Web Scanner unit.
* `docs/CHANGELOG.md` / `.es.md` and `docs/ROADMAP.md` / `.es.md`: v2.9.0 now records the production validation and one more known limitation (below).
* `docs/PROJECT.es.md`: removed a stray closing code fence (left over from the original Spanish text) that rendered the rest of the document as code.
* `docs/TODO.md`: new entry `TASK-028`. `docs/TODO.es.md` stays frozen at v2.8.3.

## Validation in production (v2.9.0)

* `are-installer upgrade` + `verify` on the production server: all checks OK; the optional units are installed and not enabled; the `web-scanner` profile (`RECON`, weight 30) is seeded.
* Enabled from ARE ADMIN (Sensors → Enable/Disable): the timer runs every minute, the service ends `Succeeded`, the offset advances.
* First dry-run against a real cPanel domain log (11,064 lines, about 17 hours): no report, which is correct — only 2 requests touched sensitive paths, both from a Cloudflare address already in the whitelist, below the threshold of 5.

## Known limitation (added)

* The sensor reads a single log file (`WEB_SCANNER_LOG_FILE`). On cPanel each domain has its own log under `/usr/local/apache/domlogs/`, so one instance covers one domain. Multi-log support is not implemented.

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

# v2.9.0

**Date:** 2026-11-24

## Summary

Adds the Web Scanner sensor: it detects reconnaissance of sensitive paths (`.env`, `.git`, `.ssh`, credentials, backups, `phpinfo`) from a single IP by reading an `access_log` in combined format, from nginx or Apache. It is the first sensor shipped as an optional systemd unit.

## Web Scanner Sensor

Arising from a real scan captured on a test nginx server behind a Cloudflare Tunnel: one IP made about 140 requests in 2 minutes to paths such as `.env`, `.git/HEAD`, `.ssh/id_rsa`, `backup.sql` and `phpinfo.php`, all answered 404. Neither Fail2Ban nor `web_correlation` can see this pattern (a single IP, no common path marker), and ARE had no sensor for nginx logs.

* Counts, per IP and per run, the **distinct** sensitive paths requested; from `WEB_SCANNER_HIT_THRESHOLD` (default 5) the IP is reported with `are.sh found <IP> web-scanner`.
* Same structure as `web_correlation.sh`: configuration in `config.conf`, `flock` against overlapping runs, persistent offset (resets if the log rotates), `--dry-run` by default, dynamic filter against `jail_profile`, dedicated log with logrotate.
* Always discards loopback, private (RFC 1918), link-local and IPv6 ULA addresses, so a log that still records the proxy IP never reports the server itself.
* Jail `web-scanner`, category RECON, weight 30, confidence 0.90, decay 0.95: 7 points per run (`weight × confidence × 0.25`).
* Registered in `sensor_registry` (`enabled=0`) and shipped as an **optional systemd unit** (`are-web-scanner.service`/`.timer`): it is installed but not enabled automatically, because `WEB_SCANNER_LOG_FILE` depends on each server. It is enabled from ARE ADMIN > Sensors after configuring the log.
* The sensitive-path pattern can be replaced with `WEB_SCANNER_PATTERN`.

## Validation

* Real captured log (142 distinct URLs): the sensor reports the scanning IP with 100 sensitive paths; the loopback-recorded version of the same log reports nothing; 18 common legitimate routes and normal browser traffic produce no report and no false positive.
* Run on the production server (gawk, sqlite3 3.26) in an isolated directory: identical result to the simulated environment.
* Isolated install followed by `are-installer verify`: 11/11 OK, with no differences from v2.8.4; the optional units and the logrotate file are installed, the timer is not enabled.
* Calibration with the real `are.sh found` flow, ten consecutive runs on a test IP: `WATCH` on run 1, `FILTER` on run 3 (21 points), `TEMP_BAN` of 1 hour on run 9 (63 points).

## Known limitations

* The log must record the **real client IP**. In nginx behind a proxy or tunnel this requires `set_real_ip_from` / `real_ip_header` (for Cloudflare, `CF-Connecting-IP`).
* Behind a tunnel such as Cloudflare Tunnel every connection reaches the server from `127.0.0.1`, so a host firewall ban (IPSet/iptables) cannot block the real client. The sensor detects and builds reputation there; blocking requires a backend outside the host (see `IDEA-013`).
* Bundle and `.map` requests (`main.js.map`, `_next/static/...`) are intentionally not matched: browsers' developer tools also request them.

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

# v2.8.4

**Date:** 2026-10-24

## Summary

Documentation-only patch: supported-versions table corrected, demo recording embedded, and the internal work log translated to English. No code changes.

## What's new

* `README.md`: embeds the asciinema demo (a single attacker escalating `WATCH → FILTER → TEMP_BAN`, with the per-category breakdown from `are score`).
* `SECURITY.md`: the supported-versions table had been left at the 2.3.x line; it now reflects 2.8.x (supported), 2.7.x (limited support) and 2.6.x and earlier (not supported). Adds the private vulnerability-reporting channel (GitHub private security advisory).
* `docs/TODO.md` is now in English (89 entries, all IDs preserved). The Spanish original is preserved unchanged as `docs/TODO.es.md`, frozen at v2.8.3 and no longer updated; the English `TODO.md` is canonical.
* All project documentation is now in English, with the Spanish originals kept as `*.es.md`.

## Validation

`docs/TODO.es.md` compared against the previous `docs/TODO.md`: identical. English and Spanish `TODO` checked entry by entry: same 89 IDs in the same order and the same number of code blocks (118 fences each).

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
