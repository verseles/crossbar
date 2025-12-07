// +build ignore

package main

import (
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

func main() {
	// Use Crossbar CLI API to get current time
	cmd := exec.Command("crossbar", "time", "24h") // Request 24-hour format
	output, err := cmd.Output()
	timeStr := "N/A"
	if err == nil {
		timeStr = strings.TrimSpace(string(output)) // Example: "14:30:05"
	}

	// Parse time string to get hour for color logic
	hour := -1
	if parts := strings.Split(timeStr, ":"); len(parts) >= 1 {
		if h, err := strconv.Atoi(parts[0]); err == nil {
			hour = h
		}
	}

	// Determine icon
	icon := "⏰"

	// Determine color based on time of day (example logic)
	var color string
	if hour >= 6 && hour < 12 {
		color = "blue" // Morning
	} else if hour >= 12 && hour < 18 {
		color = "green" // Afternoon
	} else {
		color = "gray" // Evening/Night
	}

	// Print output
	fmt.Printf("%s %s | color=%s\n", icon, timeStr, color)
	fmt.Println("---")
	fmt.Printf("Current Time: %s\n", timeStr)
	// Optionally get date using crossbar date
	cmdDate := exec.Command("crossbar", "date")
	outputDate, errDate := cmdDate.Output()
	dateStr := "N/A"
	if errDate == nil {
		dateStr = strings.TrimSpace(string(outputDate))
	}
	fmt.Printf("Current Date: %s\n", dateStr)
	fmt.Println("Refresh | refresh=true")
}
