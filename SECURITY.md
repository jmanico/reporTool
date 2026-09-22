# Security

This document is the **source of truth** for reportTool's security posture: threat model status, security requirements, controls, and trust-boundary enforcement. It does not restate *what* the system does (`REQUIREMENTS.md`), *how it is built* (`ARCHITECTURE.md`), or *how it looks/behaves in the UI* (`DESIGN.md`) — it defines the security rules those documents must be built and verified against.

No implementation exists yet. Nothing below infers a framework, auth mechanism, database, provider, CI/CD system, or regulatory obligation the input documents don't name.

**Markers used throughout:**
- `UNKNOWN` — a fact the input documents do not provide.
- `TO BE DECIDED` — a decision not yet made.
- `ASSUMPTION` — an inference this document makes that is not explicitly stated in an input source. Never treat an `ASSUMPTION` as final.

Security notes supplied alongside this task add constraints but never silently override `REQUIREMENTS.md` or `ARCHITECTURE.md`; material conflicts are recorded under **Open Security Questions**.

---

## Required Security Inputs

| Field | Value |
|---|---|
| Requirements source | REQUIREMENTS.md |
| Design source | DESIGN.md |
| Architecture source | ARCHITECTURE.md |
| System purpose | A platform for a pentest group to run and report on security testing engagements — standardized finding capture/review/CWE-ASVS mapping, multi-customer engagement tracking, structured report generation, fine-grained access control, and safe engagement credential management (REQUIREMENTS.md §1). |
| Application profile | Web application, API monolith. Server: Go, Gin framework (version `UNKNOWN`). Client: React SPA (version `UNKNOWN`). API style: REST/JSON. Data store: RDBMS, normalized to 3NF, product `TO BE DECIDED` (ARCHITECTURE.md Required Architecture Inputs). |
| Users / actors / roles | Pentester (Author), Technical Reviewer, Final Reviewer, Engagement/Project Manager, Admin (REQUIREMENTS.md §2). A read-only Customer/Client persona is `TO BE DECIDED` for v1 (REQUIREMENTS.md §2, §12.1) — see SQ-7. |
| Public interfaces and trust boundaries | Browser Client (React SPA) is untrusted and holds no authoritative access-control or business-rule logic. The Server-side API (Go/Gin) is the edge boundary: TLS terminus, DPoP validation, sole ABAC enforcement point. Uploaded scanner/tool export files are untrusted input parsed by the Import Pipeline, never executed. The Cloud KMS/Secrets Manager is an external, separately-governed trust boundary reached only by the API (ARCHITECTURE.md "Trust boundaries"). |
| Sensitive or regulated data | Live vulnerability data about pentest clients across the full domain hierarchy (customer, department, pentest, finding, finding field, discovered asset, imported artefact) — a high-value target (REQUIREMENTS.md §1, NFR-1). Some finding fields carry client-sensitive evidence or internal-only remediation-cost notes requiring finer-grained visibility than the finding as a whole (REQUIREMENTS.md §3.5, §6.4). Engagement credentials (VPN, scoped test accounts, API keys) (REQUIREMENTS.md §4.5). |
| External integrations | Cloud KMS/Secrets Manager (provider `TO BE DECIDED`). Scanner/tool exports — Burp Suite is the confirmed v1 source; additional tools `TO BE DECIDED` (REQUIREMENTS.md §7, open question 5). Optional AI Review Assist pass, first-party vs. third-party and blocking vs. advisory both `UNKNOWN`/`TO BE DECIDED` (REQUIREMENTS.md FR-11; ARCHITECTURE.md AI Review Assist). |
| Authentication model | WebAuthn passkey is the minimum authenticator for registration and login; YubiKey and smart card (PIV) are supported additional/alternative authenticators. Target assurance level: NIST SP 800-63B-4 AAL3, authentication only — no identity-proofing (IAL) claim made (ARCHITECTURE.md). |
| Authorization model | ABAC scoped at every level of Customer → Department → Pentest → Finding → Finding Field (REQUIREMENTS.md §6). Subject/resource/action/context attributes combine; broader-scope access does not imply narrower-scope access. ABAC engine/standard (OPA/Rego, Cedar, custom) is `TO BE DECIDED` (REQUIREMENTS.md §6.5, open question 4). |
| Session model | Sender-constrained sessions using DPoP-bound JWTs — a bearer token alone is insufficient to use a session (ARCHITECTURE.md). Token/session lifetime and revocation model, and whether AAL3 step-up applies per-action or only at login, are `TO BE DECIDED` (ARCHITECTURE.md Identity & Session Handling). |
| Deployment and CI/CD model | `ASSUMPTION` (carried from ARCHITECTURE.md): "teraformn" is read as Terraform-managed infrastructure-as-code — this is unconfirmed. Target cloud provider(s)/hosting platform is `UNKNOWN`. The architecture note "cloud model enterprise license (review)" is `UNKNOWN` and flagged for human review before any provider/license decision. CI/CD platform is `UNKNOWN`. |
| Applicable privacy or regulatory obligations | `TO BE DECIDED`. No jurisdiction, data-residency requirement, or compliance regime (GDPR, HIPAA, PCI DSS, SOC 2, ISO 27001) is stated in any input document (REQUIREMENTS.md §10, open question 9) — none is assumed here. See SQ-8. |
| Security assurance target | TO BE DECIDED |
| Security verification reference | OWASP ASVS 5.0.0 |
| Threat model status | TO BE DECIDED |

