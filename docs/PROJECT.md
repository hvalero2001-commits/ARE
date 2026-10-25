# ARE Project

## Introduction

ARE (Abuse Reputation Engine) is a reputation and decision engine designed to turn security events
into intelligent, evidence-based responses.

The project fully decouples threat detection from decision-making, allowing multiple event sources
and multiple response mechanisms to be integrated without modifying the system's core.

ARE does not aim to replace tools like Fail2Ban or ModSecurity.

Its goal is to turn them into information sources for building a unified view of an IP address's
behavior.

---

# Vision

To build an independent reputation engine capable of interpreting the historical behavior of an IP
address and deciding the most appropriate response based on the observed risk.

ARE aims to become a decision platform reusable by any security system.

---

# Mission

Centralize security intelligence.

External systems generate events.

ARE interprets those events.

ARE retains the knowledge.

ARE makes the decisions.

The protection mechanisms only carry out those decisions.

---

# Objectives

The project pursues the following objectives:

- Build persistent reputation.
- Evaluate historical behavior.
- Separate observation and decision.
- Keep a modular architecture.
- Allow incremental growth.
- Ease integration with new sensors.
- Ease integration with new backends.
- Keep a stable, reusable core.

---

# Scope

ARE manages:

- reputation;
- states;
- policies;
- sanction cycle;
- persistence;
- installation;
- observation through sensors.

ARE does not replace:

- Firewalls;
- WAF;
- IDS;
- IPS;
- Fail2Ban;
- ModSecurity.

These components continue to perform their natural function and act as event producers.

---

# Architecture

The project is composed of the following engines:

- Sensor Framework
- Reputation Engine
- State Engine
- Policy Engine
- Ban Lifecycle Engine
- Firewall Backend
- Installer Engine

Each component implements a single responsibility.

---

# Main components

## Sensor Framework

Normalizes events coming from external systems.

---

## Reputation Engine

Builds persistent knowledge through reputation categories.

---

## State Engine

Represents the operational evolution of an IP address.

---

## Policy Engine

Determines the appropriate response based on reputation and state.

---

## Ban Lifecycle Engine

Manages how sanctions evolve.

---

## Firewall Backend

Carries out decisions on the operating system.

---

## Installer Engine

Manages the product lifecycle.

---

# Current status

Latest stable release:

```text
v2.8.4
```

Implemented capabilities:

- Reputation Engine, with an extensible per-category reputation model with no schema migration.
- State Engine.
- Policy Engine, with per-category risk evaluation.
- Ban Lifecycle Engine.
- Sensor Framework, with the polling and callback patterns, and per-sensor operational
  enable/disable control from ARE ADMIN.
- Fail2Ban Sensor.
- Apache/mod_evasive Sensor.
- SpamAssassin Sensor (SOCIAL category).
- Firewall Backend (IPSet), with automatic restoration at system boot.
- Dashboard, with statistics, per-category time-based trends, and anomaly detection.
- Installer Engine, with packaging, distribution, and self-update (available-version query, remote
  update, automatic installation of system dependencies).
- SQLite.
- ModSecurity integration.
- Fail2Ban integration.

---

# Project organization

The official documentation is organized through specialized documents.

| Document | Purpose |
|----------|---------|
| README.md | Project presentation |
| PHILOSOPHY.md | Fundamental principles |
| PROJECT.md | Project definition |
| ARCHITECTURE.md | Architecture |
| DESIGN.md | Design decisions |
| INSTALL.md | Installer lifecycle |
| DEVELOPMENT.md | Development methodology |
| CONTRIBUTING.md | Contributor guide |
| GOVERNANCE.md | Project governance |
| ROADMAP.md | Planned evolution |
| CHANGELOG.md | Version history |
| SECURITY.md | Security policy |
| BAN_LIFECYCLE.md | Sanction cycle |
| USER_GUIDE.md | Administrator guide |
| TODO.md | Pending work |

---

# Evolution

ARE evolves through small iterations.

Each version strengthens the core before adding new capabilities.

Architectural modifications are made through RFCs, and implementation only begins once they are
approved.

---

# Principles

The project's fundamental principles are documented in `docs/PHILOSOPHY.md`, the single source —
this prevents this list from drifting out of sync with that one, as happened until now (two
different "principles" lists across the two documents).

---

# Philosophy

ARE interprets behavior.

It does not respond only to events.

Each IP address builds a reputation.

Each decision represents the consequence of accumulated knowledge.

The intelligence resides in ARE.

External systems only provide information or carry out the decisions the engine generates.

---

> 🇪🇸 Versión en español (referencia): [`PROJECT.es.md`](PROJECT.es.md)
