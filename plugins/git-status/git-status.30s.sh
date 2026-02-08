#!/bin/bash
# git-status.30s.sh

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo " Not a repo"
    echo "---"
    echo "Not inside a git repository"
    echo "Refresh | refresh=true"
    exit 0
fi

BRANCH=$(git branch --show-current)
STATUS=$(git status --porcelain)
CHANGES=$(echo "$STATUS" | grep -c .)

COLOR="green"
[ "$CHANGES" -gt 0 ] && COLOR="orange"

echo " $BRANCH | color=$COLOR"
echo "---"
echo "Branch: $BRANCH"
echo "---"

if [ "$CHANGES" -gt 0 ]; then
    echo "Changes: $CHANGES"
    echo "---"
    echo "$STATUS" | head -n 10
    REMAINING=$((CHANGES - 10))
    if [ $REMAINING -gt 0 ]; then
        echo "...and $REMAINING more files"
    fi
else
    echo "Working tree clean"
fi

echo "---"
echo "Refresh | refresh=true"
