# ARE Development Guide

## Introduction

This document defines the development methodology of ARE (Abuse Reputation Engine).

Its goal is to establish a controlled process for making changes to the project, keeping the system
stable, the architecture coherent, and the documentation in sync with the code.

Documentation is part of development and must reflect the project's real state.

---

# Philosophy

ARE development is based on a fundamental principle:

> **Understand before you implement.**

Before modifying code, you must understand the existing behavior and verify the impact of the change
on the components involved.

Unnecessary modifications must not be made to components that are not part of the change.

---

# Objectives

The methodology seeks to preserve:

* system stability;
* incremental evolution;
* a coherent architecture;
* separation of responsibilities;
* low coupling;
* reuse of existing components;
* documentation in sync;
* traceability of changes.

---

# Development flow

Changes must follow a controlled process:

```text
Problem or need
        │
        ▼
Analysis of current behavior
        │
        ▼
Identification of the affected component
        │
        ▼
Definition of the change
        │
        ▼
Implementation
        │
        ▼
Verification
        │
        ▼
Documentation update
        │
        ▼
Commit
```

Each stage must be completed before the change is considered finished.

---

# Incremental development

ARE evolves through small, verifiable changes.

Before starting a change, you must verify the existing behavior and determine which components are
actually involved.

Files or components that are not necessary to solve the problem or implement the corresponding change
must not be modified.

When a modification produces incorrect behavior, the problem must be resolved and verified before
continuing with other dependent changes.

---

# Change classification

Changes can be classified according to their nature.

## BUG

A fix for existing incorrect behavior.

The fix must preserve the features that are not part of the problem.

---

## TASK

Technical maintenance, reorganization, or documentation work.

The scope of the change must be kept clearly defined.

---

## FEATURE

Adding a new feature.

The feature must be integrated respecting the responsibilities of the existing components.

---

## RFC

A proposal for an architectural modification.

Changes that alter fundamental responsibilities, interfaces, or relationships between components must
be analyzed before being implemented.

---

## IDEA

A proposal that is not yet part of a defined implementation.

An idea does not, by itself, represent an implemented feature.

---

# Implementation principles

## Single responsibility

Each component must keep a clearly defined responsibility.

A modification must not move responsibilities between components without a verifiable architectural
reason.

---

## Reuse

When a function or component already solves a need, its reuse must be evaluated before creating a
duplicate implementation.

Logic must not be duplicated unnecessarily.

---

## Modularity

Features must stay separate according to their responsibility.

Adding a feature must not introduce unnecessary dependencies on unrelated components.

---

## Simplicity

Simple, verifiable solutions must be prioritized.

Complexity that is not necessary to solve the concrete problem must not be introduced.

---

## Behavior preservation

Modifications must preserve the existing behavior when it is not part of the requested change.

Additional changes must not be made merely for convenience, cleanup, or reorganization if they are
not necessary for the change's objective.

---

# Architecture

Development must respect the existing separation between:

* Sensor Framework;
* Reputation Engine;
* State Engine;
* Policy Engine;
* Ban Lifecycle Engine;
* Apply Engine;
* Firewall Backend;
* Reputation Decay Engine;
* ARE ADMIN;
* Installer Engine.

Each component must use the functions and mechanisms corresponding to its responsibility.

Modifications that affect the relationships between these components must be verified against the
system's real behavior.

---

# Documentation

Documentation is part of the project's source.

When a change modifies ARE's documented behavior, the corresponding documents must be updated to
reflect the real state of the code.

Depending on the scope of the change, the following may be affected:

* README.md;
* PROJECT.md;
* ARCHITECTURE.md;
* DESIGN.md;
* INSTALL.md;
* CHANGELOG.md;
* ROADMAP.md;
* CONTRIBUTING.md;
* GOVERNANCE.md;
* SECURITY.md;
* BAN_LIFECYCLE.md;
* USER_GUIDE.md.

The documentation must not describe features that are not implemented.

Nor must it present as current behavior a capability that belongs only to future planning.

---

# Verification

Every modification must be verified before being considered finished.

Verification must check, as applicable:

* the change's operation;
* no introduced errors;
* preservation of unaffected behavior;
* consistency with the components involved;
* preservation of persistent data where appropriate.

Verification must be based on observable results from the system, not on assumptions.

---

# Installer Engine

Changes related to the Installer Engine must be verified according to the affected operation.

The operations managed by the Installer Engine are:

* install;
* upgrade;
* repair;
* verify;
* uninstall.

Validation must be limited to the operations actually modified by the change and their direct
dependencies.

---

# Commits

Each commit must represent an identifiable and coherent change.

Messages must be:

* clear;
* specific;
* traceable;
* representative of the commit's real content.

Examples:

```text
BUG-008  Fix reputation calculation

TASK-012  Refactor installer manifest

FEAT-005  Add Sensor Framework

DOC-006  Rewrite installation guide
```

A commit must not be used to hide changes unrelated to its objective.

---

# Quality

Before closing a change, the following must be verified:

* code corresponding to the defined objective;
* verified operation;
* no unnecessary modifications;
* documentation updated where appropriate;
* consistency with the architecture;
* repository state reviewed.

---

# Final principles

ARE development must keep the following principles:

1. Understand before you implement.
2. Change only what is necessary.
3. One responsibility per component.
4. Verify before concluding.
5. Fully resolve the problems you find before continuing.
6. Preserve unaffected behavior.
7. Reuse existing components before duplicating logic.
8. Keep the documentation in sync with the code.
9. Base conclusions on verifiable behavior.
10. Keep each change traceable and coherent.

---

> 🇪🇸 Versión en español (referencia): [`DEVELOPMENT.es.md`](DEVELOPMENT.es.md)
