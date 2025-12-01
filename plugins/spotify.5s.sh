#!/bin/bash
# Spotify Now Playing (macOS only)
# Shows current track

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo " N/A"
    echo "---"
    echo "macOS only"
    exit 0
fi

state=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)

if [ "$state" = "playing" ]; then
    track=$(osascript -e 'tell application "Spotify" to name of current track as string' 2>/dev/null)
    artist=$(osascript -e 'tell application "Spotify" to artist of current track as string' 2>/dev/null)

    # Truncate if too long
    if [ ${#track} -gt 30 ]; then
        track="${track:0:27}..."
    fi

    echo " $track"
    echo "---"
    echo "Track: $track"
    echo "Artist: $artist"
    echo "---"
    echo "Pause | bash='osascript -e \"tell application \\\"Spotify\\\" to pause\"' terminal=false"
    echo "Next | bash='osascript -e \"tell application \\\"Spotify\\\" to next track\"' terminal=false refresh=true"
    echo "Previous | bash='osascript -e \"tell application \\\"Spotify\\\" to previous track\"' terminal=false refresh=true"
elif [ "$state" = "paused" ]; then
    echo " Paused"
    echo "---"
    echo "Play | bash='osascript -e \"tell application \\\"Spotify\\\" to play\"' terminal=false refresh=true"
else
    echo ""
    echo "---"
    echo "Open Spotify | bash='open -a Spotify' terminal=false"
fi

echo "---"
echo "Refresh | refresh=true"
