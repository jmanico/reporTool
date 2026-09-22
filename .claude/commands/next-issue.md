---
description: Implement one GitHub issue end to end against reporTool's specs, with spec/security review and a PR.
argument-hint: <issue-number>
---

Run GitHub issue `$1` end to end.

1. Fetch the issue body (`gh issue view $1`). It follows `REQUIREMENT_TEMPLATE.md`'s structure — use its **Architecture Traceability**, **Security Traceability**, and **Acceptance Criteria** fields to find exactly which sections of `REQUIREMENTS.md`, `ARCHITECTURE.md`, and `SECURITY.md` govern this issue. Read only those cited sections, not the full documents, unless a cited section itself points elsewhere.
2. Plan the implementation against what you just read. Do not implement behavior the issue's requirement doesn't ask for.
3. Turn each Acceptance Criterion from the issue into a failing test before writing any implementation code.
4. Implement until the tests pass.
5. Invoke the `spec-auditor` and `security-reviewer` subagents on the resulting diff. Address any findings they report before proceeding; re-invoke them after fixes if the diff changed materially.
6. Open a pull request referencing issue `$1` (e.g. `Closes #$1` in the description).
