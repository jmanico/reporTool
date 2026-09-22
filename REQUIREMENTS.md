# Requirements

This document is the **source of truth** for reporTool. It describes what the system must do, for whom, and the constraints it must operate under. Architecture and implementation decisions should trace back to a requirement in this document; if they can't, either the requirement is missing or the work is out of scope.

Status: **draft, actively evolving.** Sections marked `[OPEN]` are known gaps that need a decision before implementation.

---

## 1. Purpose

reporTool is a platform for a pentest group to run and report on security testing engagements. It replaces ad-hoc spreadsheets, Word templates, and manual copy/paste from tools like Burp Suite with a system that:

- Standardizes how findings are captured, reviewed, and mapped to CWE/ASVS
- Tracks engagements across many customers and departments
- Generates client-ready reports from structured data instead of manual document editing
- Enforces fine-grained access control over who can see and edit what
- Manages engagement credentials and secrets safely

## 2. Users / personas

| Persona | Description |
|---|---|
| **Pentester (Author)** | Runs testing, creates findings, discovered-asset lists, and imports tool output. |
| **Technical Reviewer** | Reviews a finding for technical accuracy before it moves forward. |
| **Final Reviewer** | Signs off on a finding/report before client delivery (e.g. team lead, QA). |
| **Engagement/Project Manager** | Manages customers, departments, and pentest engagements; assigns pentesters; tracks status. |
| **Customer/Client (read-only)** | Scoped, read-only access to their own customer's findings/reports. In scope for v1 (SECURITY.md SQ-7). |
| **Admin** | Manages users, roles, ABAC policies, KMS/secrets configuration, and report templates. |

## 3. Core domain model

The org hierarchy, from broadest to narrowest scope:

```
Customer
 └─ Department
     └─ Pentest (engagement)
         ├─ Finding
         │   └─ Finding Field (individual attributes of a finding)
         ├─ Discovered Asset (IP, domain, cloud account, etc.)
         └─ Imported Artefact (Burp log, scanner output, work log, etc.)
```

Every access-control decision is scoped to one or more levels of this hierarchy (see §6).

### 3.1 Customer
A client organization the pentest group works for. Has one or more departments engaged separately over time.

### 3.2 Department
A sub-unit of a customer (e.g. "Payments", "Mobile", "Infra"). Engagements belong to a department, not directly to a customer, since the same customer may run multiple concurrent/independent engagements across departments.

### 3.3 Pentest (engagement)
A single scoped testing engagement: has a start/end date, scope definition, assigned pentester(s), status, and produces one or more reports.

### 3.4 Finding
An individual security finding discovered during a pentest. Minimum required fields:

- Title / summary
- Description
- Severity (and a defined scoring methodology — `[OPEN: CVSS? custom scale?]`)
- Affected asset(s) / location
- Steps to reproduce
- Evidence (screenshots, requests/responses, logs)
- Remediation guidance
- **CWE mapping** — one or more CWE IDs
- **ASVS control mapping** — one or more ASVS requirement IDs
- Status (see review workflow, §5)
- Author, timestamps, review history

### 3.5 Finding Field
Findings are composed of individually addressable fields (title, description, evidence, severity, etc.) because ABAC must be enforceable **per field**, not just per finding (see §6.4).

### 3.6 Discovered Asset
An in-scope or in-scope-adjacent asset identified during testing: IP address, domain/subdomain, cloud account (AWS/Azure/GCP), hostname, URL, etc. Assets are tracked independently of findings so they can be compiled into an asset inventory for the report, and so multiple findings can reference the same asset.

### 3.7 Imported Artefact
Raw or semi-structured output imported from a tool (Burp Suite export, other scanner output, analyst work log). See §7 (Data Import).

## 4. Functional requirements

### 4.1 Finding management
- FR-1: A pentester can create, edit, and submit an individual security finding.
- FR-2: Findings must be organized into a standardized testing artefact log per pentest.
- FR-3: Each finding can be linked to one or more **CWE** identifiers.
- FR-4: Each finding can be linked to one or more **OWASP ASVS** controls.
- FR-5: A pentester can report on a list of discovered assets (IPs, domains, cloud accounts, etc.) for inclusion in the report.
- FR-6: A pentester can import findings from Burp Suite and other scanner/tool output (see §7).

### 4.2 Engagement management
- FR-7: The system supports many customers, each with multiple departments, each with multiple pentest engagements, running concurrently or over time.
- FR-8: Engagement/project managers can create and manage customers, departments, and pentests, and assign pentesters to engagements.

