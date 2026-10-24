# ARE Ban Lifecycle

## Introduction

The Ban Lifecycle Engine is the component responsible for computing the next sanction when the
Policy Engine determines that a temporary sanction (`TEMP_BAN`) is appropriate.

Its responsibility is to determine the next sanction level from the ban level currently recorded
for an IP address and from the times configured for each level.

The Ban Lifecycle Engine does not determine whether an IP address represents a threat. That
responsibility belongs to the reputation, state, and policy flow.

Nor does it modify the firewall directly. Applying the sanction belongs to Policy Apply.

## Objective

The goal of the Ban Lifecycle Engine is to provide a consistent progression of temporary
sanctions.

For each `TEMP_BAN` request, the engine:

1. Initializes the IP's sanction record if necessary.
2. Gets the current ban level.
3. Increments the level by one.
4. Determines the duration corresponding to the new level.
5. Returns the computed sanction.
6. Escalates to a permanent `BAN` when the configured maximum level is reached.

## Responsibility

The component's main function is:

```text
ban_lifecycle_calculate()
```

It receives:

* IP address.

It uses:

* ban level stored in SQLite;
* `BAN_LEVEL_MAX`;
* times configured for the sanction levels.

It returns a decision in the format:

```text
ACTION|TIME|REASON
```

Examples:

```text
TEMP_BAN|3600|BAN_LEVEL_1
BAN|0|BAN_LEVEL_MAX
```

## Flow

```text
Policy Engine
      |
      | TEMP_BAN
      v
Policy Apply
      |
      v
Ban Lifecycle Engine
      |
      +--> Get ban_level
      |
      +--> Increment level
      |
      +--> Compare with BAN_LEVEL_MAX
      |
      +-------------------------+
      |                         |
      v                         v
  Level available          Maximum level
      |                         |
      v                         v
 TEMP_BAN                      BAN
      |                         |
      v                         v
 Configured time         Permanent escalation
```

## Sanction level

The current sanction level is obtained from the persistent information associated with the IP
address.

The next level is computed as:

```text
NEXT_LEVEL = CURRENT_LEVEL + 1
```

If there is no recorded level, the current level is treated as 0.

Therefore, the first temporary sanction corresponds to level 1.

## Temporary levels

The Ban Lifecycle Engine uses the configured times for the following levels:

```text
BAN_LEVEL_1_TIME
BAN_LEVEL_2_TIME
BAN_LEVEL_3_TIME
BAN_LEVEL_4_TIME
BAN_LEVEL_5_TIME
BAN_LEVEL_6_TIME
```

The next level, `BAN_LEVEL_7` (`BAN_LEVEL_MAX`), has no configured time — it corresponds to the
escalation to a permanent block, see the "Escalation" section.

The time used for a sanction depends exclusively on the computed next level and its corresponding
configuration.

A level whose configured time exceeds the maximum supported by the Firewall Backend (see the
"Firewall Backend" section and `IPSET_MAX_TIMEOUT`) is automatically clamped to that limit at the
moment the sanction is applied — the level recorded in `sanction_state` reflects the real
escalation, even though the timeout actually applied to the firewall may be lower than the one
configured for that level.

## Escalation

Before selecting the duration, the engine checks:

```text
NEXT_LEVEL >= BAN_LEVEL_MAX
```

When this condition is met, the engine returns:

```text
BAN|0|BAN_LEVEL_MAX
```

This indicates that the sanction must escalate to a permanent block.

No timeout is computed for this situation.

A permanent block is not reached by the Reputation Decay Engine — its release requires an explicit
administrative decision, not an automatic recovery from inactivity.

## TEMP_BAN

When the next level does not reach `BAN_LEVEL_MAX`, the engine returns:

```text
TEMP_BAN|TIME|BAN_LEVEL_N
```

where:

* `TIME` is the time configured for the level;
* `N` is the next sanction level.

For example:

```text
TEMP_BAN|3600|BAN_LEVEL_1
```

represents a temporary sanction corresponding to level 1 with a duration of 3600 seconds.

