# ARE Design

## 1. Purpose

This document defines the design principles and decisions that guide the implementation of ARE
(Abuse Reputation Engine).

`ARCHITECTURE.md` describes how the system is composed.

`DESIGN.md` describes why the system is designed that way.

The decisions documented here correspond to the implemented and validated design. Future proposals
belong to the Roadmap or to the corresponding RFCs.

---

# 2. Design principles

## 2.1 Single responsibility

Each ARE component must keep a clearly defined responsibility.

Observation, reputation, state, decision, sanction, enforcement, and product administration must
not be mixed unnecessarily.

The separation allows:

* reducing coupling;
* easing testing;
* isolating changes;
* avoiding duplicated logic;
* easing the system's evolution.

---

## 2.2 Separation between observation and decision

External systems produce events.

Sensors turn those events into information ARE can process.

Sensors do not determine the security response.

The decision belongs to the ARE core.

The conceptual flow is:

```text
external source
      |
      v
    sensor
      |
      v
    event
      |
      v
ARE interprets
      |
      v
ARE decides
```

This separation was established during v1.1 through the Sensor Framework and is kept in v2.0.

---

## 2.3 Separation between decision and execution

The Policy Engine determines the action.

The mechanism responsible for applying the decision carries out the action through the Firewall
Backend.

Therefore:

```text
Policy Engine
      |
      | what to do
      v
Apply
      |
      | how to apply it
      v
Firewall Backend
```

The decision engine must not contain unnecessary logic specific to a concrete backend.

---

## 2.4 Knowledge persistence

ARE must not depend exclusively on the momentary state of the external system.

Accumulated knowledge must be kept persistently.

The model distinguishes between:

```text
events
    |
    +-- observed activity

reputation
    |
    +-- accumulated knowledge

sanction_state
    |
    +-- sanction state
```

This separation makes it possible to reconstruct the operational state without conflating the
event history with the reputation or the sanction cycle.

---

# 3. Reputation model

## 3.1 Accumulated reputation

Reputation represents the observed behavior of an IP address.

An individual event can modify the reputation, but the decision must not depend exclusively on the
last event.

Historical information is a fundamental part of ARE's model.

---

## 3.2 Categories

Reputation categories make it possible to classify different types of behavior.

The model was extended during v1.1 and is the base v2.0 uses.

Jails do not become independent columns of the `reputation` table.

The relationship between a jail and a category is kept through `jail_profile`.

This allows adding or modifying profiles without changing the main reputation structure.

The catalog of supported categories is kept explicitly in `config/policy.conf` through
`REPUTATION_CATEGORIES`, as a single source of truth consumed both by the reputation model and by
the administration interface (see Section 13).

---

# 4. Risk-based decision model

ARE uses accumulated reputation, state, and policy to determine the response.

The model avoids treating block time as the only source of decision.

Conceptually:

```text
events
   |
   v
reputation
   |
   v
state
   |
   v
policy
   |
   v
decision
```

The response can evolve according to the IP's accumulated behavior.

This makes it possible to differentiate between:

* minimal activity;
* observation;
* filtering;
* temporary block;
* permanent block.

---

## 4.1 Per-category risk evaluation

The Policy Engine evaluates an IP's risk per category independently before issuing a decision. Each
reputation category (Section 3.2) has its own rule (`policy/rules/*.sh`) that knows only its own
threshold, configured in `policy.conf`, and contributes to the total risk only if it is exceeded.
No rule knows the others or decides an action by itself — that responsibility belongs exclusively
to the orchestrator (`policy_evaluate()`).

```text
IP
 |
 v
context (per-category score + recent activity)
 |
 v
EXPLOIT rule --\
BOT rule -------\
RECON rule ------ >-- risk accumulator
PROTOCOL rule --/
... rule       -/
 |
 v
per-category risk
 |
 v
MAX(per-category risk, accumulated total score)  <- safety floor
 |
 v
final decision
```

The **safety floor** guarantees that the per-category engine is never less strict than a simple
total-score evaluation: it can detect more (for example, a brute-force signal that no individual
category reflects), but never less. This prevents an IP whose risk is spread across several
categories — each below its own threshold — from evading detection even when its accumulated total
score is high.

A category with no threshold configured in `policy.conf` does not evaluate — explicit behavior, not
a silent error — which makes it possible to add new categories progressively, without having to
define their risk criterion in advance.

---

# 5. Lifecycle of an IP

An IP address observed by ARE keeps information throughout its entire lifecycle.

The general cycle is:

