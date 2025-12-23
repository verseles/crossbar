#!/bin/bash
# pomodoro.1s.sh
# Simple file-based Pomodoro for Bash

STATE_FILE="/tmp/crossbar_pomodoro.state"
WORK_MINS=25
BREAK_MINS=5

# Helper to read state
read_state() {
    if [ -f "$STATE_FILE" ]; then
        source "$STATE_FILE"
    else
        RUNNING=false
        START_TIME=0
        IS_BREAK=false
        COMPLETED=0
    fi
}

# Helper to write state
write_state() {
    echo "RUNNING=$RUNNING" > "$STATE_FILE"
    echo "START_TIME=$START_TIME" >> "$STATE_FILE"
    echo "IS_BREAK=$IS_BREAK" >> "$STATE_FILE"
    echo "COMPLETED=$COMPLETED" >> "$STATE_FILE"
}

# Handle Arguments (Actions)
if [ "$1" == "start_work" ]; then
    read_state
    RUNNING=true
    IS_BREAK=false
    START_TIME=$(date +%s)
    write_state
    exit 0
elif [ "$1" == "start_break" ]; then
    read_state
    RUNNING=true
    IS_BREAK=true
    START_TIME=$(date +%s)
    write_state
    exit 0
elif [ "$1" == "stop" ]; then
    read_state
    RUNNING=false
    write_state
    exit 0
elif [ "$1" == "reset" ]; then
    RUNNING=false
    START_TIME=0
    IS_BREAK=false
    COMPLETED=0
    write_state
    exit 0
fi

# Main Logic
read_state
NOW=$(date +%s)

if [ "$RUNNING" == "true" ]; then
    ELAPSED=$((NOW - START_TIME))
    if [ "$IS_BREAK" == "true" ]; then
        DURATION=$((BREAK_MINS * 60))
    else
        DURATION=$((WORK_MINS * 60))
    fi
    
    REMAINING=$((DURATION - ELAPSED))

    if [ $REMAINING -le 0 ]; then
        RUNNING=false
        if [ "$IS_BREAK" == "false" ]; then
            COMPLETED=$((COMPLETED + 1))
            echo "🍅 Work Done!"
        else
            echo "🎉 Break Over!"
        fi
        write_state
    else
        MINS=$((REMAINING / 60))
        SECS=$((REMAINING % 60))
        
        if [ "$IS_BREAK" == "true" ]; then
            printf "☕️ %02d:%02d | color=green\n" $MINS $SECS
        else
            printf "🍅 %02d:%02d | color=red\n" $MINS $SECS
        fi
    fi
else
    echo "🍅 $COMPLETED"
fi

echo "---"
echo "Completed: $COMPLETED"
echo "---"

if [ "$RUNNING" == "true" ]; then
    echo "Stop | bash='$0' param1=stop terminal=false refresh=true"
else
    echo "Start Work (25m) | bash='$0' param1=start_work terminal=false refresh=true"
    echo "Start Break (5m) | bash='$0' param1=start_break terminal=false refresh=true"
fi

echo "Reset Counter | bash='$0' param1=reset terminal=false refresh=true"
echo "---"
echo "Refresh | refresh=true"
