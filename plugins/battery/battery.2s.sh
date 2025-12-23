#!/bin/bash
# battery.2s.sh - Battery monitor with dynamic icons (argos-compatible)
# Updates every 2 seconds for real-time monitoring
#
# Features:
# - Dynamic Freedesktop icons (battery-level-X-symbolic)
# - Power consumption in Watts
# - Time remaining to full/empty
# - Color coding by state
#
# Based on: https://github.com/p-e-w/argos

set -u

# ─── Data Sources ───────────────────────────────────────────────────────────

get_bat_upower() {
  upower -e 2>/dev/null | grep -E '/battery_' | head -n1
}

get_bat_sysfs() {
  local up dev
  up=$(get_bat_upower)
  if [ -n "$up" ]; then
    dev=$(upower -i "$up" 2>/dev/null | awk -F': *' '/native-path:/{print $2; exit}')
    [ -n "$dev" ] && [ -d "/sys/class/power_supply/$dev" ] && { echo "/sys/class/power_supply/$dev"; return; }
  fi
  for d in /sys/class/power_supply/BAT*; do [ -d "$d" ] && { echo "$d"; return; }; done
  echo ""
}

UP_BAT="$(get_bat_upower)"
SYS_BAT="$(get_bat_sysfs)"

# ─── UPower Data ────────────────────────────────────────────────────────────

state="$(upower -i "$UP_BAT" 2>/dev/null | awk -F': *' '/state:/{print $2; exit}')"
percent="$(upower -i "$UP_BAT" 2>/dev/null | awk -F': *' '/percentage:/{gsub("%","",$2); print $2; exit}')"
erate="$(LC_ALL=C upower -i "$UP_BAT" 2>/dev/null | awk -F': *' '/energy-rate:/{gsub(" W","",$2); print $2; exit}')"
ttfull="$(upower -i "$UP_BAT" 2>/dev/null | awk -F': *' '/time to full:/{print $2; exit}')"
ttempty="$(upower -i "$UP_BAT" 2>/dev/null | awk -F': *' '/time to empty:/{print $2; exit}')"

# ─── Sysfs Power Calculation ────────────────────────────────────────────────

p_sysfs=""
if [ -n "$SYS_BAT" ] && [ -f "$SYS_BAT/voltage_now" ] && [ -f "$SYS_BAT/current_now" ]; then
  v=$(cat "$SYS_BAT/voltage_now" 2>/dev/null)
  i=$(cat "$SYS_BAT/current_now" 2>/dev/null)
  p_sysfs=$(awk -v v="$v" -v i="$i" 'BEGIN{p=v*i/1e12; if(p<0)p=-p; printf "%.1f", p}')
fi

# ─── Dynamic Icon ───────────────────────────────────────────────────────────

get_battery_icon() {
  local pct="$1"
  local st="$2"
  local level=$((pct / 10 * 10))
  [ "$level" -gt 100 ] && level=100
  [ "$level" -lt 0 ] && level=0

  local suffix=""
  if [ "$st" = "charging" ]; then
    suffix="-charging"
  elif [ "$st" = "fully-charged" ] || [ "$st" = "charged" ]; then
    suffix="-charged"
  fi

  if [ "$pct" -eq 100 ] && [ "$st" = "fully-charged" ]; then
    echo "battery-level-100-charged-symbolic"
  elif [ "$pct" -le 5 ]; then
    echo "battery-level-0${suffix}-symbolic"
  else
    echo "battery-level-${level}${suffix}-symbolic"
  fi
}

# ─── Output ─────────────────────────────────────────────────────────────────

if [ -z "$percent" ]; then
  echo "🔋 --"
  echo "---"
  echo "No battery detected"
  exit 0
fi

icon_name=$(get_battery_icon "${percent:-50}" "$state")

# Color by state
if [ "$state" = "discharging" ]; then
  if [ "$percent" -lt 20 ]; then
    color="color=#ff5555"
  else
    color="color=#f8f8f2"
  fi
else
  color="color=#8be9fd"
fi

# Panel line with power if available
if [ "$state" = "fully-charged" ] || ([ "$percent" -eq 100 ] && [ "$state" = "charging" ]); then
  echo "${percent}% | iconName=$icon_name $color"
elif [ -n "$p_sysfs" ] && [ "$p_sysfs" != "0.0" ]; then
  echo "${p_sysfs}W ${percent}% | iconName=$icon_name $color"
elif [ -n "$erate" ] && [ "$erate" != "0" ]; then
  echo "${erate}W ${percent}% | iconName=$icon_name $color"
else
  echo "🔋 ${percent}% | iconName=$icon_name $color"
fi

# Menu
echo "---"
echo "State: $state"
[ -n "$erate" ] && echo "Power: ${erate} W"
[ -n "$p_sysfs" ] && [ "$p_sysfs" != "0.0" ] && echo "Power (sysfs): ${p_sysfs} W"
[ -n "$ttfull" ] && echo "Time to 100%: $ttfull"
[ -n "$ttempty" ] && echo "Time to 0%: $ttempty"
echo "---"
echo "Open Power Settings | bash='gnome-control-center power' terminal=false"
echo "Refresh | refresh=true"
