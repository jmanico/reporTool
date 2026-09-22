#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash).
# Refuses destructive command patterns at the shell-string level. This
# overlaps .claude/settings.json's permission deny rules on purpose: those
# stop the tool call, this stops the shell string that slipped past a
# pattern (e.g. wrapped in a subshell or string concatenation).
# Not traceable to a reporTool spec rule (no implementation exists yet to
# protect) — this enforces the harness's own general destructive-action
# guidance, kept here so it applies from day one rather than being added
# later once SECURITY.md/ARCHITECTURE.md name a concrete deployment to harm.
set -euo pipefail

input="$(cat)"

cmd="$(printf '%s' "$input" | grep -o '"command"[[:space:]]*:[[:space:]]*"\([^"\\]\|\\.\)*"' | head -n1 | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//')"

if [[ -z "$cmd" ]]; then
  exit 0
fi

patterns=(
  'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f'
  'rm[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*r'
  'git[[:space:]]+push[[:space:]]+.*--force'
  'git[[:space:]]+push[[:space:]]+.*-f([[:space:]]|$)'
  'git[[:space:]]+reset[[:space:]]+--hard'
  'git[[:space:]]+clean[[:space:]]+.*-[a-zA-Z]*f'
  'git[[:space:]]+.*--no-verify'
  'git[[:space:]]+.*-c[[:space:]]+commit\.gpgsign=false'
  'git[[:space:]]+branch[[:space:]]+.*-D'
  '>[[:space:]]*/dev/sd'
  'mkfs\.'
  'dd[[:space:]]+.*of=/dev/'
  ':\(\)[[:space:]]*\{.*\};[[:space:]]*:'
  'chmod[[:space:]]+-R[[:space:]]+777'
  'curl[[:space:]]+.*\|[[:space:]]*(sudo[[:space:]]+)?(sh|bash)'
  'wget[[:space:]]+.*\|[[:space:]]*(sudo[[:space:]]+)?(sh|bash)'
)

for pat in "${patterns[@]}"; do
  if [[ "$cmd" =~ $pat ]]; then
    echo "Blocked: command matches a destructive pattern ($pat). If this is intentional, run it outside Claude Code." >&2
    exit 2
  fi
done

exit 0