```text
observation
     |
     v
reputation
     |
     v
state
     |
     v
decision
     |
     v
sanction
     |
     v
recovery
     |
     v
re-evaluation
```

The goal is to prevent an IP from immediately losing all its history due to a temporary absence of
activity.

---

# 6. Decay and recovery

## 6.1 Principle

Reputation can gradually decrease when relevant activity stops.

Recovery is not the same as deleting the reputation.

The mechanism progressively reduces the score and lets ARE re-evaluate the state and the policy.

---

## 6.2 Frequency control

Execution control is separate from the IP's general activity.

For this it uses:

```text
last_decay
```

in `reputation`.

This avoids using the date of last activity as if it were the date of the last decay run.

The design makes it possible to distinguish:

```text
last activity
```

from:

```text
last applied decay
```

---

## 6.3 Separation between recovery and enforcement

The Decay Engine modifies the reputation and triggers a re-evaluation.

Reputation recovery must not be confused with a direct order to modify the firewall.

The flow is:

```text
Decay
  |
  v
Reputation
  |
  v
State Engine
  |
  v
Policy Engine
  |
  v
decision
```

Applying that decision remains under the system's corresponding responsibilities.

---

# 7. Ban Lifecycle

## 7.1 Separation of responsibilities

The Ban Lifecycle Engine does not determine whether an IP is dangerous.

That decision belongs to:

* Reputation Engine;
* State Engine;
* Policy Engine.

Ban Lifecycle determines how a sanction evolves once the policy decides to apply a sanction action.

---

## 7.2 Persistence

The sanction state is kept in:

```text
sanction_state
```

The persisted information makes it possible to distinguish:

* sanction level;
* historical count;
* duration;
* termination;
* permanence.

This allows recidivism to have cumulative consequences.

---

## 7.3 Escalation

Sanctions can evolve progressively.

The design contemplates:

```text
TEMP_BAN
    |
    v
higher level
    |
    v
longer duration
    |
    v
permanent BAN
```

Escalation stays separate from the initial risk determination.

---

# 8. Sensors

Sensors are input adapters.

Their responsibility is to turn external information into events ARE can process.

A sensor must not:

* decide the policy;
* directly modify the reputation without going through the defined flow;
* replace the Policy Engine;
* take on Firewall Backend responsibilities.

The Sensor Framework makes it possible to add new sources without unnecessarily changing the core.

The first official implementation is the Fail2Ban sensor.

It currently processes:

```text
FOUND
EXTERNAL_UNBAN
```

and uses a persistent offset to avoid reprocessing.

---

# 9. Fail2Ban as an event source

Fail2Ban is not ARE's final decision authority.

Its role within the model is to provide information about observed activity.

The flow is:

```text
Fail2Ban
    |
    v
Sensor
    |
    v
ARE
    |
    v
Reputation
    |
    v
Policy
```

This lets ARE keep an accumulated view of the IP instead of depending exclusively on an individual
Fail2Ban action.

---

# 10. Decoupled configuration

Configuration must not be unnecessarily embedded inside the engines.

Operational configuration is kept separate from the product's code.

In v2.0 the official structure uses:

```text
/opt/are
/opt/are/config
/var/lib/are
/var/log/are
```

The Product Manifest defines which components are part of the product and how they are managed.

The configuration distributed with the product and an installation's active configuration are
different concepts.

The Installer manages this relationship.

---

# 11. Product Manifest

`manifest/product.sh` is the product's structural definition.

The Manifest centralizes:

* product identity;
* version;
* directories;
* files;
* configuration;
* persistent data;
* executables;
* links;
* systemd;
* logrotate;
* exclusions.

The Manifest does not contain the engines' logic.

Its function is to provide a single source for the Installer to know what it must manage.

---

# 12. Installer Engine

The Installer Engine manages the installation lifecycle.

The operations are:

```text
install
upgrade
repair
verify
uninstall
```

The design keeps separate:

```text
product
configuration
persistent data
logs
services
links
```

An `upgrade` can update the product components without destroying the persistent data.

A `repair` can rebuild missing components of an incomplete installation.

A `verify` checks that the required components are present and operational.

An `uninstall` removes the product without automatically turning the persistent data into part of
the removed content.

---

# 13. Administration Interface (ARE ADMIN)

## 13.1 Purpose

ARE ADMIN is ARE's command-line administration interface.

Its function is to expose, in an organized way, the query, configuration, and operation
capabilities of the components already defined in this document.

ARE ADMIN does not introduce a new engine or a new decision authority. It is an administration
layer built on top of the existing components: Reputation Engine, State Engine, Policy Engine,
Sensor Framework, Decay Engine, and Installer Engine.

