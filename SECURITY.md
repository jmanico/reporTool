# Security

This document is the **source of truth** for reporTool's security posture: threat model status, security requirements, controls, and trust-boundary enforcement. It does not restate *what* the system does (`REQUIREMENTS.md`), *how it is built* (`ARCHITECTURE.md`), or *how it looks/behaves in the UI* (`DESIGN.md`) — it defines the security rules those documents must be built and verified against.

No implementation exists yet. Nothing below infers a framework, auth mechanism, database, provider, CI/CD system, or regulatory obligation the input documents don't name.

**Markers used throughout:**
- `UNKNOWN` — a fact the input documents do not provide.
- `TO BE DECIDED` — a decision not yet made.
- `ASSUMPTION` — an inference this document makes that is not explicitly stated in an input source. Never treat an `ASSUMPTION` as final.

Security notes supplied alongside this task add constraints but never silently override `REQUIREMENTS.md` or `ARCHITECTURE.md`; material conflicts are recorded under **Open Security Questions** and **Decisions Requiring Requirements/Architecture Sync** below.

---

## Resolved Security Decisions (2026-09-21)

The stakeholder decisions below resolve the open questions raised in the previous revision of this document. They are recorded here as the authoritative security-posture decisions.

| ID | Question | Decision |
|---|---|---|
| SQ-1 | ABAC engine/policy model | **OPA / Rego** |
| SQ-2 | AI Review Assist mode | **Advisory only, first-party/in-house model** — non-authoritative, cannot block or bypass ABAC/lifecycle |
| SQ-3 | AAL3 step-up scope | **Per sensitive action** (not login-only) |
| SQ-4 | Cloud provider | **AWS**, single provider |
| SQ-5 | v1 scanner imports | **Burp Suite, OWASP ZAP, Nessus, and Nuclei — all four in v1** |
| SQ-6 | Report output format(s) | **PDF and DOCX** |
| SQ-7 | Customer/Client portal | **In scope for v1**, read-only |
| SQ-8 | Compliance/data-residency targets | **SOC 2 Type II, GDPR, and ISO 27001** |
| SQ-9 | Review workflow skip / rejected state | **No skip of Technical Review; add a `Rejected` terminal state** reachable from Technical or Final Review |
| SQ-10 | RDBMS product / hosting | **PostgreSQL**, hosted on AWS (e.g. RDS for PostgreSQL) |
| SQ-11 | IaC tool | **Terraform confirmed** (resolves the "teraformn" typo) |
| SQ-12 | Assurance target / threat-model method | **OWASP ASVS Level 2**, with a **STRIDE** threat model produced/updated at design time for each major architectural change |
| SQ-13 | Passkey/authenticator recovery | **Admin-assisted re-enrollment** after out-of-band identity verification; users are additionally encouraged (not yet mandated) to register a second authenticator at onboarding so single-device loss isn't a lockout |

These decisions are reflected in the **Required Security Inputs**, **Provisional Security Rules**, and **Prompt Placeholders** sections below. New follow-on questions each decision raises are carried into **Open Security Questions**. Five of these decisions (customer portal in scope, `Rejected` terminal state, v1 scanner scope, report output formats, Gin/Go version) extended facts stated in `REQUIREMENTS.md`/`ARCHITECTURE.md` rather than merely resolving a gap already marked open there; both documents have been synced to match as of 2026-09-21.

---

## Required Security Inputs

| Field | Value |
|---|---|
| Requirements source | REQUIREMENTS.md |
| Design source | DESIGN.md |
| Architecture source | ARCHITECTURE.md |
| System purpose | A platform for a pentest group to run and report on security testing engagements — standardized finding capture/review/CWE-ASVS mapping, multi-customer engagement tracking, structured report generation, fine-grained access control, and safe engagement credential management (REQUIREMENTS.md §1). |
| Application profile | Web application, API monolith. Server: Go **1.27** baseline, Gin **v1.12.0** (per the Gin 1.12 Secure Coding Prompt supplied 2026-09-21 — see `REF-GIN-112`; this pins a version ARCHITECTURE.md leaves open, see "Decisions Requiring Requirements/Architecture Sync"). Client: React SPA (version `UNKNOWN`). API style: REST/JSON. Data store: **PostgreSQL**, normalized to 3NF (SQ-10). |
| Users / actors / roles | Pentester (Author), Technical Reviewer, Final Reviewer, Engagement/Project Manager, Admin, and a read-only Customer/Client portal actor (REQUIREMENTS.md §2, SQ-7); its authentication assurance level is open (SQ-14). |
| Public interfaces and trust boundaries | Browser Client (React SPA, internal actors) and a read-only Customer/Client portal surface (new, SQ-7) are both untrusted and hold no authoritative access-control or business-rule logic. The Server-side API (Go/Gin) is the edge boundary: TLS terminus, DPoP validation, sole ABAC enforcement point. Uploaded scanner/tool export files (now Burp Suite, ZAP, Nessus, Nuclei — SQ-5) and uploaded report templates (DOCX/PDF baselines, FR-23) are untrusted input. The AWS KMS/Secrets Manager boundary is external and reached only by the API. |
| Sensitive or regulated data | Live vulnerability data about pentest clients across the full domain hierarchy (customer, department, pentest, finding, finding field, discovered asset, imported artefact) — a high-value target (REQUIREMENTS.md §1, NFR-1). Some finding fields carry client-sensitive evidence or internal-only remediation-cost notes requiring finer-grained visibility (REQUIREMENTS.md §3.5, §6.4). Engagement credentials (VPN, scoped test accounts, API keys) (REQUIREMENTS.md §4.5). Under GDPR scope (SQ-8), finding/asset data that identifies or relates to an individual is personal data. |
| External integrations | **AWS KMS + AWS Secrets Manager** (SQ-4/SQ-10). Scanner/tool exports: **Burp Suite, OWASP ZAP, Nessus, and Nuclei, all in v1** (SQ-5). AI Review Assist: **advisory-only, first-party/in-house model** (SQ-2). |
| Authentication model | WebAuthn passkey is the minimum authenticator for registration and login; YubiKey and smart card (PIV) are supported additional/alternative authenticators. Target assurance level: NIST SP 800-63B-4 AAL3, authentication only. **Step-up re-authentication is required per sensitive action, not only at login (SQ-3).** Assurance level for the new Customer/Client portal actor is `TO BE DECIDED` (SQ-14). |
| Authorization model | ABAC scoped at every level of Customer → Department → Pentest → Finding → Finding Field (REQUIREMENTS.md §6). **Policy engine: OPA / Rego (SQ-1).** Broader-scope access does not imply narrower-scope access. |
| Session model | Sender-constrained sessions using DPoP-bound JWTs. Token/session lifetime and revocation model remain `TO BE DECIDED` in concrete values (SQ-15); step-up-per-action is now required (SQ-3). |
| Deployment and CI/CD model | **Terraform-managed infrastructure-as-code, confirmed (SQ-11).** **Cloud provider: AWS (SQ-4).** CI/CD platform (e.g. GitHub Actions vs. another system) remains `UNKNOWN` (SQ-16). The architecture note "cloud model enterprise license (review)" remains `UNKNOWN` and still flagged for human review. |
| Applicable privacy or regulatory obligations | **SOC 2 Type II, GDPR, and ISO 27001 (SQ-8).** Concrete data-residency region, GDPR lawful-basis/data-subject-rights implementation, and SOC 2/ISO 27001 control-evidence cadence remain `TO BE DECIDED` (SQ-17, SQ-18). |
| Security assurance target | **OWASP ASVS Level 2 (SQ-12).** |
| Security verification reference | OWASP ASVS 5.0.0, Level 2 |
| Threat model status | **Complete for the documented design (first pass, 2026-09-21).** Methodology: STRIDE per element, with a LINDDUN privacy pass over personal data in findings/evidence (SQ-12). The model is recorded in **Threat Model (STRIDE, 2026-09-21)** below as threats `T-001`–`T-034`. It covers the documented system only — no implementation exists. It MUST be re-run for each major architectural change, including any change to a trust boundary, before that change is implemented; cadence beyond that remains open (SQ-23). |

---

## Threat Model (STRIDE, 2026-09-21)

**Scope.** The documented system as specified in `REQUIREMENTS.md`, `ARCHITECTURE.md`, and `DESIGN.md` at this revision. No implementation exists, so every threat below is derived from documented elements, flows, and boundaries — not from observed code. Nothing here asserts that a vulnerability is present; each entry states what the design must defend against and which rule discharges it.

**Method.** STRIDE applied per element and per flow across the elements `ARCHITECTURE.md` defines (Browser Client, Customer/Client Portal, Server-side API, Identity & Session Handling, ABAC decision point, Data Persistence, Secrets/KMS boundary, Import Pipeline, Report Engine, AI Review Assist, deployment/CI-CD), plus a LINDDUN-oriented pass over personal data that findings, evidence, and discovered assets may contain under GDPR scope (SQ-8). Threat IDs are stable; do not renumber them. Where a threat cannot be closed without a pending decision, it is tied to an `SQ-*` entry under **Open Security Questions**.

**Assumptions and gaps carried into the model.** Deployment tenancy (single-tenant vs. multi-tenant SaaS) is unresolved (`REQUIREMENTS.md` §12) — threats T-003, T-017 and T-023 are rated against the stricter multi-tenant reading. CI/CD platform (SQ-16), token lifetimes (SQ-15), portal assurance level (SQ-14), OPA deployment topology (SQ-20), and the Go-language baseline prompt (SQ-24) are `UNKNOWN`; threats depending on them are marked and carry an open question rather than an invented control.

**Risk method.** Severity below is a qualitative design-time rating (High / Medium / Low) reflecting impact on the system's core asset — live client vulnerability data and engagement credentials (NFR-1) — combined with plausibility given the documented design. It is not CVSS and is not a residual-risk claim; no control effectiveness has been verified because nothing is built.