If `ARCHITECTURE.md` identifies a web application but leaves the client/server integration model unresolved: not applicable here — REST is confirmed (ARCHITECTURE.md Required Architecture Inputs) — but API exposure beyond the SPA (a separately consumable public API) is not stated and is not assumed.

---

## Selected Security References and Prompt Imports

No local secure-coding prompt library was found in this execution environment (checked common locations under the user's home directory and Claude Code configuration paths; nothing matching a project-scoped prompt library was present). The authoritative public references below were selected and read, filtered to what the confirmed stack (Go/Gin REST API, React SPA, RDBMS/3NF, WebAuthn passkey + DPoP-bound sessions, Terraform `ASSUMPTION`) actually needs.

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

`REF-FIDO` and `REF-WEBAUTHN` are included because passkeys are explicitly selected as the minimum authenticator in `ARCHITECTURE.md`, not merely because the auth model was unknown. GraphQL/gRPC/WebSocket-specific guidance was not selected: the API style is confirmed REST.

---

## Provisional Security Rules

### Trust boundaries and server-side enforcement

- **SEC-TRUST-1** The Server-side API MUST be the sole enforcement point for authentication, authorization, and business-rule decisions. The Browser Client MUST NOT be relied upon to enforce access control or hide unauthorized data/actions — any client-side check is a UX convenience only.
  - **Applies to:** All REST endpoints
  - **Verification:** Automated tests calling API endpoints directly (bypassing the SPA) with under-privileged and over-privileged identities, confirming enforcement holds independent of what the client would have shown
  - **References:** `REF-ASVS-5`, `REF-API-2023`
  - **Status:** CONFIRMED (ARCHITECTURE.md DR-1, DR-6)

- **SEC-TRUST-2** Uploaded scanner/tool export files MUST be treated as untrusted input, parsed only by a dedicated per-format parser, and MUST NOT be executed or interpreted as code at any stage of import.
  - **Applies to:** Import Pipeline
  - **Verification:** A malformed/adversarial-file test corpus per supported format; confirm parser failure rejects rather than executes or passes through unparsed content
  - **References:** `REF-INPUTVAL`, `REF-ASVS-5`
  - **Status:** CONFIRMED (ARCHITECTURE.md "Trust boundaries", DR-4; REQUIREMENTS.md §7)

### Authentication

- **SEC-AUTHN-1** The system MUST require a WebAuthn passkey ceremony as the minimum authenticator factor for registration and login; YubiKey and smart-card (PIV) MAY be offered as additional/alternative authenticators. Password-only or password-as-sole-fallback authentication MUST NOT be introduced without an explicit decision superseding this rule.
  - **Applies to:** Identity & Session Handling; all human actors (REQUIREMENTS.md §2)
  - **Verification:** Attempt registration/login without a WebAuthn ceremony and confirm rejection
  - **References:** `REF-WEBAUTHN`, `REF-FIDO`, `REF-AUTH`
  - **Status:** CONFIRMED (ARCHITECTURE.md "Authentication")

- **SEC-AUTHN-2** The authentication implementation MUST target NIST SP 800-63B-4 AAL3 (authentication only; no identity-proofing/IAL claim).
  - **Verification:** Review of the authenticator registration flow against AAL3 criteria (hardware-backed authenticator, verifier-impersonation-resistant protocol)
  - **References:** `REF-63B`, `REF-WEBAUTHN`
  - **Status:** CONFIRMED (ARCHITECTURE.md "Authentication")

- **SEC-AUTHN-3** `TO BE DECIDED`: whether AAL3 step-up is required per sensitive action or only at login (ARCHITECTURE.md open decision). Until decided, sensitive operations — credential retrieval, ABAC policy changes, Final Review approval — SHOULD require a fresh authentication ceremony as a provisional default.
  - **Applies to:** Server-side API, sensitive state-changing endpoints
  - **Verification:** TO BE DECIDED pending the step-up policy decision
  - **References:** `REF-AUTH`, `REF-63B`
  - **Status:** TO BE DECIDED (SQ-3)

### Session management

- **SEC-SESSION-1** Sessions MUST be sender-constrained using DPoP-bound JWTs. The API MUST reject any bearer token presented without a valid DPoP proof bound to the same key and matching HTTP method/URI.
  - **Verification:** Replay a captured bearer token with a missing, mismatched, or reused DPoP proof and confirm rejection
  - **References:** `REF-SESSION`, `REF-AUTH`
  - **Status:** CONFIRMED (ARCHITECTURE.md "Session")

- **SEC-SESSION-2** `TO BE DECIDED`: token/session lifetime and revocation model (ARCHITECTURE.md open decision). Until decided, the provisional default is short-lived access tokens with a server-side revocation capability; long-lived, unrevocable bearer tokens MUST NOT be issued.
  - **Verification:** TO BE DECIDED
  - **References:** `REF-SESSION`
  - **Status:** TO BE DECIDED (SQ-3)

### Authorization (ABAC)

- **SEC-AUTHZ-1** The Server-side API MUST verify, for every request, that the authenticated actor is authorized for the requested action against the specific customer, department, pentest, finding, and finding field targeted, before performing the operation or returning data. Default MUST be deny.
  - **Applies to:** All reads/writes across the domain hierarchy
  - **Verification:** Automated ABAC test suite exercising permitted and prohibited subject/resource/action/context combinations at each scope level, including field-level denial within an otherwise-permitted finding
  - **References:** `REF-ASVS-5`, `REF-API-2023`
  - **Status:** CONFIRMED (REQUIREMENTS.md FR-13, FR-14, FR-15, §6; ARCHITECTURE.md DR-6)

- **SEC-AUTHZ-2** A grant of access at a broader scope MUST NOT be interpreted as implying access to a narrower-scope resource that a narrower-scope policy further restricts.
  - **Verification:** Regression test asserting pentest-level allow plus field-level deny yields deny for that field
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED (REQUIREMENTS.md §6.3)

- **SEC-AUTHZ-3** Granting reviewer rights (technical or final) on a pentest or finding MUST itself be an authorized, audited action — only actors already holding assignment rights may grant them to others.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED (REQUIREMENTS.md FR-15)

- **SEC-AUTHZ-4** `TO BE DECIDED`: the ABAC engine/policy model (OPA/Rego, Cedar, or custom). Regardless of the eventual choice, policy evaluation MUST occur only within the single server-side ABAC decision point; no component may implement a parallel or shortcut authorization check.
  - **References:** `REF-ASVS-5`
  - **Status:** TO BE DECIDED (SQ-1; ARCHITECTURE.md DR-6)

- **SEC-AUTHZ-5** The Report Engine MUST invoke the same ABAC decision point used for interactive reads, evaluated per finding/field for the specific recipient, when generating a report — it MUST NOT reimplement authorization logic.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED (REQUIREMENTS.md FR-24, §8.4; ARCHITECTURE.md Report Engine, DR-6)

### HTTP/API boundaries

- **SEC-HTTP-1** All client-server communication MUST occur over TLS. The API MUST NOT accept plaintext HTTP for any authenticated or credential-bearing request.
  - **References:** `REF-REST`, `REF-ASVS-5`
  - **Status:** CONFIRMED (ARCHITECTURE.md system context — "HTTPS")

- **SEC-HTTP-2** The API MUST validate that each DPoP proof's HTTP method and URI match the request it accompanies, rejecting mismatches.
  - **References:** `REF-SESSION`, `REF-REST`
  - **Status:** CONFIRMED (ARCHITECTURE.md system context)

- **SEC-HTTP-3** `TO BE DECIDED`: whether cross-origin access is required (UNKNOWN — a single first-party SPA origin is assumed but not confirmed). If required, CORS MUST use an explicit allow-list and MUST NOT combine a wildcard origin with credentialed requests. Until decided, cross-origin requests SHOULD be rejected by default.
  - **References:** `REF-REST`
  - **Status:** TO BE DECIDED

### Input validation

- **SEC-INPUT-1** All data crossing the trust boundary into the Server-side API — REST request bodies, query parameters, and imported artefact files — MUST be validated for both format/type and business-rule meaning (e.g., a well-formed CWE identifier, a well-formed ASVS control identifier, an allowed severity value) before being persisted or acted upon.
  - **References:** `REF-INPUTVAL`, `REF-ASVS-5`
  - **Status:** CONFIRMED (REQUIREMENTS.md FR-3, FR-4, §7.2)

### Output encoding and safe rendering

- **SEC-OUTPUT-1** The React SPA MUST render server-supplied and user-supplied content (finding text, evidence, imported artefact content) using framework-provided safe rendering. Raw HTML/DOM injection interfaces for untrusted content MUST NOT be used.
  - **References:** `REF-XSS`
  - **Status:** CONFIRMED (ARCHITECTURE.md Browser Client; REQUIREMENTS.md §3.4 evidence field)

### Data protection and privacy

- **SEC-DATA-1** Field-level access restrictions (REQUIREMENTS.md §3.5, §6.4) MUST be enforced by the API on every read path that can expose finding-field data, including list, bulk, search, and export/report endpoints — not only single-record reads.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED (REQUIREMENTS.md NFR-1, §3.5, §6.4)

- **SEC-DATA-2** The system MUST NOT assume GDPR, HIPAA, PCI DSS, SOC 2, ISO 27001, or any other compliance regime applies. Jurisdiction and applicable obligations are `TO BE DECIDED`.
  - **Status:** TO BE DECIDED (SQ-8; REQUIREMENTS.md §10, open question 9)

### Secrets and keys

- **SEC-SECRETS-1** Engagement credentials MUST be stored only via the Cloud KMS/Secrets Manager boundary. The RDBMS MUST NOT persist credential secret material in plaintext. The Server-side API MUST be the only component permitted to call the KMS boundary.
  - **References:** `REF-SECRETS`, `REF-ASVS-5`
  - **Status:** CONFIRMED (REQUIREMENTS.md FR-16, FR-17, NFR-3; ARCHITECTURE.md DR-3)

- **SEC-SECRETS-2** Decrypted credential material MUST NOT be returned to the Browser Client except as the specific, ABAC-approved output of the request that required it, and MUST NOT appear in application or audit logs.
  - **References:** `REF-SECRETS`, `REF-LOGGING`
  - **Status:** CONFIRMED (REQUIREMENTS.md NFR-3; ARCHITECTURE.md Secrets/KMS Boundary)

- **SEC-SECRETS-3** Access to a given engagement's credentials MUST be governed by the same ABAC model used for findings and reports — no separate or weaker authorization path for credential retrieval.
  - **References:** `REF-ASVS-5`
  - **Status:** CONFIRMED (REQUIREMENTS.md FR-18)

### Logging and error handling

- **SEC-LOG-1** Access to and changes in findings, credentials, and ABAC policy MUST be fully audit-logged (who, when, what changed). Audit and diagnostic logs MUST NOT contain credential secret material, passkey/authenticator private-key material, or DPoP private-key material.
  - **References:** `REF-LOGGING`
  - **Status:** CONFIRMED (REQUIREMENTS.md NFR-2, NFR-3, FR-12)

- **SEC-LOG-2** Error responses returned to the Browser Client MUST NOT expose internal implementation details (stack traces, raw SQL, internal-only identifiers). Detailed diagnostics MUST be retained server-side only.
  - **References:** `REF-ERROR`
  - **Status:** CONFIRMED (general safe default; not contradicted by any input document)

### External integrations

- **SEC-INTEG-1** When the optional AI Review Assist pass is enabled, its output MUST be treated as advisory/non-authoritative input to the human review workflow. It MUST NOT itself grant, deny, or bypass an ABAC decision or a finding lifecycle transition, unless REQUIREMENTS.md FR-11 is explicitly resolved to make it blocking.
  - **References:** `REF-ASVS-5`
  - **Status:** TO BE DECIDED (SQ-2; REQUIREMENTS.md FR-11)

- **SEC-INTEG-2** `TO BE DECIDED`: whether AI Review Assist is a first-party or third-party/external service is `UNKNOWN`. If it is external, data sent to it MUST be scoped to only the finding data required for the review pass, consistent with the requesting actor's ABAC scope.
  - **Status:** TO BE DECIDED (SQ-2)

### CI/CD and deployment

- **SEC-DEPLOY-1** If infrastructure provisioning uses Terraform (per the `ASSUMPTION` in ARCHITECTURE.md — unconfirmed), state files and any embedded secrets MUST be kept out of source control and out of application/build logs. This rule is conditional on that assumption being confirmed.
  - **References:** `REF-IAC`, `REF-SSDF`
  - **Status:** ASSUMPTION-dependent (SQ-11; ARCHITECTURE.md Deployment model)

- **SEC-DEPLOY-2** CI/CD pipelines MUST follow NIST SSDF 1.1 build-integrity practices — least-privilege pipeline credentials, no plaintext secrets in pipeline configuration. The specific CI/CD platform is `UNKNOWN`.
  - **References:** `REF-SSDF`, `REF-CICD`
  - **Status:** TO BE DECIDED (SQ-11)

---

## Requirement and Architecture Traceability

| Rule(s) | Requirement(s) | Component(s) | Status |
|---|---|---|---|
| SEC-TRUST-1 | §6, FR-13–FR-15 | Server-side API, Browser Client | CONFIRMED |
| SEC-TRUST-2 | §7 | Import Pipeline | CONFIRMED |
| SEC-AUTHN-1, SEC-AUTHN-2 | §2 (actors) | Identity & Session Handling | CONFIRMED |
| SEC-AUTHN-3 | — | Identity & Session Handling | TO BE DECIDED |
| SEC-SESSION-1 | — (architecture note) | Identity & Session Handling | CONFIRMED |
| SEC-SESSION-2 | — | Identity & Session Handling | TO BE DECIDED |
| SEC-AUTHZ-1, SEC-AUTHZ-2 | FR-13, FR-14, §6.1, §6.3 | Server-side API (ABAC decision point) | CONFIRMED |
| SEC-AUTHZ-3 | FR-15 | Server-side API | CONFIRMED |
| SEC-AUTHZ-4 | §6.5 (open question 4) | ABAC Decision | TO BE DECIDED |
| SEC-AUTHZ-5 | FR-24, §8.4 | Report Engine | CONFIRMED |
| SEC-HTTP-1, SEC-HTTP-2 | — (architecture note) | Server-side API | CONFIRMED |
| SEC-HTTP-3 | — | Server-side API | TO BE DECIDED |
| SEC-INPUT-1 | FR-3, FR-4, §7.2 | Server-side API, Import Pipeline | CONFIRMED |
| SEC-OUTPUT-1 | §3.4 | Browser Client | CONFIRMED |
| SEC-DATA-1 | NFR-1, §3.5, §6.4 | Server-side API, Report Engine | CONFIRMED |
| SEC-DATA-2 | §10 (open question 9) | — | TO BE DECIDED |
| SEC-SECRETS-1, SEC-SECRETS-2, SEC-SECRETS-3 | FR-16, FR-17, FR-18, NFR-3 | Secrets/Cloud KMS Boundary, Server-side API | CONFIRMED |
| SEC-LOG-1 | NFR-2, NFR-3, FR-12 | Server-side API | CONFIRMED |
| SEC-LOG-2 | — | Server-side API | CONFIRMED |
| SEC-INTEG-1, SEC-INTEG-2 | FR-11 | AI Review Assist (OPEN) | TO BE DECIDED |
| SEC-DEPLOY-1 | — | Deployment (ASSUMPTION: Terraform) | PARTIALLY DEFINED |
| SEC-DEPLOY-2 | — | CI/CD (UNKNOWN) | TO BE DECIDED |

---

## Dependency Security Rules

These are prospective rules for future implementation; no dependency has been assessed because no implementation exists yet. They apply once the Go/Gin backend and React frontend begin adding dependencies, and to any Terraform modules if that deployment assumption is confirmed. Relevant references: `REF-DEPMGMT`, `REF-SUPPLYCHAIN`, `REF-IAC`.

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
- `{{API_SECURITY_PROMPT}}` — **RESOLVED**: an API exists and its style is confirmed REST — `REF-API-2023` (OWASP API Security Top 10 2023) plus `REF-REST` (OWASP REST Security Cheat Sheet).
- `{{BACKEND_FRAMEWORK_PROMPT}}` — **PARTIALLY RESOLVED**: the backend framework (Go, Gin) is named, but no version is given, so no version-specific official documentation can be cited per the resolution rule. Framework version: `TO BE DECIDED`.
- `{{FRONTEND_FRAMEWORK_PROMPT}}` — **PARTIALLY RESOLVED**: the frontend framework (React) is named, but no version is given. `REF-XSS` serves as a framework-neutral rendering baseline (SEC-OUTPUT-1) but does not itself resolve this placeholder. Framework version: `TO BE DECIDED`.
- `{{AUTH_PROMPT}}` — **RESOLVED**: the auth and session model is identified (WebAuthn passkey minimum, YubiKey/PIV additional, DPoP-bound sessions, AAL3 target) — `REF-WEBAUTHN`, `REF-FIDO`, `REF-AUTH`, `REF-SESSION`, `REF-63B`.
- `{{DEPLOYMENT_PROMPT}}` — **PARTIALLY RESOLVED**: `REF-SSDF` and `REF-CICD` apply unconditionally. `REF-IAC` applies only if the Terraform `ASSUMPTION` is confirmed. Cloud provider/platform-specific guidance is `TO BE DECIDED` (provider `UNKNOWN`).

---

## Open Security Questions

- **SQ-1** Which ABAC engine/standard will be used — OPA/Rego, Cedar, or a custom policy model? (REQUIREMENTS.md §6.5, open question 4)
- **SQ-2** What exactly does the AI Review Assist pass check, is it blocking or advisory, and is it a first-party or third-party/external service (data-exposure implications for finding data sent to it)? (REQUIREMENTS.md FR-11)
- **SQ-3** What is the session/access-token lifetime and revocation model, and is AAL3 step-up authentication required per sensitive action or only at login? (ARCHITECTURE.md Identity & Session Handling)
- **SQ-4** Which cloud provider(s) will back the KMS/Secrets Manager — a single provider or an abstraction layer across several — and what does the architecture note "cloud model enterprise license (review)" mean procedurally? (REQUIREMENTS.md §9, open question 7; ARCHITECTURE.md Secrets/Cloud KMS Boundary)
- **SQ-5** Which scanners/tools beyond Burp Suite are in scope for v1 import, and what per-format parser trust/validation requirements do they introduce? (REQUIREMENTS.md §7, open question 5)
- **SQ-6** What report output format(s) are required (PDF, DOCX, both), and is there an in-app preview before export? This affects what artifact-generation and delivery controls are needed. (REQUIREMENTS.md §8, open question 6)
- **SQ-7** Is a read-only customer/client portal in scope for v1? This would introduce a new, lower-trust external actor requiring its own ABAC scope and additions to the threat model. (REQUIREMENTS.md §2, §11, §12.1)
- **SQ-8** What compliance or data-residency obligations apply (e.g., SOC 2, ISO 27001, a specific jurisdiction's privacy law)? None is currently assumed. (REQUIREMENTS.md §10, open question 9)
- **SQ-9** Can a finding skip technical review (e.g., for low-severity/informational items), and is there a "rejected" terminal lifecycle state? Each affects the ABAC and audit-trail rules that apply at that transition. (REQUIREMENTS.md §5)
- **SQ-10** What is the specific RDBMS product and the target cloud provider(s)/hosting platform? Needed before platform-specific hardening guidance can be selected. (ARCHITECTURE.md Data Persistence, Required Architecture Inputs)
- **SQ-11** Is Terraform actually the intended IaC tool, or was "teraformn" in the architecture notes a typo for something else? What CI/CD platform will be used? (ARCHITECTURE.md Deployment model, `ASSUMPTION`)
- **SQ-12** What is the security assurance target and threat-modeling methodology/cadence (e.g., STRIDE, at what lifecycle points)? Not specified by any input document.
- **SQ-13** Is a passkey/authenticator recovery flow defined for a user who loses their only registered authenticator? This is a common AAL3 operational gap not addressed by any input document.

---

*Changes to this document should be made deliberately. When a requirement or architecture decision changes, update `REQUIREMENTS.md` or `ARCHITECTURE.md` first, then reflect the consequence here.*