### 4.3 Review & acceptance workflow
- FR-9: Findings move through a defined lifecycle: **Author (draft) → Technical Review → Final Review → Accepted**.
- FR-10: Reviewers are access-controlled — only users granted reviewer access to a given finding/pentest can act on it at that stage.
- FR-11: An optional **AI-assisted review pass** can run before a finding is routed to human technical review, to catch obvious issues (missing evidence, inconsistent severity, unmapped CWE/ASVS, etc.). It is **advisory only** (SECURITY.md SQ-2) — it cannot block or bypass the review workflow. `[OPEN: the exact check list beyond this example set]`
- FR-12: Full review history (who, when, what changed, comments) is retained per finding.

### 4.4 Access control (ABAC)
- FR-13: Access control must be enforceable at each level of the hierarchy: **customer, department, pentest, finding, and individual finding field.**
- FR-14: Access decisions are attribute-based (ABAC), not just role-based — e.g. a policy might grant access based on user attributes (team, clearance) combined with resource attributes (customer, sensitivity, engagement status) and context (review stage).
- FR-15: Reviewer assignment is itself access-controlled — only authorized users can be assigned/granted reviewer rights on a given pentest or finding.

### 4.5 Secrets / credential management
- FR-16: The system stores and manages credentials used during engagements (e.g. VPN, scoped test accounts, API keys), scoped per pentest/project.
- FR-17: Credentials are backed by a cloud KMS/secrets manager, not stored in the application database in plaintext.
- FR-18: Access to a given engagement's credentials is governed by the same ABAC model as findings (§4.4).

### 4.6 Data import
- FR-19: Analysts can import work logs (e.g. Burp Suite logs) into the system.
- FR-20: Imports are normalized into standardized testing artefact types (e.g. timestamped automated notes, access-requirement records) rather than stored as opaque blobs.
- FR-21: Imported artefacts are linked back to the pentest (and, where applicable, to the findings/assets they support).

### 4.7 Report engine
- FR-22: Report generation is a first-class feature, not a bolt-on export.
- FR-23: Admins/managers can upload a baseline report template and modify it.
- FR-24: Templates are access-control aware — a generated report only includes sections/fields the recipient is entitled to see, consistent with ABAC (§4.4).
- FR-25: Customer and team logos/branding can be uploaded and applied to generated reports.
- FR-26: Every generated report produces a durable generation record — who requested it, the recipient scope it was generated under, the template version, and the exact set of findings/assets/artefacts (with versions) it contained — so a delivered report can be reconstructed and disputed content resolved. Enforcement detail: SECURITY.md SEC-LOG-5 (threat T-014).

### 4.8 Accountability and operational safety

*(Added by the 2026-09-21 threat model; each item is functional behavior a user or operator observes. The corresponding enforcement rules live in SECURITY.md.)*

- FR-27: The system enforces separation of duties in the review workflow — a finding's author cannot technically or finally review it, the technical reviewer cannot also perform its final review, and no user can grant themselves reviewer rights. The UI surfaces why an action is unavailable rather than failing silently. Enforcement: SECURITY.md SEC-AUTHZ-11 (threat T-029). `[OPEN: small-team exception path — SECURITY.md SQ-27]`
- FR-28: Findings, evidence, imported artefacts, and generated reports are governed by a per-customer retention schedule tied to the engagement lifecycle, after which they are disposed of. Authorized users can see an engagement's retention state and upcoming disposal. Enforcement: SECURITY.md SEC-DATA-7 (threat T-021). `[OPEN: concrete retention periods — SECURITY.md SQ-25]`
- FR-29: Imported artefacts and any findings auto-generated from them are attributed to the importing user, scoped to exactly one pentest, and enter the workflow at `Draft` — an import never creates content in a review or accepted state, and never on behalf of another user. Enforcement: SECURITY.md SEC-TRUST-5 (threats T-017, T-031).
- FR-30: Recovery of a lost authenticator is performed as an admin-assisted re-enrollment (SECURITY.md SQ-13) that requires two authorized approvers, notifies the account owner out of band, and ends the account's existing sessions. Enforcement: SECURITY.md SEC-AUTHN-5 (threat T-001).
- FR-31: Engagement credential retrieval records the requesting user, engagement, and stated purpose, and credentials are rotated or revoked when the engagement closes or an assigned pentester's access is removed. Enforcement: SECURITY.md SEC-SECRETS-5 (threat T-019).
- FR-32: Imports and report generation run as tracked asynchronous jobs with visible status, bounded resource limits, and a clear failure reason when a submission exceeds those limits — a large or malformed submission never degrades the rest of the system for other users. Enforcement: SECURITY.md SEC-TRUST-7 (threats T-024, T-025).

## 5. Finding lifecycle (workflow)

```
Draft (Author)
   ↓
Technical Review  ──(optional AI pre-review)──▶
   ↓
Final Review
   ↓
Accepted → included in report
```

- A finding can be sent back a stage with comments at any review step.
- No finding may skip Technical Review. A `Rejected` terminal state is reachable from Technical Review or Final Review (SECURITY.md SQ-9).
- The lifecycle is enforced server-side as a state machine, and an `Accepted` finding is not silently editable — a content change is either refused or returns the finding to review (SECURITY.md SEC-WORKFLOW-1, threat T-006).
- Author, technical reviewer, and final reviewer must be three distinct users (FR-27).