| ID | STRIDE | Element / flow | Threat | Severity | Disposition |
|---|---|---|---|---|---|
| T-001 | Spoofing | Identity & Session | Abuse of admin-assisted authenticator re-enrollment (SQ-13) to bind an attacker's authenticator to a victim account — the weakest path to an AAL3 account | High | SEC-AUTHN-5, REQUIREMENTS.md FR-30 |
| T-002 | Spoofing | Identity & Session | DPoP proof replay, or use of an exfiltrated DPoP private key, to reuse a captured session | High | SEC-SESSION-3 (SQ-15 for lifetimes) |
| T-003 | Spoofing | Customer/Client Portal | A portal user is bound to the wrong customer, or rebinds itself, gaining another customer's engagement data | High | SEC-AUTHZ-7 |
| T-004 | Spoofing | Identity & Session | WebAuthn RP ID / origin / challenge validation weakness enabling a proxy-phishing or cross-origin ceremony | High | SEC-AUTHN-6 |
| T-005 | Tampering | ABAC decision point | Rego policy or policy bundle altered in transit, at rest, or in a running environment, silently widening access | High | SEC-AUTHZ-8 (topology: SQ-20) |
| T-006 | Tampering | API / finding lifecycle | Direct API call drives a finding Draft → Accepted, skipping Technical Review, or edits a finding after Final Review without re-review | High | SEC-WORKFLOW-1 |
| T-007 | Tampering | Import Pipeline | Malicious scanner export: XXE/entity expansion in XML formats (Burp, ZAP, `.nessus`), archive path traversal ("zip slip"), decompression bomb, or nested-archive abuse | High | SEC-TRUST-4, SEC-TRUST-7 |
| T-008 | Tampering | Report Engine | Uploaded DOCX/PDF template carries active content beyond macros — external/remote template references, DDE fields, embedded objects, OOXML XXE | High | SEC-OUTPUT-3 (ownership: SQ-21) |
| T-009 | Tampering | Report Engine | Formula/field injection: scanner- or client-supplied finding text interpreted as a formula or field code by the consuming office application when the report is opened | Medium | SEC-OUTPUT-4 |
| T-010 | Tampering | Audit log | An operator or compromised admin deletes or edits audit entries to conceal access to findings or credentials | High | SEC-LOG-3, ARCHITECTURE.md Audit Log Store |
| T-011 | Tampering | Deployment / IaC | Terraform change or state manipulation grants the API role broader KMS/Secrets/database access than the design intends | High | SEC-DEPLOY-3 (platform: SQ-16) |
| T-012 | Tampering | AI Review Assist | Prompt injection carried in finding text or imported artefact content manipulates the advisory pass, or induces it to emit attacker-chosen content into the review record | Medium | SEC-INTEG-3 |
| T-013 | Repudiation | Review workflow | A reviewer denies having approved a finding; approval is not bound to a specific fresh authentication event | Medium | SEC-LOG-4 |
| T-014 | Repudiation | Report Engine | Dispute over what a delivered client report contained, who generated it, and under whose ABAC scope, with no record of the generated artifact's content set | Medium | SEC-LOG-5, REQUIREMENTS.md FR-26 |
| T-015 | Information disclosure | API read paths | Field-level ABAC enforced on single-object reads but bypassed via list, search, filter, sort, aggregate, or error-message side channels (over-fetch then filter in the client) | High | SEC-DATA-4 (extends SEC-DATA-1) |
| T-016 | Information disclosure | Report Engine / artifact storage | A generated PDF/DOCX is retrievable by URL possession alone, or persists past the recipient's entitlement, leaking a full engagement report | High | SEC-DATA-5, ARCHITECTURE.md Report Artifact Store |
| T-017 | Information disclosure | Import Pipeline / AI pass | Cross-engagement or cross-customer bleed — an artefact is attached to the wrong pentest, or several customers' findings are processed in one AI batch | High | SEC-TRUST-5 |
| T-018 | Information disclosure | Import Pipeline / Report Engine | SSRF: a parser or template renderer dereferences a URL from untrusted input, reaching the AWS instance metadata service or an internal address | High | SEC-TRUST-6 |
| T-019 | Information disclosure | Secrets / KMS boundary | Engagement credentials over-retrieved and retained — broad KMS decrypt rights, no per-retrieval justification, no rotation when the engagement ends | High | SEC-SECRETS-5, REQUIREMENTS.md FR-31 |
| T-020 | Information disclosure | Data Persistence | Database backups, snapshots, or read replicas expose client vulnerability data outside the controls applied to the primary store | High | SEC-DATA-6 (region: SQ-17) |
| T-021 | Information disclosure (LINDDUN: identifiability, retention) | Findings / evidence | Personal data inside evidence (screenshots, request/response captures, account identifiers) is retained indefinitely beyond engagement need under GDPR scope | Medium | SEC-DATA-7, REQUIREMENTS.md FR-28 (mechanism: SQ-19) |
| T-022 | Information disclosure (LINDDUN: linkability) | Customer/Client Portal | Sequential or guessable identifiers, or differing not-found vs. forbidden responses, let a portal user infer the existence and volume of other customers' engagements | Medium | SEC-AUTHZ-9 |
| T-023 | Information disclosure | Browser Client | XSS or a compromised frontend dependency exfiltrates session material or renders attacker content inside an authenticated surface | High | SEC-OUTPUT-5 (complements SEC-OUTPUT-1) |
| T-024 | Denial of service | Import Pipeline | A large or adversarial export exhausts memory/CPU/disk in the request path, degrading imports and unrelated API traffic | Medium | SEC-TRUST-7, ARCHITECTURE.md Async Job Runner, REQUIREMENTS.md FR-32 |
| T-025 | Denial of service | Report Engine | Report generation for a large engagement blocks request-handling capacity or exhausts artifact storage | Medium | SEC-TRUST-7, ARCHITECTURE.md Async Job Runner, REQUIREMENTS.md FR-32 |
| T-026 | Denial of service | ABAC decision point | The OPA decision point is unreachable; fail-closed (correctly) denies all access, so availability of the decision path is itself a security-relevant property | Medium | SEC-AUTHZ-10 (topology: SQ-20) |
| T-027 | Denial of service / Spoofing | API edge | No rate limiting or lockout on authentication, step-up, import, or report endpoints — enabling resource abuse and ceremony-flooding against users | Medium | SEC-HTTP-4 (reinforces SEC-GIN-1) |
| T-028 | Denial of service | Secrets / KMS boundary | KMS/Secrets Manager throttling or outage blocks credential retrieval mid-engagement, creating pressure to keep out-of-band plaintext copies | Medium | SEC-SECRETS-6 |
| T-029 | Elevation of privilege | Review workflow | An author technically- or finally-reviews their own finding, or grants themselves reviewer rights, collapsing the two-stage review into one actor | High | SEC-AUTHZ-11, REQUIREMENTS.md FR-27 |
| T-030 | Elevation of privilege | Admin role | An Admin silently widens ABAC policy or reads all client findings; the role that governs access also governs the evidence of its own use | High | SEC-AUTHZ-12, SEC-LOG-3 |
| T-031 | Elevation of privilege | Import Pipeline | Auto-generated findings/artefacts enter the system outside the importing actor's ABAC scope, or pre-authored into a later lifecycle state | Medium | SEC-TRUST-5, REQUIREMENTS.md FR-29 |
| T-032 | Elevation of privilege | Data Persistence | SQL injection via finding text, search filters, or normalized artefact content reaching PostgreSQL | High | SEC-INPUT-2 |
| T-033 | Elevation of privilege | Deployment / supply chain | A compromised Go, npm, or Terraform dependency executes inside the API or build pipeline, reaching data and credentials directly | High | DEP-1–DEP-8, SEC-DEPLOY-3 (Go baseline: SQ-24) |
| T-034 | Repudiation / Tampering | Customer/Client Portal | Portal reads are not audited to the same standard as internal reads, so client-side access to findings cannot be reconstructed | Low | SEC-LOG-1 (already CONFIRMED — no new rule required) |

**Coverage notes.** Every STRIDE category produced at least one threat for the API, Identity/Session, Import Pipeline, Report Engine, and Customer/Client Portal elements. The Browser Client produced no Repudiation threat of its own — it holds no authoritative state (DR-1), so repudiation is modelled at the API and audit log. T-034 required no new rule; the existing SEC-LOG-1 already covers it and is recorded here only for traceability.

---

## Selected Security References and Prompt Imports