It is accessed through `are.sh admin`, or directly through `admin.sh` as an equivalent shortcut.
Both paths load the same `bootstrap.sh` the rest of the system uses, so ARE ADMIN always operates
on the same real components, without duplicating logic or maintaining a separate loading
environment.

---

## 13.2 Design principle

ARE ADMIN respects the separation of responsibilities established in Section 2.

The CLI does not decide, does not enforce, and does not sanction. The CLI queries, administers, and,
when appropriate, invokes the corresponding engines, respecting the flow each one defines.

Consequently:

* ARE ADMIN does not directly modify the `reputation` table;
* ARE ADMIN does not directly modify the Firewall Backend;
* ARE ADMIN does not replace the Policy Engine or the Decay Engine;
* ARE ADMIN administers `jail_profile`, the decoupled configuration, and the installation lifecycle
  through each component's already-existing interfaces.

---

## 13.3 Menu structure

ARE ADMIN's navigation tree directly reflects the composition of ARE described in the previous
sections. Each branch corresponds to a component already defined in the design.

Two branches add, beyond the original query capabilities, an extra summary/diagnostic item that
reuses already-existing Dashboard commands (`dashboard_stats`, `dashboard_status`), without
introducing new logic:

```text
ARE ADMIN
│
├── 1. Jails / Profiles
│   ├── List
│   ├── Create
│   ├── Modify
│   ├── Delete
│   └── Validate
│
├── 2. Categories
│   ├── List
│   └── View scores
│
├── 3. Sensors
│   ├── Status
│   └── Configuration
│
├── 4. Policy
│   ├── View configuration
│   └── Validate
│
├── 5. State / Reputation
│   ├── Query IP
│   ├── Events
│   ├── Top
│   └── Statistics
│
├── 6. Decay
│   ├── Status
│   ├── Dry-run
│   └── Run
│
├── 7. Configuration
│   ├── View
│   ├── Validate
│   └── System status
│
└── 0. Exit
```

---

## 13.4 Correspondence with the design components

Each menu branch is built on an already-defined component, without duplicating its logic:

* **Jails / Profiles** administers `jail_profile` (Section 3.2) through a full CRUD. Create, Modify,
  and Delete operate on the jail–category relationship, not on the `reputation` structure. The
  category is restricted to `REPUTATION_CATEGORIES` through numbered selection, never free text.
  Create and Modify offer weight/confidence assistance at two levels: a statistical reference
  computed from real existing profiles in the category, or an admin-curated level scale
  (`config/jail_scale.conf`) when the category defines one. Delete requires typing the jail's exact
  name as confirmation, not just a y/N answer, since it is the CRUD's only destructive operation.
  Validate reuses the consistency-check concept described for the Installer Engine (Section 12),
  checking for a valid category and weight/confidence ranges.
* **Categories** exposes the reputation model (Section 3) in read-only mode, including the scores
  associated with each category. The category catalog and its thresholds are read dynamically from
  `REPUTATION_CATEGORIES` in `config/policy.conf` (Section 3.2), keeping the listing from being
  hardcoded in the interface.
* **Sensors** exposes the status and configuration of the Sensor Framework (Section 8), without
  letting the CLI decide policy or directly modify reputation. The status includes the sensor's
  persistent offset and the status of the associated systemd timer.
* **Policy** allows inspecting and validating the Policy Engine's configuration (Section 4), without
  directly running a decision on a specific IP. A branch pending implementation: there are concurrent
  definitions of the decision engine in the code base whose coexistence is not resolved; the branch
  will be enabled once the canonical engine is identified (see `docs/TODO.md`).
* **State / Reputation** allows querying the accumulated knowledge (Section 2.4) and an IP's event
  history, obtaining a prioritized listing (Top), and querying an aggregate activity summary
  (Statistics), reusing `dashboard_score`, `dashboard_events`, `dashboard_top`, and `dashboard_stats`
  respectively.
* **Decay** exposes the cycle described in Section 6. *Status* queries `last_decay` and the current
  candidates; *Dry-run* simulates the Decay Engine's effect without modifying `reputation` or
  triggering a real re-evaluation; *Run* invokes the full Decay → Reputation → State Engine → Policy
  Engine flow (Section 6.3), delegating the actual application of any resulting decision to the Apply
  mechanism already defined in Section 2.3. The Run operation requires explicit confirmation before
  being invoked.
