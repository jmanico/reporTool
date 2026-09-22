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

The stakeholder decisions below resolve the open questions raised in the previous revision of this document. They are recorded here as the authoritative security-posture decisions; where a decision adds to or clarifies `REQUIREMENTS.md` or `ARCHITECTURE.md` rather than merely filling a gap those documents already flagged as open, that is called out under **Decisions Requiring Requirements/Architecture Sync**.

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

These decisions are reflected in the **Required Security Inputs**, **Provisional Security Rules**, and **Prompt Placeholders** sections below. New follow-on questions each decision raises are carried into **Open Security Questions**.

### Decisions Requiring Requirements/Architecture Sync

These stakeholder decisions extend or change facts stated in `REQUIREMENTS.md`/`ARCHITECTURE.md` rather than merely resolving an `[OPEN]` marker already scoped there as a gap. `SECURITY.md` records them so security work can proceed, but **`REQUIREMENTS.md` and `ARCHITECTURE.md` should be updated to match** — per this document's own rule, a security note must not silently override those documents.

- **Customer/Client portal (SQ-7):** `REQUIREMENTS.md` §2 lists this persona as `[OPEN — is client portal access in scope for v1?]` and §11 lists it under "Out of scope (for now)." The decision above sets it in scope for v1. `REQUIREMENTS.md` §2/§11 and `ARCHITECTURE.md`'s system context diagram (which currently marks the client actor as open/dashed) should be updated accordingly, including the read-only access model and which fields a customer may see by default.
- **Rejected terminal state (SQ-9):** `REQUIREMENTS.md` §5 documents only `Draft → Technical Review → Final Review → Accepted` with send-back-with-comments, and does not currently define a terminal `Rejected` state. `REQUIREMENTS.md` §5 and `ARCHITECTURE.md`'s finding-lifecycle description should be updated to add it.
- **Scanner scope (SQ-5):** `REQUIREMENTS.md` §7.1 states "Burp Suite export is the first supported import source" and §12 lists additional scanners as an open question. Committing to ZAP, Nessus, and Nuclide all for v1 is a scope increase beyond "first supported source" that `REQUIREMENTS.md` §7 should reflect (FR-19–FR-21 and the import pipeline's v1 acceptance criteria).
- **Report formats (SQ-6):** `REQUIREMENTS.md` §8's open question 6 is resolved to PDF and DOCX; `REQUIREMENTS.md` §8 should record this so FR-22–FR-25 can be scoped against a fixed format set.
- **Backend runtime/framework version (Gin 1.12 prompt, 2026-09-21):** `ARCHITECTURE.md` names "Go, using the Gin framework" without a version. A Gin 1.12 Secure Coding Prompt supplied directly in-session pins this to **Go 1.27 baseline, Gin v1.12.0** (Gin requires Go ≥ 1.25.0). `ARCHITECTURE.md`'s "Required Architecture Inputs" table should be updated to record these versions as a fixed decision, not left implicit in `SECURITY.md` alone.

---

## Required Security Inputs

| Field | Value |
|---|---|
| Requirements source | REQUIREMENTS.md |
| Design source | DESIGN.md |
| Architecture source | ARCHITECTURE.md |
| System purpose | A platform for a pentest group to run and report on security testing engagements — standardized finding capture/review/CWE-ASVS mapping, multi-customer engagement tracking, structured report generation, fine-grained access control, and safe engagement credential management (REQUIREMENTS.md §1). |
| Application profile | Web application, API monolith. Server: Go **1.27** baseline, Gin **v1.12.0** (per the Gin 1.12 Secure Coding Prompt supplied 2026-09-21 — see `REF-GIN-112`; this pins a version ARCHITECTURE.md leaves open, see "Decisions Requiring Requirements/Architecture Sync"). Client: React SPA (version `UNKNOWN`). API style: REST/JSON. Data store: **PostgreSQL**, normalized to 3NF (SQ-10). |
| Users / actors / roles | Pentester (Author), Technical Reviewer, Final Reviewer, Engagement/Project Manager, Admin (REQUIREMENTS.md §2). **A read-only Customer/Client portal actor is now in scope for v1 (SQ-7)** — see "Decisions Requiring Requirements/Architecture Sync" above; its authentication assurance level is a new open question (SQ-14). |
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
| Threat model status | **Methodology decided: STRIDE, produced/updated at design time for each major architectural change (SQ-12).** No STRIDE artifact exists yet — first pass is a prerequisite before implementation of any new trust boundary (e.g. the new Customer/Client portal). |

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

### Session management

- **SEC-SESSION-1** Sessions MUST be sender-constrained using DPoP-bound JWTs. The API MUST reject any bearer token presented without a valid DPoP proof bound to the same key and matching HTTP method/URI.
  - **References:** `REF-SESSION`, `REF-AUTH`
  - **Status:** CONFIRMED

- **SEC-SESSION-2** Concrete session/access-token lifetime and revocation-mechanism values are `TO BE DECIDED` (SQ-15). Until decided, the provisional default is short-lived access tokens with a server-side revocation capability; long-lived, unrevocable bearer tokens MUST NOT be issued. Step-up per SEC-AUTHN-3 applies regardless of the chosen token lifetime.
  - **References:** `REF-SESSION`
  - **Status:** TO BE DECIDED (SQ-15)

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

### Input validation

- **SEC-INPUT-1** All data crossing the trust boundary into the Server-side API — REST request bodies, query parameters, and imported artefact files across all four v1 scanner formats — MUST be validated for both format/type and business-rule meaning (e.g., a well-formed CWE identifier, a well-formed ASVS control identifier, an allowed severity value) before being persisted or acted upon.
  - **References:** `REF-INPUTVAL`, `REF-ASVS-5`
  - **Status:** CONFIRMED

### Output encoding and safe rendering

- **SEC-OUTPUT-1** The React SPA and the Customer/Client portal MUST render server-supplied and user-supplied content (finding text, evidence, imported artefact content) using framework-provided safe rendering. Raw HTML/DOM injection interfaces for untrusted content MUST NOT be used.
  - **References:** `REF-XSS`
  - **Status:** CONFIRMED

- **SEC-OUTPUT-2** Uploaded DOCX report templates (FR-23) MUST NOT support embedded macros or other active/executable content, and MUST be validated/sanitized before use in report generation, regardless of the uploader's role.
  - **Applies to:** Report Engine template ingestion
  - **Verification:** Test upload of a DOCX template containing a macro or embedded object and confirm rejection or stripping before the template is accepted
  - **References:** `REF-INPUTVAL`, `REF-ASVS-5`
  - **Status:** CONFIRMED — new rule required by the DOCX output-format decision (SQ-6)

### Data protection and privacy

- **SEC-DATA-1** Field-level access restrictions (REQUIREMENTS.md §3.5, §6.4) MUST be enforced by the API on every read path that can expose finding-field data, including list, bulk, search, and export/report endpoints, for both internal actors and the Customer/Client portal.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED

- **SEC-DATA-2** The system targets **SOC 2 Type II, GDPR, and ISO 27001** (SQ-8). Concrete data-residency region, GDPR lawful-basis documentation, and SOC 2/ISO 27001 control-evidence ownership/cadence are `TO BE DECIDED` (SQ-17, SQ-18) — no specific control implementation is claimed as complete by this document.
  - **Status:** PARTIALLY DEFINED (SQ-8 resolved at the "which regimes" level; implementation detail open)

- **SEC-DATA-3** Where finding, asset, or artefact data identifies or relates to an individual (GDPR personal data), the system MUST support data-subject export and deletion requests scoped to that individual's data, consistent with ABAC (i.e., a deletion/export request MUST NOT be actionable by an unauthorized requester). Concrete mechanism is `TO BE DECIDED` (SQ-19).
  - **References:** `REF-ASVS-5`
  - **Status:** TO BE DECIDED (SQ-19) — new rule required by the GDPR decision (SQ-8)

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

### Logging and error handling

- **SEC-LOG-1** Access to and changes in findings, credentials, and ABAC policy MUST be fully audit-logged (who, when, what changed), including access performed by the Customer/Client portal actor. Audit and diagnostic logs MUST NOT contain credential secret material, passkey/authenticator private-key material, or DPoP private-key material.
  - **References:** `REF-LOGGING`
  - **Status:** CONFIRMED

- **SEC-LOG-2** Error responses returned to any client MUST NOT expose internal implementation details (stack traces, raw SQL, internal-only identifiers). Detailed diagnostics MUST be retained server-side only.
  - **References:** `REF-ERROR`
  - **Status:** CONFIRMED

### External integrations

- **SEC-INTEG-1** The AI Review Assist pass MUST run as a first-party/in-house model and MUST be treated as advisory/non-authoritative input to the human review workflow. It MUST NOT itself grant, deny, or bypass an ABAC decision or a finding lifecycle transition.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED (SQ-2)

- **SEC-INTEG-2** Because AI Review Assist is first-party, finding data used for the review pass MUST remain within the system's own trust boundary (no third-party API call for this purpose) — this constraint is binding as long as SQ-2's "first-party" decision stands, and MUST be revisited if that decision changes.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED (SQ-2)

### CI/CD and deployment

- **SEC-DEPLOY-1** Infrastructure provisioning MUST use Terraform (confirmed, SQ-11). Terraform state files and any embedded secrets MUST be kept out of source control and out of application/build logs, and MUST be stored in a backend with access control and encryption at rest (e.g. an S3 backend with server-side encryption and a restrictive bucket policy) rather than committed to the repository.
  - **References:** `REF-IAC`, `REF-SSDF`, `REF-AWS-WA-SEC`
  - **Status:** CONFIRMED (SQ-11)

- **SEC-DEPLOY-2** CI/CD pipelines MUST follow NIST SSDF 1.1 build-integrity practices — least-privilege pipeline credentials, no plaintext secrets in pipeline configuration. The specific CI/CD platform is `UNKNOWN` (SQ-16).
  - **References:** `REF-SSDF`, `REF-CICD`
  - **Status:** TO BE DECIDED (SQ-16)

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

| Rule(s) | Requirement(s) | Component(s) | Status |
|---|---|---|---|
| SEC-TRUST-1 | §6, FR-13–FR-15 | Server-side API, Browser Client, Customer/Client portal | CONFIRMED |
| SEC-TRUST-2, SEC-TRUST-3 | §7 | Import Pipeline, Report Engine | CONFIRMED |
| SEC-AUTHN-1, SEC-AUTHN-2, SEC-AUTHN-3 | §2 (actors) | Identity & Session Handling | CONFIRMED |
| SEC-AUTHN-4 | §2, §12.1 | Identity & Session Handling, Customer/Client portal | TO BE DECIDED (SQ-14) |
| SEC-SESSION-1 | — (architecture note) | Identity & Session Handling | CONFIRMED |
| SEC-SESSION-2 | — | Identity & Session Handling | TO BE DECIDED (SQ-15) |
| SEC-AUTHZ-1, SEC-AUTHZ-2, SEC-AUTHZ-3 | FR-13, FR-14, FR-15, §6.1, §6.3 | Server-side API (ABAC decision point) | CONFIRMED |
| SEC-AUTHZ-4 | §6.5 (open question 4) | ABAC Decision (OPA/Rego) | CONFIRMED |
| SEC-AUTHZ-5 | FR-24, §8.4 | Report Engine | CONFIRMED |
| SEC-AUTHZ-6 | §2, §11, §12.1 | Customer/Client portal | CONFIRMED |
| SEC-HTTP-1, SEC-HTTP-2 | — (architecture note) | Server-side API | CONFIRMED |
| SEC-HTTP-3 | — | Server-side API, Customer/Client portal | TO BE DECIDED |
| SEC-INPUT-1 | FR-3, FR-4, §7.2 | Server-side API, Import Pipeline | CONFIRMED |
| SEC-OUTPUT-1 | §3.4 | Browser Client, Customer/Client portal | CONFIRMED |
| SEC-OUTPUT-2 | FR-23 | Report Engine | CONFIRMED |
| SEC-DATA-1 | NFR-1, §3.5, §6.4 | Server-side API, Report Engine | CONFIRMED |
| SEC-DATA-2 | §10 (open question 9) | — | PARTIALLY DEFINED |
| SEC-DATA-3 | §10 | Server-side API, Data Persistence | TO BE DECIDED (SQ-19) |
| SEC-SECRETS-1, SEC-SECRETS-2, SEC-SECRETS-3 | FR-16, FR-17, FR-18, NFR-3 | Secrets/Cloud KMS Boundary (AWS), Server-side API | CONFIRMED |
| SEC-SECRETS-4 | NFR-3 | Secrets/Cloud KMS Boundary, CI/CD | CONFIRMED |
| SEC-LOG-1 | NFR-2, NFR-3, FR-12 | Server-side API | CONFIRMED |
| SEC-LOG-2 | — | Server-side API | CONFIRMED |
| SEC-INTEG-1, SEC-INTEG-2 | FR-11 | AI Review Assist | CONFIRMED |
| SEC-DEPLOY-1 | — | Deployment (Terraform, AWS) | CONFIRMED |
| SEC-DEPLOY-2 | — | CI/CD (UNKNOWN) | TO BE DECIDED (SQ-16) |
| SEC-GIN-1, SEC-GIN-2, SEC-GIN-3 | §6, FR-13–FR-15 | Server-side API (Gin) | CONFIRMED |
| SEC-GIN-4, SEC-GIN-7 | FR-3, FR-4, §7.2, FR-23 | Server-side API, Import Pipeline, Report Engine | CONFIRMED |
| SEC-GIN-5 | NFR-2 | Server-side API | CONFIRMED |
| SEC-GIN-6 | — (architecture note) | Server-side API | CONFIRMED |
| SEC-GIN-8 | §3.4 | Server-side API, Report Engine | CONFIRMED |
| SEC-GIN-9 | — | Server-side API, Deployment | CONFIRMED |
| SEC-GIN-10 | NFR-2, NFR-3 | Server-side API | CONFIRMED |

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

---

*Changes to this document should be made deliberately. When a requirement or architecture decision changes, update `REQUIREMENTS.md` or `ARCHITECTURE.md` first, then reflect the consequence here.*
