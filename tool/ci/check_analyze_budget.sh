#!/usr/bin/env bash
# Enforce a maximum number of static analysis issues.
# Usage: bash tool/ci/check_analyze_budget.sh [MAX_ISSUES]
set -euo pipefail

MAX_ISSUES=${1:-100}

OUTPUT=$(flutter analyze --no-fatal-infos 2>&1 || true)

# Count info + warning lines (each issue has " • " separator)
ISSUE_COUNT=$(echo "$OUTPUT" | grep -cE '(info|warning) •' || true)
ISSUE_COUNT=${ISSUE_COUNT:-0}

echo "Static analysis: $ISSUE_COUNT issues (budget: $MAX_ISSUES)"

if [ "$ISSUE_COUNT" -gt "$MAX_ISSUES" ]; then
  echo "::error::Analysis budget exceeded: $ISSUE_COUNT > $MAX_ISSUES"
  echo "$OUTPUT" | grep -E '(info|warning) •' | tail -20
  exit 1
fi

# Still fail on actual errors
ERROR_COUNT=$(echo "$OUTPUT" | grep -cE 'error •' || true)
ERROR_COUNT=${ERROR_COUNT:-0}
if [ "$ERROR_COUNT" -gt 0 ]; then
  echo "::error::Found $ERROR_COUNT analysis errors"
  echo "$OUTPUT" | grep -E 'error •'
  exit 1
fi

echo "Analysis budget OK ($ISSUE_COUNT/$MAX_ISSUES)"