* **Configuration** allows viewing and validating the decoupled configuration (Section 10), without
  embedding that configuration in the engines' code, and querying the system's general operational
  status (database, Decay, Firewall, IPSet) by reusing `dashboard_status`.

---

## 13.5 Scope of write operations

The write operations available from ARE ADMIN are limited to configuration and administration
elements: jail profiles and operational configuration.

ARE ADMIN does not offer an operation that directly modulates `reputation` or `sanction_state`. Any
change to an IP's accumulated knowledge results exclusively from the normal operation of the engines
(Sensor Framework, Decay Engine, Policy Engine), and not from a manual action run from the CLI.

This preserves the integrity of the reputation model described in Section 3 and keeps the
administration interface from becoming a parallel path to decisions.

---

## 13.6 Implementation status

The seven branches defined in Section 13.3 are implemented, verified through isolated tests, and
confirmed operating in production with real data: Jails/Profiles, Categories, Sensors, Policy,
State/Reputation, Decay, and Configuration.

Implementing the Policy branch (see RFC-009) revealed, through its own validation, a reputation
category (`CREDENTIAL`) with no associated evaluation rule despite having a configured threshold —
fixed as part of the same work (see `docs/TODO.md`, BUG-016). It is an example of the purpose of the
validation built into the CLI: detecting inconsistencies between configuration and implementation
before they manifest as silent incorrect behavior.

---

# 14. Compatibility and evolution

v2.0 is not designed as a conceptual break from v1.1.

The stable v1.1 version provided the functional base on which v2.0 was developed.

The v2.0 evolution mainly affected:

* product identity;
* operational structure;
* installation;
* persistence;
* maintenance;
* integration of the recovery cycle;
* component organization;
* administration interface.

Future capabilities that have not yet been implemented and validated must not be incorporated as
already-made design decisions.

---

# 15. Evidence-based design

ARE's design decisions must arise from:

1. an identified need;
2. analysis;
3. implementation;
4. testing;
5. validation;
6. documentation.

Documentation must not be used to retroactively define behavior the system does not yet implement.

The system's real, validated behavior is the primary reference for updating this document.

---

# 16. Incremental evolution

ARE must evolve without introducing unnecessary changes.

A modification must be integrated into the responsible component rather than duplicating an
existing capability.

When a modification affects the architecture, it must be reflected in the corresponding
documentation.

Proposals that have not yet been implemented belong to the Roadmap or the RFCs and are not part of
the current operational design.

---

# 17. Design status

The current design keeps the principles established during v1.1 and adapts them to the operational
structure consolidated through v2.0, v2.1, and v2.2.

## Decisions consolidated in v2.0

* separation between sensors and decision;
* separation between decision and execution;
* independent persistence of events, reputation, and sanctions;
* Ban Lifecycle as an independent component;
* recovery through Decay;
* decoupled configuration;
* Product Manifest as the product's structural definition;
* Installer Engine as the installation-lifecycle manager;
* the ARE ADMIN administration interface as a query-and-administration layer over the existing
  components, with no decision authority of its own, integrated into the official entry point
  (`are.sh admin`) and operating on the same `bootstrap.sh` as the rest of the system;
* ARE's own operational structure;
* incremental evolution on the stable v1.1 base.

## Decisions consolidated in v2.1

* a normalized per-category reputation model (`reputation_scores`), where adding a new category is a
  data operation and not a schema or code migration;
* `total_score` always derived as the sum of the categories, instead of stored independently —
  structurally eliminating the possibility that it drifts from the real data;
* a second sensor pattern formalized within the Sensor Framework: callback (direct, synchronous
  invocation at the moment of the event), alongside the already-existing polling pattern;
* the jail filter resolved dynamically against `jail_profile`, instead of kept as a fixed list in
  each sensor's code;
* profile administration across servers (export/import), as a mechanism to propagate calibration
  without recreating each profile by hand;
* Firewall Backend restoration from the database at system boot, since IPSet does not natively
  persist its contents across reboots.

## Decisions consolidated in v2.2

* an "adapter per source" pattern within a sensor: data extraction varies by the real source (today,
  Exim for SpamAssassin), but the reporting contract toward the Reputation Engine stays single —
  adding a new source is adding a function, not rewriting the sensor;
* separating responsibility between `config.conf` (infrastructure: what to read and from where) and
  `policy.conf` (decision calibration: when something matters), applied to a sensor's configuration
  too, not just the global thresholds;
* proactive calibration of a category threshold with no local sensor available (`MALWARE_THRESHOLD`),
  as a conscious generic-engine decision — useful for any server with real surface for that threat,
  not just the one calibrating it;