While a temporary sanction remains active, the Reputation Decay Engine periodically reduces the
IP's score, applying the reduction to the aggregate total and redistributing it proportionally
across that IP's active categories — each category is not truncated independently. This prevents an
IP with activity spread across several categories from decaying faster than one with activity
concentrated in a single category, given the same total score. Decay does not advance or shorten
the timeout already applied to the Firewall Backend for an ongoing sanction; its effect is
reflected in the evaluation of the next recidivism.

## BAN

When the configured maximum level is reached, the Ban Lifecycle Engine returns:

```text
BAN|0|BAN_LEVEL_MAX
```

Applying this result subsequently belongs to Policy Apply.

The Ban Lifecycle Engine does not directly modify the IPSet sets or the firewall rules.

## Persistence

The sanction level is kept persistently through SQLite.

The Ban Lifecycle Engine uses the stored information to determine the next sanction.

Reputation and events belong to other components of the system and are not modified directly by
this engine.

An active sanction (permanent or temporary, with its exact remaining time) is restored in the
Firewall Backend from this same persistent information when the operating system reboots — see the
"Firewall Backend" section.

## Relationship with the Policy Engine

The Policy Engine determines that an IP address requires a sanction through the decision:

```text
TEMP_BAN
```

Policy Apply receives that decision and asks the Ban Lifecycle Engine to compute the concrete
sanction.

The Ban Lifecycle Engine can return:

```text
TEMP_BAN
BAN
```

Therefore, the flow is:

```text
Policy Engine
      |
      v
TEMP_BAN
      |
      v
Policy Apply
      |
      v
Ban Lifecycle Engine
      |
      +--------+
      |        |
      v        v
 TEMP_BAN    BAN
```

## Relationship with Policy Apply

The Ban Lifecycle Engine computes the sanction.

Policy Apply carries out the result.

When the result is `TEMP_BAN`, Policy Apply:

* computes the expiration moment;
* increments the ban level;
* records the sanction;
* clamps the computed timeout to the maximum supported by the Firewall Backend, if it exceeds it;
* applies the timeout to IPSet;
* sets the corresponding state.

When the result is `BAN`, Policy Apply:

* sets the maximum level;
* marks the sanction as permanent;
* removes previous containments;
* adds the IP to the ban set with no timeout;
* records the event;
* sets the `BANNED` state.

## Firewall Backend

The Ban Lifecycle Engine does not interact directly with the firewall.

Modifying the operating system belongs to Policy Apply through the backend mechanisms ARE uses.

Since ARE v2.0, this mechanism uses exclusively:

```text
IPSet
```

`iptables` and `ip6tables` are no longer part of ARE's Firewall Backend — direct management of
firewall rules was replaced by the exclusive use of IPSet sets, which ARE manages completely,
including their restoration at system boot (IPSet does not natively persist its contents across
reboots; ARE repopulates it from `sanction_state` and `reputation` at start, preserving the exact
remaining time of active temporary sanctions).

The maximum time IPSet allows for a timeout is limited (`IPSET_MAX_TIMEOUT`, in
`config/policy.conf`). Any duration computed by the Ban Lifecycle Engine that exceeds that limit is
clamped to the maximum supported before being applied — see the "Temporary levels" section.

## Principles

The Ban Lifecycle Engine keeps a specific responsibility:

* compute the next sanction;
* apply the level progression;
* select the configured time;
* determine when it is appropriate to escalate to `BAN`.

It is not responsible for:

* detecting events;
* computing reputation;
* determining the IP's general state;
* initially deciding whether `TEMP_BAN` is appropriate;
* directly modifying the firewall;
* restoring the firewall state after a system reboot.

## Summary

The cycle of a temporary sanction in ARE is:

```text
Event
   |
   v
Reputation Engine
   |
   v
State Engine
   |
   v
Policy Engine
   |
   v
TEMP_BAN
   |
   v
Policy Apply
   |
   v
Ban Lifecycle Engine
   |
   +------------------+
   |                  |
   v                  v
TEMP_BAN             BAN
   |                  |
   v                  v
Configured time      Maximum level
(clamped to IPSet     |
 limit if exceeded)   |
   |                  |
   +--------+---------+
            |
            v
       Policy Apply
            |
            v
      Firewall Backend
```

---

> 🇪🇸 Versión en español (referencia): [`BAN_LIFECYCLE.es.md`](BAN_LIFECYCLE.es.md)