No local secure-coding prompt library was found in this execution environment (checked common locations under the user's home directory and Claude Code configuration paths; nothing matching a project-scoped prompt library was present). The authoritative public references below were selected and read, filtered to the confirmed stack (Go/Gin REST API, React SPA, PostgreSQL/3NF, WebAuthn passkey + DPoP-bound sessions, Terraform on AWS, OPA/Rego ABAC).

| ID | Title / Version | URL |
|---|---|---|
| `REF-ASVS-5` | OWASP Application Security Verification Standard 5.0.0 | https://github.com/OWASP/ASVS/releases/tag/v5.0.0_release |
| `REF-PC-2024` | OWASP Top 10 Proactive Controls 2024 | https://top10proactive.owasp.org/archive/2024/the-top-10/ |
| `REF-API-2023` | OWASP API Security Top 10 2023 | https://owasp.org/API-Security/editions/2023/en/0x11-t10/ |
| `REF-REST` | OWASP REST Security Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html |
| `REF-AUTH` | OWASP Authentication Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html |
| `REF-SESSION` | OWASP Session Management Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html |
| `REF-XSS` | OWASP Cross Site Scripting Prevention Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html |
| `REF-INPUTVAL` | OWASP Input Validation Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html |
| `REF-SECRETS` | OWASP Secrets Management Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html |
| `REF-LOGGING` | OWASP Logging Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html |
| `REF-ERROR` | OWASP Error Handling Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html |
| `REF-SSDF` | NIST SP 800-218 (SSDF) 1.1 | https://csrc.nist.gov/pubs/sp/800/218/final |
| `REF-CICD` | OWASP CI/CD Security Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html |
| `REF-SUPPLYCHAIN` | OWASP Software Supply Chain Security Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/Software_Supply_Chain_Security_Cheat_Sheet.html |
| `REF-IAC` | OWASP Infrastructure as Code Security Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/Infrastructure_as_Code_Security_Cheat_Sheet.html |
| `REF-DEPMGMT` | OWASP Vulnerable Dependency Management Cheat Sheet | https://cheatsheetseries.owasp.org/cheatsheets/Vulnerable_Dependency_Management_Cheat_Sheet.html |
| `REF-63B` | NIST SP 800-63B-4 (Authentication and Authenticator Management) | https://pages.nist.gov/800-63-4/sp800-63b.html |
| `REF-FIDO` | FIDO Alliance — Passkeys | https://fidoalliance.org/passkeys/ |
| `REF-WEBAUTHN` | W3C Web Authentication (WebAuthn) | https://www.w3.org/TR/webauthn/ |
| `REF-AWS-WA-SEC` | AWS Well-Architected Framework — Security Pillar | https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html |
| `REF-AWS-KMS` | AWS KMS Best Practices | https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html |
| `REF-AWS-SECRETS` | AWS Secrets Manager Best Practices | https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html |
| `REF-GIN-112` | "Gin 1.12 Secure Coding Prompt" — an overlay for `github.com/gin-gonic/gin` v1.12.0 on a Go 1.27 baseline | User-supplied in this session, 2026-09-21; no external URL. Full text was read and is synthesized into `SEC-GIN-*` below, not copied verbatim. |
| `REF-GO-127` | Go 1.27 secure-coding baseline prompt (referenced by `REF-GIN-112` as a prerequisite: "Apply the resolved Go 1.27 prompt first") | **Not supplied in this session** — `UNKNOWN` content. See SQ-24. |

`REF-FIDO` and `REF-WEBAUTHN` are included because passkeys are explicitly selected as the minimum authenticator. `REF-AWS-*` are included now that AWS is the confirmed cloud provider (SQ-4/SQ-10). No ABAC-engine-specific cheat sheet exists in the selected library; OPA/Rego policy design guidance is sourced from `REF-ASVS-5`'s access-control chapter and `REF-API-2023`, kept general rather than citing OPA's own (non-OWASP/NIST) documentation as a security-authoritative source. `REF-GIN-112` was provided directly by the user as pasted text rather than a local file path or URL — its exact content is retained in this session's history; it is cited here by name/date per the Reference Accuracy Rules since no path/URL exists for it.

---

## Provisional Security Rules

### Trust boundaries and server-side enforcement

- **SEC-TRUST-1** The Server-side API MUST be the sole enforcement point for authentication, authorization, and business-rule decisions. No client surface — the internal Browser Client or the new Customer/Client portal (SQ-7) — MUST be relied upon to enforce access control or hide unauthorized data/actions.
  - **Applies to:** All REST endpoints
  - **Verification:** Automated tests calling API endpoints directly (bypassing any client) with under-privileged and over-privileged identities, confirming enforcement holds
  - **References:** `REF-ASVS-5`, `REF-API-2023`
  - **Status:** CONFIRMED

- **SEC-TRUST-2** Uploaded scanner/tool export files (Burp Suite, OWASP ZAP, Nessus, Nuclei — SQ-5) and uploaded report templates (FR-23) MUST be treated as untrusted input, parsed only by a dedicated per-format parser, and MUST NOT be executed or interpreted as code at any stage.
  - **Applies to:** Import Pipeline, Report Engine template ingestion
  - **Verification:** A malformed/adversarial-file test corpus per supported format; confirm parser failure rejects rather than executes or passes through unparsed content
  - **References:** `REF-INPUTVAL`, `REF-ASVS-5`
  - **Status:** CONFIRMED

- **SEC-TRUST-3** Each scanner/tool import format (now four in v1: Burp Suite, ZAP, Nessus, Nuclei) MUST have its own isolated parser module. A parsing failure, malformed input, or vulnerability in one format's parser MUST NOT affect the availability or correctness of another format's parser or of unrelated pentests' data.
  - **Applies to:** Import Pipeline
  - **Verification:** Fault-injection test — a crafted malformed file for one parser must not affect a concurrent import using a different parser
  - **References:** `REF-INPUTVAL`, `REF-ASVS-5`
  - **Status:** CONFIRMED — new rule required by the v1 scanner-scope decision (SQ-5)

- **SEC-TRUST-4** Every parser that processes a structured import format MUST disable external entity resolution, DTD processing, and entity expansion, and MUST NOT dereference any URI, schema location, or file reference contained in the input. Archive-bearing formats MUST validate each entry's resolved destination path stays within a generated extraction root, and MUST reject absolute paths, parent-directory traversal, symbolic and hard links, and nested archives beyond a declared depth.
  - **Applies to:** Import Pipeline (Burp Suite, OWASP ZAP, Nessus, Nuclei), Report Engine template ingestion
  - **Verification:** Per-format adversarial corpus containing an external-entity document, an entity-expansion document, an archive entry escaping the extraction root, a symlink entry, and a nested archive — each MUST be rejected without file write outside the root and without any outbound network request
  - **References:** `REF-INPUTVAL`, `REF-ASVS-5`
  - **Status:** CONFIRMED — T-007, T-008

- **SEC-TRUST-5** Imported artefacts and any findings or notes auto-generated from them MUST be bound at creation to exactly one pentest, and MUST be created under the ABAC scope of the actor who performed the import — never under a service or elevated identity. Auto-generated findings MUST enter the lifecycle at `Draft` and MUST NOT be created in, or advanced to, any review or accepted state by the import itself. Processing MUST NOT batch, join, or cache data from more than one customer in a single unit of work, and this constraint applies identically to the AI Review Assist pass (SEC-INTEG-1).
  - **Applies to:** Import Pipeline, AI Review Assist, Server-side API
  - **Verification:** Test that an import performed by an actor without write scope on the target pentest is denied; that auto-generated findings are authored-by and scoped-to the importing actor and land in `Draft`; that no processing unit spans two customers
  - **References:** `REF-ASVS-5`, `REF-API-2023`
  - **Status:** CONFIRMED — T-017, T-031

- **SEC-TRUST-6** Import parsing and report generation MUST NOT make outbound network requests. The execution context for both MUST have egress denied by default, MUST have no route to the cloud instance metadata service, and where an instance metadata service is reachable at all it MUST require session-oriented (IMDSv2-style) access. Any future requirement for an outbound fetch MUST be introduced as an explicit allow-list entry with a recorded decision, not as a parser or renderer capability.
  - **Applies to:** Import Pipeline, Report Engine, deployment configuration
  - **Verification:** Egress test asserting a crafted input referencing an external host and an internal/metadata address produces no outbound connection; infrastructure test asserting the deny-by-default egress policy is present
  - **References:** `REF-AWS-WA-SEC`, `REF-INPUTVAL`, `REF-IAC`
  - **Status:** CONFIRMED — T-018

- **SEC-TRUST-7** Untrusted-input processing MUST be resource-bounded: an explicit maximum accepted upload size, a maximum decompressed/expanded size and ratio, a maximum element/record count, a wall-clock timeout, and a memory bound, each enforced before or during parsing rather than after. Exceeding a bound MUST abort that job with a non-revealing error and MUST NOT degrade concurrent imports, report generation, or unrelated API traffic. The same bounds apply to report generation over large engagements.
  - **Applies to:** Import Pipeline, Report Engine, Async Job Runner
  - **Verification:** Load/fault test with an oversized export, a high-ratio compressed file, and a high-element-count document, asserting rejection and asserting unrelated concurrent requests stay within normal service
  - **References:** `REF-INPUTVAL`, `REF-ASVS-5`
  - **Status:** CONFIRMED — T-007, T-024, T-025

### Authentication

- **SEC-AUTHN-1** The system MUST require a WebAuthn passkey ceremony as the minimum authenticator factor for registration and login for internal actors (Pentester, Technical/Final Reviewer, PM, Admin); YubiKey and smart-card (PIV) MAY be offered as additional/alternative authenticators.
  - **References:** `REF-WEBAUTHN`, `REF-FIDO`, `REF-AUTH`
  - **Status:** CONFIRMED

- **SEC-AUTHN-2** The authentication implementation MUST target NIST SP 800-63B-4 AAL3 (authentication only; no identity-proofing/IAL claim) for all internal actors.
  - **References:** `REF-63B`, `REF-WEBAUTHN`
  - **Status:** CONFIRMED

- **SEC-AUTHN-3** The API MUST require a fresh authentication ceremony (step-up) immediately before performing a sensitive operation, at minimum: engagement credential retrieval, ABAC policy changes, and Final Review approval — an existing valid session alone is not sufficient for these actions (SQ-3).
  - **Applies to:** Server-side API, sensitive state-changing endpoints
  - **Verification:** Attempt each listed sensitive action using a valid session that has not freshly re-authenticated; confirm the API demands a new ceremony
  - **References:** `REF-AUTH`, `REF-63B`
  - **Status:** CONFIRMED (was provisional; now a stakeholder decision, SQ-3)

- **SEC-AUTHN-4** The authentication assurance level required for the Customer/Client portal actor (SQ-7) is `TO BE DECIDED` — whether the same AAL3 passkey requirement applies to external customer users, or a different/lower bar is acceptable given they are read-only. Until decided, the provisional default is to apply the same AAL3 passkey requirement as internal actors — no external actor may be authenticated to a lower assurance level by default.
  - **References:** `REF-63B`, `REF-WEBAUTHN`
  - **Status:** TO BE DECIDED (SQ-14) — new rule required by bringing the client portal into v1 scope

- **SEC-AUTHN-5** Admin-assisted authenticator re-enrollment (SQ-13) MUST require out-of-band identity verification, MUST require authorization by two distinct authorized actors (the requesting user's account MUST NOT be recoverable by a single administrator acting alone), MUST be audit-logged as a security-significant event with both approvers recorded, and MUST notify the account owner through a channel not controlled by the re-enrollment flow. A re-enrollment MUST invalidate all existing sessions for that account.
  - **Applies to:** Identity & Session Handling
  - **Verification:** Test that a single-approver re-enrollment attempt is refused; that a completed re-enrollment invalidates prior sessions; that both approvers and the notification appear in the audit log
  - **References:** `REF-63B`, `REF-AUTH`
  - **Status:** CONFIRMED — T-001; implements REQUIREMENTS.md FR-30

- **SEC-AUTHN-6** Every WebAuthn ceremony MUST validate the relying-party identifier, the client-data origin against an exact allow-list of the system's own origins, the type field, and a server-generated single-use challenge, and MUST enforce the authenticator signature counter or an equivalent cloning signal where the authenticator provides one. Ceremony parameters MUST NOT be accepted from the client.
  - **Applies to:** Identity & Session Handling
  - **Verification:** Negative tests presenting a mismatched origin, a mismatched RP ID, a replayed challenge, and a regressed signature counter — each MUST be rejected
  - **References:** `REF-WEBAUTHN`, `REF-FIDO`, `REF-63B`
  - **Status:** CONFIRMED — T-004

### Session management

- **SEC-SESSION-1** Sessions MUST be sender-constrained using DPoP-bound JWTs. The API MUST reject any bearer token presented without a valid DPoP proof bound to the same key and matching HTTP method/URI.
  - **References:** `REF-SESSION`, `REF-AUTH`
  - **Status:** CONFIRMED

- **SEC-SESSION-2** Concrete session/access-token lifetime and revocation-mechanism values are `TO BE DECIDED` (SQ-15). Until decided, the provisional default is short-lived access tokens with a server-side revocation capability; long-lived, unrevocable bearer tokens MUST NOT be issued. Step-up per SEC-AUTHN-3 applies regardless of the chosen token lifetime.
  - **References:** `REF-SESSION`
  - **Status:** TO BE DECIDED (SQ-15)

- **SEC-SESSION-3** The API MUST reject replayed DPoP proofs: each proof MUST carry a unique identifier tracked server-side for at least the accepted proof-freshness window, MUST fall within a bounded issued-at window, and MUST be bound to the access token in use in addition to the method and URI already required by SEC-HTTP-2. The client-side DPoP key MUST be generated as non-extractable so that a scripting compromise of the browser surface cannot export it (see SEC-OUTPUT-5). Concrete window values follow from SQ-15.
  - **Applies to:** Identity & Session Handling, Browser Client, Customer/Client portal
  - **Verification:** Replay a previously accepted proof, an out-of-window proof, and a proof bound to a different token — each MUST be rejected; assert the client key is created non-extractable
  - **References:** `REF-SESSION`, `REF-AUTH`
  - **Status:** CONFIRMED — T-002 (values pending SQ-15)

### Authorization (ABAC)

- **SEC-AUTHZ-1** The Server-side API MUST verify, for every request, that the authenticated actor is authorized for the requested action against the specific customer, department, pentest, finding, and finding field targeted, before performing the operation or returning data. Default MUST be deny. This applies identically to requests originating from the internal Browser Client and from the Customer/Client portal.
  - **Applies to:** All reads/writes across the domain hierarchy
  - **Verification:** Automated ABAC test suite exercising permitted and prohibited subject/resource/action/context combinations at each scope level, including field-level denial, and including the read-only customer actor
  - **References:** `REF-ASVS-5`, `REF-API-2023`
  - **Status:** CONFIRMED

- **SEC-AUTHZ-2** A grant of access at a broader scope MUST NOT be interpreted as implying access to a narrower-scope resource that a narrower-scope policy further restricts.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED

- **SEC-AUTHZ-3** Granting reviewer rights (technical or final) on a pentest or finding MUST itself be an authorized, audited action — only actors already holding assignment rights may grant them to others.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED

- **SEC-AUTHZ-4** ABAC policy decisions MUST be evaluated using **OPA/Rego** (SQ-1) as the single, server-side ABAC decision point reachable only from within the Server-side API. Rego policies MUST be version-controlled, MUST have automated tests covering allow/deny for every scope level, and MUST NOT be edited directly in a running environment outside that pipeline.
  - **Verification:** CI check that every Rego policy change ships with a corresponding test change; deployment pipeline rejects untested policy changes
  - **References:** `REF-ASVS-5`, `REF-CICD`
  - **Status:** CONFIRMED (SQ-1)

- **SEC-AUTHZ-5** The Report Engine MUST invoke the same OPA/Rego decision point used for interactive reads, evaluated per finding/field for the specific recipient, when generating a report in either PDF or DOCX form — it MUST NOT reimplement authorization logic, and MUST NOT apply a looser check for the Customer/Client portal's own-data reports than for internal recipients.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED

- **SEC-AUTHZ-6** The Customer/Client portal actor MUST be restricted to read-only operations and MUST be scoped to only their own customer's data. It MUST NOT be granted write, review, or credential-access capabilities under any policy, and MUST be denied internal-only finding fields (e.g. remediation-cost notes, §6.4) by default unless a policy explicitly grants that field to that actor class.
  - **Applies to:** Customer/Client portal, OPA/Rego policy set
  - **Verification:** ABAC test asserting no policy combination grants a customer-scoped subject any write action, or access to another customer's data, or access to internal-only fields absent an explicit grant
  - **References:** `REF-ASVS-5`, `REF-API-2023`
  - **Status:** CONFIRMED — new rule required by bringing the client portal into v1 scope (SQ-7)

- **SEC-AUTHZ-7** The binding between an external portal user and the customer whose data they may read MUST be established only by an authorized internal actor, MUST be stored server-side as a resource attribute, and MUST NOT be derivable from anything the portal user supplies (including email domain, request parameter, token claim asserted by the client, or subdomain). Changing that binding MUST be an audited, authorized action subject to SEC-AUTHN-3 step-up.
  - **Applies to:** Customer/Client portal, Server-side API, OPA/Rego policy set
  - **Verification:** Test that no client-supplied value alters the customer scope resolved for a portal session, and that rebinding requires an authorized internal actor plus step-up
  - **References:** `REF-ASVS-5`, `REF-API-2023`
  - **Status:** CONFIRMED — T-003

- **SEC-AUTHZ-8** Rego policy MUST reach a running environment only as an integrity-verified, versioned artifact produced by the deployment pipeline: policy bundles MUST be signed or otherwise integrity-checked at load, the loaded policy version MUST be recorded in the audit log, and a failed integrity check MUST fail closed rather than fall back to a previous or permissive policy. Runtime editing of policy outside the pipeline remains prohibited (SEC-AUTHZ-4).
  - **Applies to:** ABAC Decision (OPA/Rego), deployment pipeline
  - **Verification:** Load a tampered bundle and confirm the decision point refuses to serve decisions; confirm the active policy version appears in audit output
  - **References:** `REF-ASVS-5`, `REF-CICD`, `REF-SUPPLYCHAIN`
  - **Status:** CONFIRMED — T-005 (deployment topology pending SQ-20)

- **SEC-AUTHZ-9** Identifiers exposed across the API surface MUST be non-sequential and non-guessable, and responses MUST NOT let an unauthorized caller distinguish "does not exist" from "exists but is forbidden" — including through status code, response body, error text, or materially different response timing. This applies to every scope level and specifically to the Customer/Client portal.
  - **Applies to:** Server-side API, Customer/Client portal
  - **Verification:** Enumeration test comparing responses for a non-existent resource and a real resource outside the caller's scope; assert indistinguishable responses and non-sequential identifiers
  - **References:** `REF-API-2023`, `REF-REST`, `REF-ASVS-5`
  - **Status:** CONFIRMED — T-022

- **SEC-AUTHZ-10** The ABAC decision point MUST fail closed — an unavailable, erroring, or timed-out decision MUST deny the request and MUST NOT fall back to a cached allow, a default role, or a bypass path. Because a denial of the decision path is therefore a denial of the whole system, the decision point's availability MUST be treated as a security-relevant property with its own monitoring and alerting, and policy evaluation MUST be able to proceed from a locally held, integrity-verified policy copy without a synchronous dependency on a remote policy source at request time.
  - **Applies to:** ABAC Decision (OPA/Rego), Server-side API
  - **Verification:** Fault-injection test making the decision point unavailable and asserting requests are denied rather than allowed; assert an alert fires
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED — T-026 (topology pending SQ-20)

- **SEC-AUTHZ-11** The system MUST enforce separation of duties across the finding lifecycle: the author of a finding MUST NOT perform its Technical Review or its Final Review, and the Technical Reviewer MUST NOT perform the Final Review of the same finding. No actor may grant reviewer rights on a finding or pentest to themselves. These constraints MUST be evaluated at the OPA/Rego decision point, not only in UI affordances.
  - **Applies to:** Server-side API, OPA/Rego policy set
  - **Verification:** ABAC tests asserting each self-review and self-assignment combination is denied at the API regardless of the actor's role
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED — T-029; implements REQUIREMENTS.md FR-27

- **SEC-AUTHZ-12** Administrative authority MUST NOT be silent or unilateral. Changes to ABAC policy, to role/attribute assignments, and to audit-log configuration MUST require two distinct authorized actors, MUST be subject to SEC-AUTHN-3 step-up, and MUST be audit-logged and alerted. An Admin MUST NOT hold standing read access to engagement finding data or credentials by virtue of the Admin role; where emergency access is needed it MUST be an explicit, time-bounded, dual-authorized break-glass grant that is alerted at the time of use and reviewed afterwards.
  - **Applies to:** Server-side API, OPA/Rego policy set, Identity & Session Handling
  - **Verification:** Test that a single-actor policy change is refused; that an Admin without an explicit grant is denied finding and credential reads; that a break-glass grant expires and is alerted
  - **References:** `REF-ASVS-5`, `REF-LOGGING`
  - **Status:** CONFIRMED — T-030

### Finding lifecycle integrity

- **SEC-WORKFLOW-1** The finding lifecycle (REQUIREMENTS.md §5) MUST be enforced server-side as an explicit state machine: only transitions the document defines are permitted, Technical Review MUST NOT be skipped, the target state MUST NOT be settable through a request body field (see SEC-GIN-4), and each transition MUST be authorized for the requesting actor against that specific finding. A finding in `Accepted` MUST NOT be silently mutable — any change to its content MUST either be refused or return it to review, with the choice recorded; an accepted finding already included in a delivered report MUST retain the content set that was delivered (SEC-LOG-5).
  - **Applies to:** Server-side API
  - **Verification:** Tests attempting every undefined transition, a body-supplied status field, a skip of Technical Review, and a post-acceptance edit — each MUST be refused or MUST re-enter review as recorded
  - **References:** `REF-ASVS-5`, `REF-API-2023`
  - **Status:** CONFIRMED — T-006

### HTTP/API boundaries

- **SEC-HTTP-1** All client-server communication MUST occur over TLS. The API MUST NOT accept plaintext HTTP for any authenticated or credential-bearing request.
  - **References:** `REF-REST`, `REF-ASVS-5`
  - **Status:** CONFIRMED

- **SEC-HTTP-2** The API MUST validate that each DPoP proof's HTTP method and URI match the request it accompanies, rejecting mismatches.
  - **References:** `REF-SESSION`, `REF-REST`
  - **Status:** CONFIRMED

- **SEC-HTTP-3** Whether the Customer/Client portal is served from a separate origin from the internal SPA (requiring CORS) is `UNKNOWN`. If required, CORS MUST use an explicit allow-list and MUST NOT combine a wildcard origin with credentialed requests. Until decided, cross-origin requests SHOULD be rejected by default.
  - **References:** `REF-REST`
  - **Status:** TO BE DECIDED

- **SEC-HTTP-4** The API MUST apply rate limiting and abuse controls to authentication and step-up ceremonies, import submission, report generation, and search/list endpoints, keyed on the authenticated subject where one exists and on a coarser network signal otherwise (noting `c.ClientIP()`'s limits per SEC-GIN-5). Repeated failed authentication attempts against an account MUST trigger throttling or lockout with a defined recovery path, and rate-limit responses MUST NOT disclose whether an account exists.
  - **Applies to:** Server-side API
  - **Verification:** Test that repeated authentication failures throttle, that import/report submission is bounded per actor, and that limit responses are identical for existing and non-existing accounts
  - **References:** `REF-AUTH`, `REF-API-2023`, `REF-REST`
  - **Status:** CONFIRMED — T-027; makes explicit the rate-limiting middleware named in SEC-GIN-1

### Input validation

- **SEC-INPUT-1** All data crossing the trust boundary into the Server-side API — REST request bodies, query parameters, and imported artefact files across all four v1 scanner formats — MUST be validated for both format/type and business-rule meaning (e.g., a well-formed CWE identifier, a well-formed ASVS control identifier, an allowed severity value) before being persisted or acted upon.
  - **References:** `REF-INPUTVAL`, `REF-ASVS-5`
  - **Status:** CONFIRMED

- **SEC-INPUT-2** All database access MUST use parameterized statements or an equivalent mechanism that separates query structure from data. Untrusted values MUST NOT be concatenated or interpolated into SQL, including into identifiers, `ORDER BY`/`LIMIT` clauses, and dynamic filter construction on search endpoints; where a sort or filter key must vary, it MUST be selected from a server-side allow-list. This applies equally to values originating from imported scanner output, which is untrusted regardless of having been normalized.
  - **Applies to:** Server-side API, Data Persistence, Import Pipeline
  - **Verification:** Injection test corpus across finding text, search filters, sort parameters, and normalized artefact fields; static check that no SQL is assembled by string concatenation of request-derived values
  - **References:** `REF-INPUTVAL`, `REF-ASVS-5`, `REF-PC-2024`
  - **Status:** CONFIRMED — T-032

### Output encoding and safe rendering

- **SEC-OUTPUT-1** The React SPA and the Customer/Client portal MUST render server-supplied and user-supplied content (finding text, evidence, imported artefact content) using framework-provided safe rendering. Raw HTML/DOM injection interfaces for untrusted content MUST NOT be used.
  - **References:** `REF-XSS`
  - **Status:** CONFIRMED

- **SEC-OUTPUT-2** Uploaded DOCX report templates (FR-23) MUST NOT support embedded macros or other active/executable content, and MUST be validated/sanitized before use in report generation, regardless of the uploader's role.
  - **Applies to:** Report Engine template ingestion
  - **Verification:** Test upload of a DOCX template containing a macro or embedded object and confirm rejection or stripping before the template is accepted
  - **References:** `REF-INPUTVAL`, `REF-ASVS-5`
  - **Status:** CONFIRMED — new rule required by the DOCX output-format decision (SQ-6)

- **SEC-OUTPUT-3** Template validation MUST cover active and externally-resolving content beyond macros: remote/attached template references, field codes that execute or fetch (including DDE-style constructs), embedded and linked OLE objects, external relationship targets, and external entity or schema references in the document's XML parts MUST be rejected or stripped before a template is accepted. Validation MUST be applied on upload and again at generation time, and MUST NOT be skipped for a template uploaded by a privileged role (see SEC-TRUST-4, SEC-TRUST-6).
  - **Applies to:** Report Engine template ingestion and generation
  - **Verification:** Upload corpus containing each named construct; assert rejection or stripping at upload and at generation, with no outbound request made
  - **References:** `REF-INPUTVAL`, `REF-ASVS-5`
  - **Status:** CONFIRMED — T-008 (template ownership pending SQ-21)

- **SEC-OUTPUT-4** Content written into a generated report that a consuming application may interpret as a formula, field code, or command — including finding text, evidence excerpts, asset names, and normalized scanner output — MUST be neutralized for that destination format before it is written. This is an output-encoding obligation of the Report Engine per output format (PDF, DOCX, and any tabular export), not an input-validation restriction on what a pentester may record.
  - **Applies to:** Report Engine
  - **Verification:** Generate a report from findings whose text begins with formula/field-code lead characters and confirm the produced artifact renders them as literal text
  - **References:** `REF-XSS`, `REF-INPUTVAL`
  - **Status:** CONFIRMED — T-009

- **SEC-OUTPUT-5** Both browser surfaces MUST serve a Content Security Policy that forbids inline and `eval`-based script execution and restricts script, style, image, frame-ancestor, form-action, and connect sources to an explicit allow-list, alongside the standard protective response headers. Application and third-party frontend code MUST be served from origins the project controls, with integrity-checked, lockfile-pinned dependencies (DEP-7); untrusted content MUST NOT be rendered into an executable context (SEC-OUTPUT-1). Session key material held by the client MUST be non-extractable (SEC-SESSION-3) so that a scripting compromise cannot export a usable session.
  - **Applies to:** Browser Client, Customer/Client portal, Server-side API response headers
  - **Verification:** Header assertions on every served response; a build check that no frontend asset is loaded from an unpinned third-party origin; an XSS test corpus against finding, evidence, and imported-artefact rendering paths
  - **References:** `REF-XSS`, `REF-ASVS-5`, `REF-SUPPLYCHAIN`
  - **Status:** CONFIRMED — T-023, T-033

### Data protection and privacy

- **SEC-DATA-1** Field-level access restrictions (REQUIREMENTS.md §3.5, §6.4) MUST be enforced by the API on every read path that can expose finding-field data, including list, bulk, search, and export/report endpoints, for both internal actors and the Customer/Client portal.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED

- **SEC-DATA-2** The system targets **SOC 2 Type II, GDPR, and ISO 27001** (SQ-8). Concrete data-residency region, GDPR lawful-basis documentation, and SOC 2/ISO 27001 control-evidence ownership/cadence are `TO BE DECIDED` (SQ-17, SQ-18) — no specific control implementation is claimed as complete by this document.
  - **Status:** PARTIALLY DEFINED (SQ-8 resolved at the "which regimes" level; implementation detail open)

- **SEC-DATA-3** Where finding, asset, or artefact data identifies or relates to an individual (GDPR personal data), the system MUST support data-subject export and deletion requests scoped to that individual's data, consistent with ABAC (i.e., a deletion/export request MUST NOT be actionable by an unauthorized requester). Concrete mechanism is `TO BE DECIDED` (SQ-19).
  - **References:** `REF-ASVS-5`
  - **Status:** TO BE DECIDED (SQ-19) — new rule required by the GDPR decision (SQ-8)

- **SEC-DATA-4** Field-level authorization MUST be applied as a server-side projection — the API MUST NOT retrieve a superset of permitted data and rely on filtering after the fact in a response serializer or in a client. This obligation extends to list, search, filter, sort, count, aggregate, and export paths: a field the caller may not read MUST NOT be usable as a filter or sort key, MUST NOT contribute to a returned count or aggregate, and MUST NOT be inferable from result ordering or from the presence/absence of a record.
  - **Applies to:** Server-side API, Report Engine, Data Persistence access layer
  - **Verification:** ABAC test suite asserting, for a subject denied a specific field, that the field is absent from every read path and that filtering or sorting on it is refused rather than silently applied
  - **References:** `REF-ASVS-5`, `REF-API-2023`
  - **Status:** CONFIRMED — T-015 (extends SEC-DATA-1 to derived and aggregate read paths)

- **SEC-DATA-5** A generated report artifact MUST be authorized on every retrieval against the same OPA/Rego decision point used to generate it (SEC-AUTHZ-5) — possession of a URL, identifier, or link MUST NOT by itself grant access. Artifacts MUST be encrypted at rest, MUST carry a defined retention period after which they are deleted, and MUST record the recipient scope under which they were produced (SEC-LOG-5). Where a time-limited direct download mechanism is used, its links MUST be short-lived, single-recipient, and revocable, and MUST NOT be a substitute for the authorization check.
  - **Applies to:** Report Engine, report artifact storage, Server-side API
  - **Verification:** Retrieve an artifact URL as a non-entitled subject and confirm denial; confirm retention deletion occurs; confirm an artifact cannot be retrieved after the generating grant is revoked
  - **References:** `REF-ASVS-5`, `REF-AWS-WA-SEC`
  - **Status:** CONFIRMED — T-016

- **SEC-DATA-6** All copies of client vulnerability data MUST be protected to the same standard as the primary store: PostgreSQL data, backups, snapshots, replicas, exports, and report artifacts MUST be encrypted at rest with managed keys, MUST be access-controlled to a least-privilege set of principals, MUST be restricted to the approved region(s) once SQ-17 is resolved, and MUST have a defined retention and secure-disposal period. Production data MUST NOT be copied into non-production environments.
  - **Applies to:** Data Persistence, backups/replicas, report artifact storage, deployment configuration
  - **Verification:** Infrastructure assertions that encryption at rest, key policy, region constraint, and retention are configured on every store and backup; a check that no non-production environment is provisioned with production data
  - **References:** `REF-AWS-WA-SEC`, `REF-AWS-KMS`, `REF-IAC`, `REF-ASVS-5`
  - **Status:** CONFIRMED — T-020 (region pending SQ-17)

- **SEC-DATA-7** Findings, evidence, discovered assets, and imported artefacts MUST be governed by a defined retention schedule tied to the engagement lifecycle rather than retained indefinitely, and MUST be securely disposed of (including from backups and report artifacts, consistent with SEC-DATA-5 and SEC-DATA-6) at the end of that period. Because evidence captures may embed personal data (GDPR scope, SQ-8), the schedule MUST be documented per customer and MUST be enforceable by the system rather than by operator habit. Concrete retention periods are `TO BE DECIDED` (SQ-25).
  - **Applies to:** Data Persistence, Report Engine, backups
  - **Verification:** Test that data past its retention period is disposed of on schedule and that disposal propagates to report artifacts; confirm the schedule is a stored, per-customer configuration rather than a manual process
  - **References:** `REF-ASVS-5`
  - **Status:** TO BE DECIDED (SQ-25) — T-021; implements REQUIREMENTS.md FR-28

### Secrets and keys

- **SEC-SECRETS-1** Engagement credentials MUST be stored only via **AWS KMS and AWS Secrets Manager**. The PostgreSQL database MUST NOT persist credential secret material in plaintext. The Server-side API MUST be the only component permitted to call AWS KMS/Secrets Manager.
  - **References:** `REF-SECRETS`, `REF-AWS-KMS`, `REF-AWS-SECRETS`, `REF-ASVS-5`
  - **Status:** CONFIRMED (SQ-4/SQ-10)

- **SEC-SECRETS-2** Decrypted credential material MUST NOT be returned to any client (internal Browser Client or Customer/Client portal) except as the specific, ABAC-approved output of the request that required it, and MUST NOT appear in application or audit logs.
  - **References:** `REF-SECRETS`, `REF-LOGGING`
  - **Status:** CONFIRMED

- **SEC-SECRETS-3** Access to a given engagement's credentials MUST be governed by the same OPA/Rego ABAC policy set used for findings and reports — no separate or weaker authorization path for credential retrieval. The Customer/Client portal MUST NEVER be granted credential-access policy.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED

- **SEC-SECRETS-4** AWS IAM roles used by the Server-side API and CI/CD pipeline to reach KMS/Secrets Manager MUST follow least privilege (scoped to only the required key/secret operations) and MUST NOT use long-lived static AWS access keys where a federated/short-lived credential mechanism (e.g. OIDC-based role assumption) is available.
  - **References:** `REF-AWS-WA-SEC`, `REF-AWS-KMS`, `REF-SSDF`
  - **Status:** CONFIRMED — new rule required by the AWS provider decision (SQ-4)

- **SEC-SECRETS-5** Engagement credential retrieval MUST be narrowly scoped and accountable: the API's KMS/Secrets Manager permissions MUST allow decrypt/retrieve only for the specific engagement scope of the authorized request rather than a blanket grant across all engagements; each retrieval MUST be individually authorized (SEC-SECRETS-3), step-up-authenticated (SEC-AUTHN-3), and audit-logged with the requesting actor, engagement, and stated purpose; retrieved material MUST NOT be cached beyond the request that required it. Engagement credentials MUST be rotated or revoked when the engagement reaches its end date or an assigned pentester's access is removed.
  - **Applies to:** Secrets/Cloud KMS Boundary, Server-side API
  - **Verification:** Test that the API role cannot decrypt a secret outside the authorized engagement scope; that each retrieval produces an audit entry with actor/engagement/purpose; that engagement closure triggers rotation or revocation
  - **References:** `REF-SECRETS`, `REF-AWS-KMS`, `REF-AWS-SECRETS`, `REF-AWS-WA-SEC`
  - **Status:** CONFIRMED — T-019; implements REQUIREMENTS.md FR-31

- **SEC-SECRETS-6** Unavailability or throttling of AWS KMS/Secrets Manager MUST fail closed — the system MUST NOT fall back to a plaintext, cached, or alternate copy of credential material. The failure MUST be surfaced to the user as a clear, actionable service state rather than an opaque error, so that operational pressure does not push analysts into keeping out-of-band plaintext copies outside the system.
  - **Applies to:** Secrets/Cloud KMS Boundary, Server-side API, Browser Client
  - **Verification:** Fault-injection test making the secrets backend unavailable; assert no fallback path returns credential material and that the surfaced error is non-revealing but actionable
  - **References:** `REF-SECRETS`, `REF-AWS-SECRETS`, `REF-ERROR`
  - **Status:** CONFIRMED — T-028

### Logging and error handling

- **SEC-LOG-1** Access to and changes in findings, credentials, and ABAC policy MUST be fully audit-logged (who, when, what changed), including access performed by the Customer/Client portal actor. Audit and diagnostic logs MUST NOT contain credential secret material, passkey/authenticator private-key material, or DPoP private-key material.
  - **References:** `REF-LOGGING`
  - **Status:** CONFIRMED

- **SEC-LOG-2** Error responses returned to any client MUST NOT expose internal implementation details (stack traces, raw SQL, internal-only identifiers). Detailed diagnostics MUST be retained server-side only.
  - **References:** `REF-ERROR`
  - **Status:** CONFIRMED

- **SEC-LOG-3** The audit log MUST be append-only and tamper-evident: entries MUST NOT be editable or deletable through any application path, the application's own database role MUST NOT hold update or delete rights over it, entries MUST be integrity-protected so that alteration is detectable, and retention/disposal MUST be governed separately from business-data retention. Administrative actions (SEC-AUTHZ-12) and any attempt to alter audit configuration MUST themselves be logged and alerted.
  - **Applies to:** Audit Log Store, Server-side API, Data Persistence
  - **Verification:** Attempt update and delete against audit records through the application and with the application's database role — both MUST fail; assert an integrity check detects an out-of-band alteration
  - **References:** `REF-LOGGING`, `REF-ASVS-5`
  - **Status:** CONFIRMED — T-010, T-030

- **SEC-LOG-4** Each lifecycle transition and approval MUST be recorded as a non-repudiable event binding the acting subject, the exact finding version acted upon, the timestamp, and the identifier of the fresh authentication event that satisfied SEC-AUTHN-3 — a transition MUST NOT be attributable only to a long-lived session. Grants of reviewer rights (SEC-AUTHZ-3) and break-glass grants (SEC-AUTHZ-12) MUST be recorded to the same standard.
  - **Applies to:** Server-side API, Audit Log Store, Identity & Session Handling
  - **Verification:** Assert every approval record references a distinct step-up authentication event and the specific finding version; assert a transition without such a reference cannot be written
  - **References:** `REF-LOGGING`, `REF-63B`, `REF-ASVS-5`
  - **Status:** CONFIRMED — T-013

- **SEC-LOG-5** Every generated report MUST produce a durable generation record capturing who requested it, the recipient scope it was generated under, the template identifier and version, the identifiers and versions of the findings/assets/artefacts included, the output format, and the timestamp — sufficient to reconstruct what a delivered artifact contained without retaining the artifact itself. Access to that record is subject to ABAC like any other resource.
  - **Applies to:** Report Engine, Audit Log Store
  - **Verification:** Generate a report and assert the record reconstructs its exact content set; assert the record is immutable per SEC-LOG-3
  - **References:** `REF-LOGGING`, `REF-ASVS-5`
  - **Status:** CONFIRMED — T-014; implements REQUIREMENTS.md FR-26

### External integrations

- **SEC-INTEG-1** The AI Review Assist pass MUST run as a first-party/in-house model and MUST be treated as advisory/non-authoritative input to the human review workflow. It MUST NOT itself grant, deny, or bypass an ABAC decision or a finding lifecycle transition.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED (SQ-2)

- **SEC-INTEG-2** Because AI Review Assist is first-party, finding data used for the review pass MUST remain within the system's own trust boundary (no third-party API call for this purpose) — this constraint is binding as long as SQ-2's "first-party" decision stands, and MUST be revisited if that decision changes.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED (SQ-2)

- **SEC-INTEG-3** Finding text, evidence, and imported artefact content passed to the AI Review Assist pass MUST be treated as untrusted data, never as instruction: content and instruction MUST be kept structurally separate, the pass MUST have no tool, network, or data access beyond the single finding under review (reinforcing SEC-TRUST-5 and SEC-TRUST-6), and its output MUST be constrained to a defined advisory schema, validated on return, and stored as clearly attributed advisory notes that cannot alter finding fields, ABAC decisions, or lifecycle state (SEC-INTEG-1). Output MUST be rendered under SEC-OUTPUT-1/SEC-OUTPUT-5 like any other untrusted content.
  - **Applies to:** AI Review Assist, Server-side API
  - **Verification:** Submit findings containing instruction-shaped content and assert the pass produces only schema-valid advisory notes, makes no external call, and changes no field or lifecycle state
  - **References:** `REF-ASVS-5`, `REF-INPUTVAL`, `REF-XSS`
  - **Status:** CONFIRMED — T-012

### CI/CD and deployment

- **SEC-DEPLOY-1** Infrastructure provisioning MUST use Terraform (confirmed, SQ-11). Terraform state files and any embedded secrets MUST be kept out of source control and out of application/build logs, and MUST be stored in a backend with access control and encryption at rest (e.g. an S3 backend with server-side encryption and a restrictive bucket policy) rather than committed to the repository.
  - **References:** `REF-IAC`, `REF-SSDF`, `REF-AWS-WA-SEC`
  - **Status:** CONFIRMED (SQ-11)

- **SEC-DEPLOY-2** CI/CD pipelines MUST follow NIST SSDF 1.1 build-integrity practices — least-privilege pipeline credentials, no plaintext secrets in pipeline configuration. The specific CI/CD platform is `UNKNOWN` (SQ-16).
  - **References:** `REF-SSDF`, `REF-CICD`
  - **Status:** TO BE DECIDED (SQ-16)

- **SEC-DEPLOY-3** Infrastructure and policy changes MUST be reviewed and approved by an actor other than their author before apply, the pipeline identity MUST be the only principal able to apply them, and changes affecting IAM, KMS key policy, Secrets Manager access, database access, egress policy (SEC-TRUST-6), or Rego policy (SEC-AUTHZ-8) MUST be flagged for explicit security review. Drift between applied infrastructure and committed configuration MUST be detected and alerted. Build inputs MUST be integrity-verified and dependency resolution MUST be frozen (DEP-7), so that a compromised dependency or toolchain cannot silently enter a deployed artifact.
  - **Applies to:** Deployment (Terraform, AWS), CI/CD, ABAC policy release
  - **Verification:** Assert the pipeline refuses a self-approved change to a flagged resource type; assert drift detection alerts on an out-of-band change; assert builds fail on an unpinned or integrity-mismatched dependency
  - **References:** `REF-IAC`, `REF-CICD`, `REF-SSDF`, `REF-SUPPLYCHAIN`, `REF-AWS-WA-SEC`
  - **Status:** CONFIRMED — T-011, T-033 (platform pending SQ-16)

### Backend framework (Go 1.27 / Gin v1.12.0)

Synthesized from `REF-GIN-112`, applied on top of the rules above rather than replacing them (e.g. Gin's middleware chain is *how* SEC-TRUST-1 and SEC-AUTHZ-1 get enforced in code, not a separate authorization model).

- **SEC-GIN-1** The Server-side API MUST build its Gin engine with `gin.New()` and an explicit, reviewed middleware stack (authentication, OPA/Rego ABAC check, rate limiting, structured logging, recovery) registered via `Use` before any protected route group is created — `gin.Default()`'s bundled `Logger`/`Recovery` MUST NOT be mistaken for an enforcement stack. Every rejecting handler/middleware MUST call `c.AbortWithStatus`/`c.AbortWithStatusJSON` and return immediately.
  - **Applies to:** Server-side API
  - **Verification:** A route registered after the security middleware group carries the full chain; a rejection test confirms the downstream handler never executes
  - **References:** `REF-GIN-112`, `REF-ASVS-5`
  - **Status:** CONFIRMED — traces to SEC-TRUST-1, SEC-AUTHZ-1

- **SEC-GIN-2** Handlers MUST read the authenticated principal via `c.Get` with an explicit presence/type check, and MUST run the OPA/Rego authorization decision against the specific resource resolved from `c.Param`/bound input before acting — resolving a route parameter is not itself an authorization check.
  - **Applies to:** All ABAC-scoped endpoints
  - **Verification:** Test that a missing or wrongly-typed context value is rejected rather than treated as an implicit valid principal
  - **References:** `REF-GIN-112`
  - **Status:** CONFIRMED — traces to SEC-AUTHZ-1

- **SEC-GIN-3** Routes MUST register only the specific HTTP methods they need (no `gin.Any`). Static assets, admin routes, and `NoRoute`/`NoMethod` fallback handlers MUST enforce the same authentication/ABAC checks as explicitly protected routes rather than relying on obscurity.
  - **References:** `REF-GIN-112`
  - **Status:** CONFIRMED — traces to SEC-TRUST-1

- **SEC-GIN-4** REST inputs MUST be bound with explicit, endpoint-specific binders and per-operation request structs that exclude server-owned fields (id, owner, status, ABAC-relevant flags) — omitting a `json` tag MUST NOT be relied on to hide a field. `gin.EnableJsonDecoderDisallowUnknownFields()` MUST be enabled, and a binding error MUST abort the request before any partially-bound value is used.
  - **References:** `REF-GIN-112`, `REF-INPUTVAL`
  - **Status:** CONFIRMED — traces to SEC-INPUT-1

- **SEC-GIN-5** `SetTrustedProxies` MUST be configured to exact known proxy addresses/CIDRs (or `nil` for direct traffic), and startup MUST fail on misconfiguration. `c.ClientIP()` MUST be treated as a supplemental signal only, never as an authenticated identity or the sole actor identifier in an audit-log entry. `TrustedPlatform` and legacy App Engine header trust MUST remain disabled unless ingress guarantees those headers cannot be spoofed by a client.
  - **References:** `REF-GIN-112`
  - **Status:** CONFIRMED — traces to SEC-LOG-1, NFR-2

- **SEC-GIN-6** If any cookie-based session or CSRF-relevant state is ever introduced, `c.SetSameSite` MUST be called before `c.SetCookie` with a deliberate value, and CORS middleware MUST use an explicit origin allow-list, never a wildcard combined with credentials. Given the confirmed session model is DPoP-bound bearer tokens (SEC-SESSION-1), cookie-based session authentication SHOULD NOT be introduced without a corresponding CSRF-defense decision being made first.
  - **References:** `REF-GIN-112`, `REF-SESSION`
  - **Status:** CONFIRMED — traces to SEC-HTTP-3, SEC-SESSION-1

- **SEC-GIN-7** All import-file (SEC-TRUST-2/SEC-TRUST-3) and report-template uploads MUST be bounded by an explicit request body-size limit applied before binding/`FormFile`/`MultipartForm` — Gin's default in-memory multipart threshold MUST NOT be treated as an upload-size cap. Uploaded files MUST be written to generated destinations outside executable/static roots using exclusive file-creation; `SaveUploadedFile`'s default overwrite/symlink-following behavior MUST NOT be used on a caller-influenced destination path.
  - **References:** `REF-GIN-112`, `REF-INPUTVAL`
  - **Status:** CONFIRMED — traces to SEC-TRUST-2, SEC-TRUST-3

- **SEC-GIN-8** Responses MUST use `c.JSON` with explicit response structs; `c.Data`/`PureJSON` output containing untrusted content MUST NOT be embedded directly into an HTML or script context. Any server-side redirect target MUST be validated against an allow-list of local paths or exact approved origins before use in `c.Redirect`.
  - **References:** `REF-GIN-112`, `REF-XSS`
  - **Status:** CONFIRMED — traces to SEC-OUTPUT-1, SEC-OUTPUT-2

- **SEC-GIN-9** Production MUST run with `GIN_MODE=release` behind an explicitly configured `http.Server` (read/write/idle timeouts, bounded shutdown) rather than `Engine.Run`'s convenience defaults. Request-scoped work MUST propagate `c.Request.Context()` (with `Engine.ContextWithFallback` enabled); the pooled `gin.Context` or its values MUST NOT be retained past the request, including in goroutines spawned by a handler.
  - **References:** `REF-GIN-112`, `REF-SSDF`
  - **Status:** CONFIRMED — traces to SEC-DEPLOY-2

- **SEC-GIN-10** Structured request logging MUST use `LoggerWithConfig` with `SkipQueryString` enabled wherever a query string can carry a sensitive value (e.g. a signed URL or token). `gin.ErrorLogger()` MUST NOT be installed on any public-facing route, since it serializes private errors into the response. Panic recovery MUST use a custom, redacted recovery writer rather than the default recovery dump.
  - **References:** `REF-GIN-112`, `REF-LOGGING`, `REF-ERROR`
  - **Status:** CONFIRMED — traces to SEC-LOG-1, SEC-LOG-2

---

## Requirement and Architecture Traceability

The **Threat** column names the `T-*` entry that motivated a rule; `—` means the rule predates the 2026-09-21 threat model.

| Rule(s) | Threat | Requirement(s) | Component(s) | Status |
|---|---|---|---|---|
| SEC-TRUST-1 | — | §6, FR-13–FR-15 | Server-side API, Browser Client, Customer/Client portal | CONFIRMED |
| SEC-TRUST-2, SEC-TRUST-3 | — | §7 | Import Pipeline, Report Engine | CONFIRMED |
| SEC-TRUST-4 | T-007, T-008 | §7, FR-23 | Import Pipeline, Report Engine | CONFIRMED |
| SEC-TRUST-5 | T-017, T-031 | FR-19–FR-21, FR-29 | Import Pipeline, AI Review Assist, Server-side API | CONFIRMED |
| SEC-TRUST-6 | T-018 | §7, §8 | Import Pipeline, Report Engine, Deployment | CONFIRMED |
| SEC-TRUST-7 | T-007, T-024, T-025 | FR-32 | Import Pipeline, Report Engine, Async Job Runner | CONFIRMED |
| SEC-AUTHN-1, SEC-AUTHN-2, SEC-AUTHN-3 | — | §2 (actors) | Identity & Session Handling | CONFIRMED |
| SEC-AUTHN-4 | — | §2 | Identity & Session Handling, Customer/Client portal | TO BE DECIDED (SQ-14) |
| SEC-AUTHN-5 | T-001 | FR-30 | Identity & Session Handling | CONFIRMED |
| SEC-AUTHN-6 | T-004 | §2 | Identity & Session Handling | CONFIRMED |
| SEC-SESSION-1 | — | — (architecture note) | Identity & Session Handling | CONFIRMED |
| SEC-SESSION-2 | — | — | Identity & Session Handling | TO BE DECIDED (SQ-15) |
| SEC-SESSION-3 | T-002 | — (architecture note) | Identity & Session Handling, both client surfaces | CONFIRMED (values pending SQ-15) |
| SEC-AUTHZ-1, SEC-AUTHZ-2, SEC-AUTHZ-3 | — | FR-13, FR-14, FR-15, §6.1, §6.3 | Server-side API (ABAC decision point) | CONFIRMED |
| SEC-AUTHZ-4 | — | §6.5 | ABAC Decision (OPA/Rego) | CONFIRMED |
| SEC-AUTHZ-5 | — | FR-24, §8.4 | Report Engine | CONFIRMED |
| SEC-AUTHZ-6 | — | §2 | Customer/Client portal | CONFIRMED |
| SEC-AUTHZ-7 | T-003 | §2, §6 | Customer/Client portal, Server-side API | CONFIRMED |
| SEC-AUTHZ-8 | T-005 | §6.5 | ABAC Decision, Deployment pipeline | CONFIRMED (topology pending SQ-20) |
| SEC-AUTHZ-9 | T-022 | §6 | Server-side API, Customer/Client portal | CONFIRMED |
| SEC-AUTHZ-10 | T-026 | §6.5 | ABAC Decision, Server-side API | CONFIRMED (topology pending SQ-20) |
| SEC-AUTHZ-11 | T-029 | FR-9, FR-10, FR-15, FR-27 | Server-side API, OPA/Rego policy set | CONFIRMED |
| SEC-AUTHZ-12 | T-030 | §2 (Admin), FR-14 | Server-side API, Identity & Session Handling | CONFIRMED |
| SEC-WORKFLOW-1 | T-006 | FR-9, FR-10, §5 | Server-side API | CONFIRMED |
| SEC-HTTP-1, SEC-HTTP-2 | — | — (architecture note) | Server-side API | CONFIRMED |
| SEC-HTTP-3 | — | — | Server-side API, Customer/Client portal | TO BE DECIDED |
| SEC-HTTP-4 | T-027 | NFR-1 | Server-side API | CONFIRMED |
| SEC-INPUT-1 | — | FR-3, FR-4, §7.2 | Server-side API, Import Pipeline | CONFIRMED |
| SEC-INPUT-2 | T-032 | §9.2 | Server-side API, Data Persistence, Import Pipeline | CONFIRMED |
| SEC-OUTPUT-1 | — | §3.4 | Browser Client, Customer/Client portal | CONFIRMED |
| SEC-OUTPUT-2 | — | FR-23 | Report Engine | CONFIRMED |
| SEC-OUTPUT-3 | T-008 | FR-23 | Report Engine | CONFIRMED (ownership pending SQ-21) |
| SEC-OUTPUT-4 | T-009 | §8.5, FR-22 | Report Engine | CONFIRMED |
| SEC-OUTPUT-5 | T-023, T-033 | NFR-1 | Browser Client, Customer/Client portal, Server-side API | CONFIRMED |
| SEC-DATA-1 | — | NFR-1, §3.5, §6.4 | Server-side API, Report Engine | CONFIRMED |
| SEC-DATA-2 | — | NFR-4 | — | PARTIALLY DEFINED |
| SEC-DATA-3 | — | §10 | Server-side API, Data Persistence | TO BE DECIDED (SQ-19) |
| SEC-DATA-4 | T-015 | §3.5, §6.4, FR-13 | Server-side API, Report Engine, Data Persistence | CONFIRMED |
| SEC-DATA-5 | T-016 | FR-24, §8.4 | Report Engine, Report Artifact Store | CONFIRMED |
| SEC-DATA-6 | T-020 | NFR-1, NFR-4 | Data Persistence, backups, Deployment | CONFIRMED (region pending SQ-17) |
| SEC-DATA-7 | T-021 | FR-28, NFR-4 | Data Persistence, Report Engine | TO BE DECIDED (SQ-25) |
| SEC-SECRETS-1, SEC-SECRETS-2, SEC-SECRETS-3 | — | FR-16, FR-17, FR-18, NFR-3 | Secrets/Cloud KMS Boundary (AWS), Server-side API | CONFIRMED |
| SEC-SECRETS-4 | — | NFR-3 | Secrets/Cloud KMS Boundary, CI/CD | CONFIRMED |
| SEC-SECRETS-5 | T-019 | FR-16, FR-18, FR-31 | Secrets/Cloud KMS Boundary, Server-side API | CONFIRMED |
| SEC-SECRETS-6 | T-028 | FR-17, NFR-3 | Secrets/Cloud KMS Boundary, Server-side API | CONFIRMED |
| SEC-LOG-1 | T-034 | NFR-2, NFR-3, FR-12 | Server-side API | CONFIRMED |
| SEC-LOG-2 | — | — | Server-side API | CONFIRMED |
| SEC-LOG-3 | T-010, T-030 | NFR-2 | Audit Log Store, Server-side API | CONFIRMED |
| SEC-LOG-4 | T-013 | FR-9, FR-12 | Server-side API, Audit Log Store | CONFIRMED |
| SEC-LOG-5 | T-014 | FR-26, §8 | Report Engine, Audit Log Store | CONFIRMED |
| SEC-INTEG-1, SEC-INTEG-2 | — | FR-11 | AI Review Assist | CONFIRMED |
| SEC-INTEG-3 | T-012 | FR-11 | AI Review Assist, Server-side API | CONFIRMED |
| SEC-DEPLOY-1 | — | — | Deployment (Terraform, AWS) | CONFIRMED |
| SEC-DEPLOY-2 | — | — | CI/CD (UNKNOWN) | TO BE DECIDED (SQ-16) |
| SEC-DEPLOY-3 | T-011, T-033 | — | Deployment, CI/CD, ABAC policy release | CONFIRMED (platform pending SQ-16) |
| SEC-GIN-1, SEC-GIN-2, SEC-GIN-3 | T-027 (rate limiting) | §6, FR-13–FR-15 | Server-side API (Gin) | CONFIRMED |
| SEC-GIN-4, SEC-GIN-7 | T-006, T-024 | FR-3, FR-4, §7.2, FR-23 | Server-side API, Import Pipeline, Report Engine | CONFIRMED |
| SEC-GIN-5 | — | NFR-2 | Server-side API | CONFIRMED |
| SEC-GIN-6 | — | — (architecture note) | Server-side API | CONFIRMED |
| SEC-GIN-8 | T-023 | §3.4 | Server-side API, Report Engine | CONFIRMED |
| SEC-GIN-9 | — | — | Server-side API, Deployment | CONFIRMED |
| SEC-GIN-10 | — | NFR-2, NFR-3 | Server-side API | CONFIRMED |

---

## Dependency Security Rules

These are prospective rules for future implementation; no dependency has been assessed because no implementation exists yet. They apply once the Go/Gin backend, React frontend, and Terraform modules begin adding dependencies. Relevant references: `REF-DEPMGMT`, `REF-SUPPLYCHAIN`, `REF-IAC`.

- **DEP-1** The project MUST NOT add a dependency when the standard library or a small amount of straightforward, non-security-sensitive first-party code is safer and sufficient. The project MUST NOT replace vetted cryptography, authentication, authorization, protocol parsing, output encoding, HTML sanitization, or other security-critical functionality with custom code merely to avoid a dependency.
- **DEP-2** The project SHOULD prefer zero new dependencies. Every new dependency MUST be justified in the pull request description, including its purpose and why existing code or platform functionality is insufficient.
- **DEP-3** A new dependency MUST show evidence of active maintenance through a stable release, security response, or substantive maintainer activity within the previous 12 months. A mature project with less frequent releases requires an explicit documented exception and evidence that security reports are still handled.
- **DEP-4** The project MUST use the latest stable release from the latest actively supported major version unless a documented compatibility constraint requires another actively supported major version. Deprecated, abandoned, end-of-life, or pre-release packages MUST NOT be introduced into production.
- **DEP-5** Before a dependency is added or updated, direct and transitive dependencies MUST be checked for known vulnerabilities. A dependency with a known unpatched vulnerability applicable to the intended use MUST NOT be introduced without explicit, time-bounded risk acceptance, documented compensating controls, and a remediation plan.
- **DEP-6** Dependency review MUST include the complete transitive dependency graph. A small direct dependency with a disproportionately large, opaque, abandoned, or unvetted transitive tree SHOULD be rejected.
- **DEP-7** Production builds MUST resolve dependencies to exact versions through a committed lockfile or equivalent ecosystem mechanism. Production and CI builds MUST use frozen or reproducible dependency resolution and MUST NOT resolve floating versions at build or deployment time.
- **DEP-8** When multiple suitable libraries exist, the project SHOULD prefer the library with the narrowest required scope, smallest dependency tree, active security response process, clear provenance, and established security track record.

---

## Prompt Placeholders To Resolve

- `{{CODE_QUALITY_PROMPT}}` — **RESOLVED** (no local code-quality prompt found): low cyclomatic and cognitive complexity; small cohesive functions and modules; separated presentation, business-rule, persistence, and integration concerns; explicit error handling and trust-boundary transitions; no duplicated security-sensitive logic; testability without hidden global state.
- `{{API_SECURITY_PROMPT}}` — **RESOLVED**: `REF-API-2023` (OWASP API Security Top 10 2023) plus `REF-REST` (OWASP REST Security Cheat Sheet).
- `{{BACKEND_FRAMEWORK_PROMPT}}` — **RESOLVED**: backend framework and version are now identified (Go 1.27 baseline, Gin v1.12.0). Resolved via `REF-GIN-112`, a user-supplied Gin 1.12 Secure Coding Prompt, synthesized into `SEC-GIN-1` through `SEC-GIN-10` above. The prompt itself is designed to layer onto "the resolved Go 1.27 prompt" — that underlying Go-language-baseline prompt was not supplied in this session, so language-level (non-Gin-specific) Go secure-coding rules remain **PARTIALLY RESOLVED**; see SQ-24.
- `{{FRONTEND_FRAMEWORK_PROMPT}}` — **PARTIALLY RESOLVED**: frontend framework (React) is named, but no version is given. `REF-XSS` serves as a framework-neutral rendering baseline (SEC-OUTPUT-1) but does not itself resolve this placeholder. Framework version: `TO BE DECIDED`.
- `{{AUTH_PROMPT}}` — **RESOLVED**: `REF-WEBAUTHN`, `REF-FIDO`, `REF-AUTH`, `REF-SESSION`, `REF-63B`.
- `{{DEPLOYMENT_PROMPT}}` — **RESOLVED for IaC/provider; PARTIALLY RESOLVED for CI/CD platform**: `REF-SSDF`, `REF-CICD`, `REF-IAC`, and `REF-AWS-WA-SEC`/`REF-AWS-KMS`/`REF-AWS-SECRETS` now apply given Terraform + AWS are confirmed (SQ-4, SQ-11). The specific CI/CD platform remains `UNKNOWN` (SQ-16).

---

## Open Security Questions

- **SQ-14** What authentication assurance level applies to the Customer/Client portal actor — the same AAL3 passkey requirement as internal users, or a different/lower bar appropriate for read-only external customers? (follow-on from SQ-7)
- **SQ-15** What are the concrete session/DPoP-token lifetime values and the specific revocation mechanism? (follow-on from SQ-3)
- **SQ-16** What CI/CD platform will execute Terraform plans/applies and application builds/deploys (e.g. GitHub Actions or another system)? (follow-on from SQ-11)
- **SQ-17** Which AWS region(s) will host reporTool, and does GDPR scope require EU-specific data residency? (follow-on from SQ-4/SQ-8)
- **SQ-18** What audit/evidence cadence and control ownership satisfies the SOC 2 Type II and ISO 27001 targets (e.g. access-review frequency, named control owner)? (follow-on from SQ-8)
- **SQ-19** What concrete mechanism satisfies GDPR data-subject export/deletion/rectification requests against finding/asset data that may contain personal data, and who is authorized to invoke it? (follow-on from SQ-8)
- **SQ-20** Should OPA be deployed as a centralized decision service or embedded per-API-instance, and what is the Rego policy versioning/release process? (follow-on from SQ-1)
- **SQ-21** Who is authorized to upload or modify baseline report templates (FR-23), and does the DOCX template pipeline need dedicated macro-stripping/validation tooling beyond generic file-type validation? (follow-on from SQ-6)
- **SQ-22** The architecture note "cloud model enterprise license (review)" remains `UNKNOWN` even with AWS now confirmed as the cloud provider — does this refer to an AWS Enterprise Support/Enterprise Agreement, or something else, and does it require legal/procurement review before Terraform work begins?

Carried over from the previous revision (not yet resolved by any stakeholder decision):
- **SQ-23** (was SQ-12's remainder) Beyond the ASVS Level 2 target, is there a fixed cadence for re-running the STRIDE threat model (e.g. per release, per quarter, per new trust boundary)?
- **SQ-24** The Gin 1.12 Secure Coding Prompt (`REF-GIN-112`) states it should be layered on top of "the resolved Go 1.27 prompt," which was not supplied in this session. Obtain and integrate that Go-language-baseline secure-coding prompt so language-level rules (memory/concurrency safety, crypto primitives, standard-library pitfalls, etc.) are captured in `SECURITY.md` alongside the Gin-specific `SEC-GIN-*` rules.

Raised by the STRIDE threat model (2026-09-21); each names the threat that raised it:
- **SQ-25** (T-021, SEC-DATA-7) What are the concrete retention periods for findings, evidence, imported artefacts, and generated report artifacts — per customer, per engagement type, or a single default — and who is authorized to set or override them? Until answered, no retention period can be implemented and SEC-DATA-7 stays `TO BE DECIDED`.
- **SQ-26** (T-003, T-017, T-022) Is the deployment model single-tenant per pentest group or multi-tenant SaaS (REQUIREMENTS.md §12.3)? The threat model rates cross-customer isolation against the stricter multi-tenant reading; a single-tenant decision would change the isolation boundary, not remove it.
- **SQ-27** (T-029, SEC-AUTHZ-11) How is separation of duties satisfied on a small engagement where the author may be the only qualified reviewer available — is an explicit, audited, dual-authorized exception permitted, or is the finding blocked until another reviewer exists? An exception path MUST NOT be added silently at implementation time.
- **SQ-28** (T-030, SEC-AUTHZ-12) Who holds the second approval for administrative and break-glass actions in a group small enough that a single person may be the only Admin, and what is the fallback when no second approver is reachable?
- **SQ-29** (T-002, T-023) Where is the client-held DPoP key stored in the browser such that it is non-extractable, and what is the intended behavior across tabs, browser restart, and the separate portal origin (interacts with SEC-HTTP-3)?
- **SQ-30** (T-010, SEC-LOG-3) What backing store and integrity mechanism provides the append-only, tamper-evident audit log, and is its retention period independent of the business-data retention decided under SQ-25?
- **SQ-31** (T-016, SEC-DATA-5) How are generated report artifacts delivered to a customer — retrieved through the portal under live authorization, or exported out of the system entirely? Once an artifact leaves the system the ABAC and retention controls above no longer apply, and that boundary needs an explicit decision.
- **SQ-32** (T-012, SEC-INTEG-3) What advisory-output schema does the AI Review Assist pass return, and where does it run relative to the API's trust boundary (in-process, separate service, separate account) given SEC-INTEG-2's first-party constraint?

---

*Changes to this document should be made deliberately. When a requirement or architecture decision changes, update `REQUIREMENTS.md` or `ARCHITECTURE.md` first, then reflect the consequence here.*
