// +build ignore

package main

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
)

func main() {
	level, charging := getBatteryStatus()

	if level < 0 {
		fmt.Println("\U0001F50C N/A")
		return
	}

	// Determine icon and color based on level and charging state
	var icon, color string
	if charging {
		icon = "\u26A1" // lightning bolt
		color = "blue"
	} else {
		switch {
		case level <= 10:
			icon = "\U0001FAAB" // empty battery
			color = "red"
		case level <= 25:
			icon = "\U0001F50B" // battery
			color = "orange"
		case level <= 50:
			icon = "\U0001F50B"
			color = "yellow"
		default:
			icon = "\U0001F50B"
			color = "green"
		}
	}

	fmt.Printf("%s %d%% | color=%s\n", icon, level, color)
	fmt.Println("---")
	fmt.Printf("Battery Level: %d%%\n", level)
	if charging {
		fmt.Println("Status: Charging")
	} else {
		fmt.Println("Status: Discharging")
	}
	fmt.Println("---")
	fmt.Println("Refresh | refresh=true")
}

func getBatteryStatus() (int, bool) {
	switch runtime.GOOS {
	case "linux":
		return getLinuxBattery()
	case "darwin":
		return getMacOSBattery()
	default:
		return -1, false
	}
}

func getLinuxBattery() (int, bool) {
	// Find battery in /sys/class/power_supply/
	matches, _ := filepath.Glob("/sys/class/power_supply/BAT*")
	if len(matches) == 0 {
		return -1, false
	}

	batPath := matches[0]

	// Read capacity
	capacityData, err := os.ReadFile(filepath.Join(batPath, "capacity"))
	if err != nil {
		return -1, false
	}
	level, _ := strconv.Atoi(strings.TrimSpace(string(capacityData)))

	// Read status
	statusData, err := os.ReadFile(filepath.Join(batPath, "status"))
	charging := false
	if err == nil {
		status := strings.TrimSpace(string(statusData))
		charging = status == "Charging" || status == "Full"
	}

	return level, charging
}

func getMacOSBattery() (int, bool) {
	// On macOS, we would use pmset or IOKit
	// For simplicity, return -1 (not available)
	return -1, false
}
