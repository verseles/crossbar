#!/bin/bash
# Network Status
# Shows connection status and IP

ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    status="Online"
    icon=""
    color="green"
else
    status="Offline"
    icon=""
    color="red"
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "N/A")
else
    ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "N/A")
fi

echo "$icon $status | color=$color"
echo "---"
echo "Status: $status"
echo "Local IP: $ip"
echo "---"
echo "Copy IP | bash='echo $ip | pbcopy' terminal=false"
echo "Open Network Preferences | bash='open /System/Library/PreferencePanes/Network.prefPane' terminal=false"
echo "Refresh | refresh=true"
