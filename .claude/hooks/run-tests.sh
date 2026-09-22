#!/usr/bin/env bash
# Stop hook.
# Runs the project's test suite so a turn does not end on a red build.
# CLAUDE.md: "Build, test, run — TO BE DECIDED — no implementation exists yet."
set -euo pipefail

cat >&2 <<'EOF'
run-tests.sh: TO BE DECIDED — no implementation, dependency manager, or test
runner exists yet (CLAUDE.md "Build, test, run"). Once a backend (Go/Gin) or
frontend (React) test command is chosen, replace this script with the real
invocation, e.g.:
  go test ./...
  npm test / npx jest / npx vitest
and exit 2 with the failure output when the suite fails.
EOF

exit 0
