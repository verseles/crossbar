#!/bin/bash
# github-notifications.5m.sh

TOKEN="${GITHUB_TOKEN}"

if [ -z "$TOKEN" ]; then
    echo "? | color=gray"
    echo "---"
    echo "Error: GITHUB_TOKEN not set"
    exit 0
fi

COUNT=$(curl -s -H "Authorization: token $TOKEN" https://api.github.com/notifications | grep -c "id")

COLOR="blue"
[ "$COUNT" -eq 0 ] && COLOR="gray"

echo "$COUNT | color=$COLOR"
echo "---"
echo "$COUNT unread notifications"
echo "---"
echo "Open GitHub | href=https://github.com/notifications"
echo "Refresh | refresh=true"