* packaging and distribution as a layer added *before* the Installer Engine, without changing its
  core — the installation engine still operates exactly the same, whether it receives its source from
  a `git clone` or from a downloaded and extracted package.

## Decisions consolidated in v2.3

* a sensor's activation state (`sensor_registry`) is independent of a jail's state (`jail_profile`) —
  disabling a sensor stops the generation of new events, without needing to touch or mark the
  already-existing profiles; the historical reputation remains intact without any extra flag;
* a sensor's activation mechanism depends on its pattern, not on a single interface: `systemctl` for
  polling, a lightweight flag file for callback — the cost of querying the database on every invocation
  was explicitly evaluated for a sensor that can fire very frequently (callback under a real flood),
  and discarded in favor of a file check;
* a risk engine of our own decides by its own criterion, instead of delegating to another tool's
  internal verdict — the SpamAssassin sensor filters by score against `SPAMASSASSIN_MIN_SCORE`, not by
  the boolean "spam"/"NOT spam" flag the external tool assigns by its own internal criterion,
  potentially misaligned with the real risk threshold that matters to ARE.

## Decisions consolidated in v2.4

* simplifying a `CREATE TABLE` for new installations does not require waiting for a modern SQLite
  version on any server — only `ALTER TABLE ... DROP COLUMN` on an already-existing database requires
  it; separating the two cases let half the work proceed immediately, instead of blocking everything
  on one environment's limitation;
* the installation must leave the product fully operational on its own, without depending on the
  operator running any manual step afterward — any verification (`verify`) that depends on a side
  effect of a later run, instead of the installation itself, is an incomplete installation even if it
  appears to work in practice;
* a hard dependency (`Requires=`) between a component of ours and an optional external tool assumes
  that tool will always be present — when the component itself already tolerates its absence cleanly
  (a nonexistent log, for example), the systemd dependency must reflect that (`After=`, not
  `Requires=`), not be stricter than the logic that already exists;
* validating a demonstration with manual commands in between is not the same as validating the
  installation itself — any verification of an automated flow must reproduce exactly that flow, with
  no human intervention between the trigger and the result check.

## Decisions consolidated in v2.5

* a sensor may need stateful correlation (grouping multiple events by a time window) instead of
  line-by-line evaluation — the reporting contract toward ARE (`found <IP> <JAIL>`) stays the same,
  the aggregation complexity is encapsulated inside the sensor, without touching the data model or the
  decision engine;
* a sensor-specific configuration parameter must not assume the use case of whoever requested it — a
  generic, configurable path marker (`cart`, applicable to any e-commerce catalog) generalizes the
  sensor much more than a value hardcoded to the specific business that prompted the need;
* documenting the real evidence that justifies a detection threshold (captures of real correlation,
  verification of origin infrastructure) before calibrating it, instead of choosing an arbitrary
  number — the calibration of a new sensor's `jail_profile` must be explainable with that same
  evidence, not just intuition.

## Decisions consolidated in v2.6

* not all data shared between two instances of the same product has the same correct conflict
  mechanism — configuration (`jail_profile`) needs "overwrite/keep" because each field has a single
  valid value; reputation needs to choose nothing, because it is already designed to accumulate, and
  the import simply reuses that same accumulation;
* a relevance filter does not always need an explicit administrator decision — relying on a structure
  that already exists (`jail_profile`, a reflection of the server's real role) answers "is this useful
  to this server?" for free, without inventing a new "role" concept in the data model.

## Decisions consolidated in v2.7

* a mechanism that modifies a file also edited by hand by the administrator must clearly delimit its
  own zone (`BEGIN`/`END` markers), never assume it can replace the whole file — any manual entry
  outside that block must survive indefinitely, no matter how many times it is synchronized;
* an integration with an external source must never leave the system in a worse state than before
  attempting it — validate the downloaded content before writing anything, and abort without touching
  the file if validation fails, instead of applying a partial or empty result;
* not every systemd unit that gets installed must be enabled automatically — when it depends on
  explicit administrator configuration to make sense, enabling it without that configuration is just
  noise; the Installer Engine needed to distinguish between "install" (always) and "enable" (only when
  appropriate), something that did not exist until this version.

Future capabilities that have not yet been implemented and validated are not part of the current
state of the design; they belong to the Roadmap or the corresponding RFCs.

Version v2.8 is in development and validation. This document describes only decisions corresponding
to the implemented and verified state.

---

> 🇪🇸 Versión en español (referencia): [`DESIGN.es.md`](DESIGN.es.md)
