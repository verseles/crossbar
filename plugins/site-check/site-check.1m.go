package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

func main() {
	url := "https://www.google.com" // Default site to check
	statusCode, err := checkSiteCrossbar(url)

	var icon string
	var color string
	var statusText string

	if err != nil {
		icon = "\U0000274C" // Red X
		color = "red"
		statusText = fmt.Sprintf("Error: %v", err)
	} else if statusCode >= 200 && statusCode < 300 {
		icon = "\U00002705" // Green check
		color = "green"
		statusText = fmt.Sprintf("Up (HTTP %d)", statusCode) // crossbar web doesn't give duration directly
	} else {
		icon = "\U000026A0\U0000FE0F" // Warning triangle
		color = "orange"
		statusText = fmt.Sprintf("Down (HTTP %d)", statusCode)
	}

	fmt.Printf("%s %s | color=%s\n", icon, statusText, color)
	fmt.Println("---")
	fmt.Printf("Site: %s\n", url)
	fmt.Println("Refresh | refresh=true")
}

func checkSiteCrossbar(url string) (int, error) {
	cmd := exec.Command("crossbar", "web", url, "--json")
	output, err := cmd.Output()
	if err != nil {
		return 0, fmt.Errorf("crossbar web command failed: %v", err)
	}

	var result map[string]interface{}
	err = json.Unmarshal(output, &result)
	if err != nil {
		return 0, fmt.Errorf("failed to parse JSON response: %v", err)
	}

	statusCode, ok := result["status"].(float64) // JSON numbers are often float64 in Go
	if !ok {
		return 0, fmt.Errorf("status code not found or not a number in JSON response")
	}

	return int(statusCode), nil
}
