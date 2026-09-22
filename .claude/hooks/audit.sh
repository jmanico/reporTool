#!/usr/bin/env bash
# PostToolUse hook (all tools).
# Appends one JSON line per tool call: timestamp, session ID, tool name, and
# the command or file path. Observe only — always exits 0.
# NFR-2: "Full audit logging of access and changes ... given the sensitivity
# of the data." SEC-LOG-1/SEC-LOG-2: audit logs MUST NOT contain credential,
# authenticator-key, or DPoP-key material, and MUST NOT expose internal
# diagnostics — this log records only tool name and the command/path, never
# tool output or file contents.
set +e

input="$(cat)"

log_dir="${CLAUDE_PROJECT_DIR:-.}/.claude"
log_file="$log_dir/audit.log"
mkdir -p "$log_dir" 2>/dev/null

session_id="$(printf '%s' "$input" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"
tool_name="$(printf '%s' "$input" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"
command="$(printf '%s' "$input" | grep -o '"command"[[:space:]]*:[[:space:]]*"\([^"\\]\|\\.\)*"' | head -n1 | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//')"
file_path="$(printf '%s' "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"

target="${command:-${file_path:-}}"
target="${target//\"/\\\"}"
timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

printf '{"timestamp":"%s","session_id":"%s","tool_name":"%s","target":"%s"}\n' \
  "$timestamp" "${session_id:-unknown}" "${tool_name:-unknown}" "$target" >> "$log_file" 2>/dev/null

exit 0
