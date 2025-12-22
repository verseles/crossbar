package main

import (
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

func main() {
	// Default values
	batteryLevel := "N/A"
	batteryStatus := "?"
	batteryIcon := "\U0001F50B" // Battery icon

	// Use Crossbar CLI API to get battery status
	cmd := exec.Command("crossbar", "battery")
	out, err := cmd.Output()
	if err == nil {
		batteryInfo := strings.TrimSpace(string(out)) // Example: "87% ⚡" or "50%"

		// Extract percentage
		levelStr := ""
		for _, r := range batteryInfo {
			if r >= '0' && r <= '9' {
				levelStr += string(r)
			} else if levelStr != "" {
				break
			}
		}
		if levelStr != "" {
			batteryLevel = levelStr
		}

		// Determine status
		if strings.Contains(batteryInfo, "⚡") {
			batteryStatus = "Charging"
		} else if strings.Contains(batteryInfo, "Full") || (levelStr == "100" && !strings.Contains(batteryInfo, "Discharging")) {
			batteryStatus = "Full"
		} else {
			batteryStatus = "Discharging"
		}
	}

	// Determine icon and color
	var color string
	switch batteryStatus {
	case "Charging":
		batteryIcon = "\U000026A1" // Lightning bolt
		color = "green"
	case "Full":
		batteryIcon = "\U0001F50B" // Full battery icon
		color = "green"
	case "Discharging":
		level, _ := strconv.Atoi(batteryLevel)
		switch {
		case level <= 20:
			batteryIcon = "\U0001F50C" // Low battery icon
			color = "red"
		case level <= 50:
			batteryIcon = "\U0001F50D" // Half battery icon
			color = "yellow"
		default:
			batteryIcon = "\U0001F50B" // Full battery icon
			color = "green"
		}
	default: // Unknown
		batteryIcon = "\U0001F50B"
		color = "gray"
	}

	// Print output
	fmt.Printf("%s %s%% | color=%s\n", batteryIcon, batteryLevel, color)
	fmt.Println("---")
	fmt.Printf("Status: %s\n", batteryStatus)
	fmt.Println("Refresh | refresh=true")
}