## 6. Access control model (ABAC)

- 6.1 Scope levels, from broad to narrow: **Customer → Department → Pentest → Finding → Finding Field.**
- 6.2 A policy grants (or denies) an action (read/write/review/approve/etc.) based on:
  - **Subject attributes** — the user (role, team, clearance, assigned engagements)
  - **Resource attributes** — the object being accessed (customer, department, pentest status, finding sensitivity/status)
  - **Action** — read, write, comment, review, approve, export, etc.
  - **Context** — e.g. review stage, time-bound engagement access
- 6.3 Access at a broader scope (e.g. a pentest) does not automatically imply access to every field at a narrower scope (e.g. a specific sensitive finding field) — narrower-scope policies can further restrict.
- 6.4 Field-level control exists because some finding fields (e.g. client-sensitive evidence, internal-only remediation cost notes) may need different visibility than the finding as a whole.
- 6.5 ABAC engine: **OPA/Rego** (SECURITY.md SQ-1).

## 7. Data import

- 7.1 v1 import sources: **Burp Suite, OWASP ZAP, Nessus, and Nuclei** (SECURITY.md SQ-5).
- 7.2 Import pipeline: raw file → parser (per tool/format) → normalized artefact records → optional auto-generated findings/notes with timestamps.
- 7.3 Testing artefacts have standardized types (e.g. `access-requirement`, `automated-note`, `scan-result`) so the report engine and UI can render them consistently regardless of source tool.

## 8. Report engine

- 8.1 Reports are generated from structured finding/asset/artefact data plus a template, not authored by hand.
- 8.2 Templates support customer- and team-level branding (logos, styling).
- 8.3 Templates are versioned so a baseline template can be updated without breaking in-flight reports.
- 8.4 Report generation respects ABAC — a given report recipient sees only the customer/department/pentest/finding/field data they're entitled to.
- 8.5 Output formats: **PDF and DOCX** (SECURITY.md SQ-6).
- `[OPEN: Is there an in-app preview before export?]`

## 9. Architecture (constraints, not final design)

- 9.1 API + web application (client/server split).
- 9.2 **RDBMS-driven** — relational database is the system of record for engagements, findings, users, and access-control state. Product: **PostgreSQL** (SECURITY.md SQ-10).
- 9.3 **Cloud KMS / Secrets Manager** integration for engagement credential storage (see §4.5). Provider: **AWS**, single provider (SECURITY.md SQ-4).
- 9.4 Import pipeline must be pluggable/extensible to add new scanner/tool formats over time.
- 9.5 Imports and report generation execute as asynchronous jobs rather than in the request path (FR-32); see ARCHITECTURE.md "Async Job Runner."
- `[OPEN: Deployment model — single-tenant per pentest group, or multi-tenant SaaS? The threat model assumes the stricter multi-tenant reading until decided — SECURITY.md SQ-26]`

## 10. Non-functional requirements

- NFR-1: All customer/finding data must be protected at least to the standard expected of pentest engagement data (this system will itself hold sensitive vulnerability data about clients — it is a high-value target).
- NFR-2: Full audit logging of access and changes to findings, credentials, and ABAC policy, given the sensitivity of the data. The audit trail is append-only and tamper-evident, and not erasable by any application role including Admin (SECURITY.md SEC-LOG-3, threat T-010).
- NFR-3: Credentials are never stored in plaintext at rest or logged.
- NFR-4: Compliance targets: **SOC 2 Type II, GDPR, and ISO 27001** (SECURITY.md SQ-8). Concrete data-residency region and control-evidence cadence remain open (SECURITY.md SQ-17, SQ-18).

## 11. Out of scope (for now)

- Billing/invoicing
- Scheduling/calendaring beyond basic engagement start/end dates

## 12. Open questions

A running list, also inlined above as `[OPEN]` markers:

1. What exactly does the AI review pass check beyond being advisory-only (§4.3, FR-11; mode resolved by SECURITY.md SQ-2)?
2. Is there an in-app report preview before export (§8)?
3. Single-tenant vs. multi-tenant deployment model (§9; SECURITY.md SQ-26)?
4. Concrete retention periods for findings, evidence, artefacts, and reports (§4.8, FR-28; SECURITY.md SQ-25)?
5. Is a separation-of-duties exception permitted on small engagements where no second reviewer exists (§4.8, FR-27; SECURITY.md SQ-27)?
6. Are generated reports delivered inside the system (portal retrieval under live authorization) or exported out of it (§8; SECURITY.md SQ-31)?

---

*Changes to this document should be made deliberately — it drives architecture and implementation decisions. When a requirement changes, update it here first.*
