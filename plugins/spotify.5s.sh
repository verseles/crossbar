#!/bin/bash
# Spotify Now Playing (macOS only)
# Shows current track

media_info=$(crossbar media playing --json)

if [ "$?" -eq 0 ] && [ "$media_info" != "null" ]; then
    status=$(echo "$media_info" | jq -r '.status')
    if [ "$status" == "playing" ]; then
        artist=$(echo "$media_info" | jq -r '.artist')
        track=$(echo "$media_info" | jq -r '.title')
        
        echo " $(echo "$track - $artist" | cut -c1-30)..."
        echo "---"
        echo "Artist: $artist"
        echo "Track: $track"
        echo "Next | bash='crossbar media next' terminal=false"
        echo "Prev | bash='crossbar media prev' terminal=false"
        echo "Play/Pause | bash='crossbar media toggle' terminal=false"
    else
        echo "Not Playing"
    fi
else
    echo "Spotify 🎵"
    echo "---"
    echo "No media info available or Spotify not playing."
fi
echo "---"
echo "Refresh | refresh=true"
