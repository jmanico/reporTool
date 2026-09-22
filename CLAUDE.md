# reporTool

reporTool is a web and API platform for a pentest group to run and report on security testing engagements: standardized finding capture with CWE/ASVS mapping, multi-customer engagement tracking, ABAC-controlled access down to the individual finding field, and client-ready report generation. No implementation exists yet — `REQUIREMENTS.md`, `DESIGN.md`, `ARCHITECTURE.md`, and `SECURITY.md` are the full specification.

## Spec files — read before changing anything they own

- `REQUIREMENTS.md` — WHAT the system does. Read before changing observable behavior.
- `DESIGN.md` — the design language (`style-guide.html` is its rendered reference). Read before UI work.
- `ARCHITECTURE.md` — components, boundaries, data flow, dependency rules. Read before structural changes.
- `SECURITY.md` — security rules and threat model. Read before touching auth, input handling, data protection, or any trust boundary.
- `REQUIREMENT_TEMPLATE.md` — required structure for new GitHub issues.

## Rules

- Every new GitHub issue MUST follow the structure in `REQUIREMENT_TEMPLATE.md`, so each issue is a structured, testable requirement.

## Build, test, run

TO BE DECIDED — no implementation exists yet.
