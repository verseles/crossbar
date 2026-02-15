#!/usr/bin/env bash
# Enforce minimum test coverage threshold.
# Usage: bash tool/ci/check_coverage.sh [MIN_COVERAGE] [LCOV_FILE]
set -euo pipefail

MIN_COVERAGE=${1:-35}
LCOV_FILE=${2:-coverage/lcov.info}

if [ ! -f "$LCOV_FILE" ]; then
  echo "::error::Coverage file not found: $LCOV_FILE"
  exit 1
fi

# Filter generated code
lcov --remove "$LCOV_FILE" \
  'lib/l10n/*' \
  'lib/ui/dialogs/*' \
  'lib/core/paths/*' \
  '*.g.dart' \
  '**/generated_plugin_registrant.dart' \
  -o coverage/lcov_filtered.info \
  --ignore-errors unused 2>/dev/null

COVERAGE=$(lcov --summary coverage/lcov_filtered.info 2>/dev/null | grep "lines" | grep -oP '\d+\.\d+(?=%)' || echo "0")

echo "Coverage: ${COVERAGE}% (minimum: ${MIN_COVERAGE}%)"

if (( $(echo "$COVERAGE < $MIN_COVERAGE" | bc -l) )); then
  echo "::error::Coverage ${COVERAGE}% is below minimum threshold of ${MIN_COVERAGE}%"
  exit 1
fi

echo "Coverage threshold met"
