# reporTool

**A platform for running and reporting pentest engagements** — built by pentesters, for pentesters.

reporTool replaces the usual pile of spreadsheets, Word templates, and copy-pasted Burp exports with a single system for organizing engagements, standardizing findings, and generating client-ready reports.

## Why

Pentest teams juggle many customers, each with multiple departments and engagements, each engagement generating dozens of findings that need to be triaged, reviewed, mapped to standards, and eventually turned into a report. Today that's mostly manual and mostly miserable. reporTool aims to make the finding-to-report pipeline fast, consistent, and access-controlled.

## Core features

### Engagement & finding management
- Organize work into customers → departments → pentests → findings
- Report individual security findings in a standardized testing artefact log
- Map findings to **CWE** identifiers
- Link findings to **OWASP ASVS** controls
- Report on discovered assets (IPs, domains, cloud accounts, etc.) for inclusion in reports
- Import findings from Burp Suite and other scanner/tool exports

### Review workflow
- Finding lifecycle: **author → technical review → final review**
- Access-controlled reviewer assignment
- Optional AI-assisted review pass before findings go to human peer review

### Access control
- **ABAC** (attribute-based access control) enforced at the customer, department, pentest, finding, and individual finding-field level

### Secrets & credential management
- KMS/secrets-backed storage for engagement credentials
- Per-project credential isolation, using cloud-native KMS/secrets management

### Data import & testing artefacts
- Import analyst work logs (e.g. Burp logs) into a structured, standardized format
- Automated, timestamped notes generated from tool output
- Standardized artefact types (access requirements, scope notes, etc.)

### Report engine
- First-class report generation, not an afterthought
- Upload and modify baseline report templates
- Access-control-aware templates (reviewers/clients see only what they're entitled to)
- Customer and team logo/branding support

## Architecture (planned)

- **API + web app** — client/server split, RDBMS-backed
- **RDBMS** for engagements, findings, users, and access control state
- **Cloud KMS / Secrets Manager** integration for engagement credentials
- Pluggable importers for scanner/tool output (starting with Burp Suite)

## Status

Early planning stage — architecture and data model are still being designed. Contributions, ideas, and issue discussion are welcome.

## License

TBD.
