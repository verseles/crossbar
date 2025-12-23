#!/bin/bash
# system-info.1m.sh

echo "ℹ️ System Info"
echo "---"
echo "OS: $(uname -s)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime | sed 's/.*up \([^,]*\), .*/\1/')"
echo "---"
echo "Refresh | refresh=true"
