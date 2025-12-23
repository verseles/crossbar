#!/bin/bash
# todo.1m.sh

TODO_FILE="$HOME/.crossbar/todo.txt"
touch "$TODO_FILE"

COUNT=$(wc -l < "$TODO_FILE" | tr -d ' ')

echo " $COUNT"
echo "---"

if [ "$COUNT" -gt 0 ]; then
    cat "$TODO_FILE"
else
    echo "No pending tasks"
fi

echo "---"
echo "Edit | bash='open $TODO_FILE' terminal=false"
echo "Refresh | refresh=true"
