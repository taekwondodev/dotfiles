#!/usr/bin/env bash

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "SessionStart: invoke the caveman skill now via the Skill tool (skill: caveman), before responding to any user message. Use default level (full) unless user specifies otherwise."
  }
}
EOF

exit 0
