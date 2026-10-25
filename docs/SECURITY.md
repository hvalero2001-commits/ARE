# Security Policy

## Introduction

Security is one of the fundamental principles of ARE (Abuse Reputation Engine).

This document defines the official policy for reporting, analyzing, fixing, and disclosing
vulnerabilities related to the project.

The goal is to ensure responsible handling of security incidents and to keep the core stable
before publishing any fix.

---

# Supported versions

| Version | Status |
|---------|:------:|
| 2.8.x | ✅ Supported |
| 2.7.x | ✅ Limited support |
| ≤ 2.6.x | ❌ Not supported |

---

# Reporting vulnerabilities

If you discover a vulnerability in ARE, please avoid disclosing it publicly before it can be
analyzed.

Please report it privately through the repository's **Security** tab, using **Report a
vulnerability** (GitHub private security advisory). This keeps the report confidential until
a fix is published.

Every report should include, whenever possible:

- a description of the problem;
- steps to reproduce it;
- expected impact;
- affected components;
- available evidence;
- a proposed mitigation (optional).

Reports should make it possible to reproduce the observed behavior.

---

# Classification

Every vulnerability is assessed considering:

- impact on availability;
- impact on integrity;
- impact on confidentiality;
- ease of exploitation;
- scope of the problem;
- possibility of remote exploitation.

This classification determines the priority of the fix.

---

# Handling process

Every incident follows the process below.

```text
Report
 │
 ▼
Analysis
 │
 ▼
Validation
 │
 ▼
Classification
 │
 ▼
Fix
 │
 ▼
Testing
 │
 ▼
Documentation update
 │
 ▼
New version
 │
 ▼
CHANGELOG
```

Fixes must be validated before becoming part of a stable version.

---

# Responsible disclosure

ARE promotes responsible disclosure.

A vulnerability should only be made public when:

- it has been analyzed;
- a fix is available or a mitigation is documented;
- the fixed version has been published.

---

# Scope

This policy applies to all of the project's official components.

It includes:

- Sensor Framework;
- Reputation Engine;
- State Engine;
- Policy Engine;
- Ban Lifecycle Engine;
- Apply Engine;
- Firewall Backend;
- ARE ADMIN;
- Installer Engine;
- Dashboard;
- SQLite;
- official scripts;
- documentation distributed with the product.

---

# Security fixes

Fixes must follow the same principles as the rest of the project.

- one responsibility per change;
- documentation kept in sync;
- mandatory testing;
- no regressions;
- preservation of the architecture.

Unrelated functional changes must not be introduced within a security fix.

---

# Quality

Before publishing a fix, the following must be verified:

- correct operation;
- successful tests;
- updated documentation;
- no new problems;
- CHANGELOG update where appropriate.

---

# Philosophy

Security is not only about fixing vulnerabilities.

It is about keeping an architecture that is simple, verifiable, and ready to evolve.

Each fix must strengthen the project without compromising the stability of the core.

ARE prioritizes prevention, evidence, and incremental evolution as fundamental principles of its
security strategy.

---

> 🇪🇸 Versión en español (referencia): [`SECURITY.es.md`](SECURITY.es.md)
