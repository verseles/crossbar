#!/bin/bash
# Weather Plugin - Uses curl for HTTP requests
# Requires: WEATHER_API_KEY and WEATHER_CITY env vars

API_KEY="${WEATHER_API_KEY:-}"
CITY="${WEATHER_CITY:-London}"

if [ -z "$API_KEY" ]; then
    echo "🌡️ No API Key"
    echo "---"
    echo "Set WEATHER_API_KEY"
    exit 0
fi

# Use curl
response=$(curl -s "https://api.openweathermap.org/data/2.5/weather?q=${CITY}&appid=${API_KEY}&units=metric")

if [ -z "$response" ]; then
    echo "🌡️ Error"
    echo "---"
    echo "Failed to fetch data"
    exit 0
fi

# Parse JSON (simple grep/perl fallback)
temp=$(echo "$response" | grep -oP '"temp":\s*\K[0-9.]+' | head -1)
desc=$(echo "$response" | grep -oP '"description":\s*"\K[^"]+' | head -1)

if [ -n "$temp" ]; then
    echo "🌡️ ${temp}°C"
    echo "---"
    echo "Location: $CITY"
    echo "Temperature: ${temp}°C"
    echo "Condition: $desc"
else
    echo "🌡️ --"
fi
echo "---"
echo "Refresh | refresh=true"
