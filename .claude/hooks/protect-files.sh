#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit).
# Refuses edits to files SECURITY.md treats as sensitive: credential/key
# material and .env files (SEC-SECRETS-1..4; project .gitignore "Environment
# / secrets" section), and Terraform state (SEC-DEPLOY-1: "Terraform state
# files and any embedded secrets MUST be kept out of source control").
set -euo pipefail

input="$(cat)"

path="$(printf '%s' "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"

if [[ -z "$path" ]]; then
  exit 0
fi

base="$(basename -- "$path")"

# Credentials / key material / env files (mirrors .gitignore's
# "Environment / secrets" section) plus Terraform state (SEC-DEPLOY-1).
patterns=(
  '\.env$'
  '\.env\.'
  '\.pem$'
  '\.key$'
  '\.p12$'
  '\.pfx$'
  '^id_rsa'
  '^id_ecdsa'
  '^id_ed25519'
  'credentials\.json$'
  'credentials$'
  '\.tfstate$'
  '\.tfstate\.'
  '\.tfvars$'
)

for pat in "${patterns[@]}"; do
  if [[ "$base" =~ $pat ]] || [[ "$path" =~ $pat ]]; then
    echo "Blocked: '$path' matches a restricted pattern ($pat) — credential/key material, .env, or Terraform state per SECURITY.md SEC-SECRETS-1..4 / SEC-DEPLOY-1. Edit it outside Claude Code if this is intentional." >&2
    exit 2
  fi
done

exit 0
