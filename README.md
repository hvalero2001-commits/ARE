# ARE — Abuse Reputation Engine

**English** · [Español 🇪🇸](README.es.md)

![License](https://img.shields.io/badge/license-GPLv3-blue.svg)
![Release](https://img.shields.io/github/v/release/hvalero2001-commits/ARE)
![Shell](https://img.shields.io/badge/built%20with-Bash-4EAA25)
![Platform](https://img.shields.io/badge/platform-Linux-informational)

> **Understand before you respond.**

**Fail2Ban and ModSecurity react to single events. ARE adds the memory.**
ARE is a reputation and decision engine that turns the stream of security events on your
server into a per-IP risk score across nine threat categories — and escalates its response
(`WATCH → FILTER → TEMP_BAN → BANNED`) based on *accumulated behavior*, not one isolated hit.

It sits on top of the tools you already run (Fail2Ban, ModSecurity, mod_evasive, SpamAssassin)
and decides in **code, not by trusting any single sensor**.

---

## The problem it solves

A slow attacker probes you across many small events: a login attempt here, a suspicious
request there, a port scan later. To a per-event tool each one looks minor, so it slips under
every threshold. Meanwhile a real customer who just reloads your site fast can trip a dumb
rate-limit and get banned.

ARE flips this around:
- It **accumulates** evidence per IP over time, weighted by **threat category** (an EXPLOIT
  attempt counts very differently from loading your homepage).
- Reputation **decays** over time — slowly and conservatively (flagged IPs get reused, so an
  address doesn't get a clean slate just for going quiet); history is kept, it only fades.
- Decisions are **centralized and deterministic** — the same logic across your whole fleet.

The result: aggressive, concentrated attacks escalate to a ban quickly, while normal traffic
and noisy-but-harmless clients are left alone.

## Quickstart

> Linux + root. Installs system components (systemd unit, IPSet rules, SQLite DB).

**One-liner (no clone needed):**
```bash
curl -fsSL https://raw.githubusercontent.com/hvalero2001-commits/ARE/main/scripts/install.sh | sudo bash
are score 1.2.3.4     # check any IP's reputation
```
> The `sudo` is applied to `bash` (end of the pipe), not `curl` — the installer needs root to
> set up the systemd unit and IPSet. Prefer to read the script first? Use the source method below.

**From source (review before you run):**
```bash
git clone https://github.com/hvalero2001-commits/ARE.git
cd ARE && sudo ./are-installer install && sudo ./are-installer verify
```

Update later with `are-installer upgrade --remote`.
Requirements: `bash`, `sqlite3`, `ipset`, `systemd`. Fail2Ban / ModSecurity act as event
sources when configured.

## ARE vs. the tools you know

| | **Fail2Ban** | **CrowdSec** | **ARE** |
|---|---|---|---|
| Reacts to single events | ✅ | ✅ | ✅ (via sensors) |
| **Accumulated per-IP reputation** | ❌ | ⚠️ (scenarios) | ✅ **core design** |
| **Per-category scoring** (recon vs exploit vs creds…) | ❌ | ❌ | ✅ 9 categories |
| **Reputation decay** over time | ❌ | ⚠️ | ✅ |
| **Staggered ban** (temp → longer → permanent) | ⚠️ (recidive) | ⚠️ | ✅ lifecycle engine |
| Authority over the sensors' own decisions | ❌ | — | ✅ (e.g. overrides a premature F2B unban) |
| Cross-server reputation sharing | ❌ | ✅ (central API) | ✅ fleet export/import, no 3rd party |
| Dependencies / footprint | light | Go agent + API | **Bash + SQLite + IPSet**, no external service |

ARE is **not a replacement** — it's the reputation brain that complements Fail2Ban/ModSecurity.

## Demo

[![asciicast](https://asciinema.org/a/00DD24yGltrAsLba.svg)](https://asciinema.org/a/00DD24yGltrAsLba)

A single attacker escalating in real time: each RCE hit scores the `EXPLOIT`
category, the decision climbs `WATCH → FILTER → TEMP_BAN`, and `are score`
shows the per-category breakdown. Fail2Ban would see unrelated events — ARE
sees one escalating attacker. (`policy-compare` previews the verdict without
enforcing it; `are unban` recovers the IP while keeping its history.)

## Threat categories

`RECON` · `EXPLOIT` · `CREDENTIAL` · `PROTOCOL` · `BOT` · `ANOMALY` · `MALWARE` · `DOS` · `SOCIAL`
— each scored independently by the Policy Engine with configurable thresholds.

## How it works

```text
 Sensors  ──▶  ARE (Reputation · State · Policy · Ban-Lifecycle)  ──▶  IPSet  ──▶  Decision
 Fail2Ban                                                                        ALLOW / WATCH
 ModSecurity                                                                     FILTER
 mod_evasive                                                                     TEMP_BAN
 SpamAssassin                                                                    BANNED
```

Full architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) · Design: [`docs/DESIGN.md`](docs/DESIGN.md)

## Everyday commands

```bash
are score <IP>          # reputation of an IP
are events <IP>         # its recorded events
are top                 # top threats right now
are trends              # daily activity evolution
are policy-compare <IP> # what the engine WOULD decide, without acting (safe)
are decay-dry-run       # preview decay without changing anything (safe)
are admin               # full admin TUI (jails, categories, sensors, policy…)
```

## Safe by default

`policy-compare` and `decay-dry-run` let you validate any configuration change against **real
data without taking any action** — test first, enforce later.

## Documentation

Full docs live in [`docs/`](docs/): User Guide, Architecture, Design, Install lifecycle,
Ban lifecycle, Roadmap, Changelog, Security, Philosophy, and more.

## License

GPL-3.0. See [`LICENSE`](LICENSE).

---

> 🇪🇸 Versión en español: [`README.es.md`](README.es.md)
