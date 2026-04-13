#!/bin/bash
set -euo pipefail

input=$(cat)
target=$(echo "$input" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tip = data.get('tool_input', {})
print(tip.get('command') or tip.get('file_path') or tip.get('path', ''))
")

# .env.example is always allowed
if echo "$target" | grep -qiE '\.env\.example'; then
  exit 0
fi

patterns=(
  '\.env($|[^a-zA-Z])'
  '[/]\.ssh[/]'
  '_rsa(\s|$)'
  '_ed25519'
  '_ecdsa'
  '_dsa(\s|$)'
  '\.pem(\s|$)'
  'secrets?\.ya?ml'
  'secret[-_][a-z]'
)

for pattern in "${patterns[@]}"; do
  if echo "$target" | grep -qiE "$pattern"; then
    echo "Bloccato: accesso a file sensibili (pattern: $pattern)"
    exit 2
  fi
done
