//go:build ignore

package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

func crossbar(args string) string {
	cmd := exec.Command("crossbar", strings.Split(args, " ")...)
	out, err := cmd.Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func main() {
	batteryStr := crossbar("--battery")
	if batteryStr == "" {
		batteryStr = "N/A"
	}

	charging := false
	jsonStr := crossbar("--battery --json")
	if jsonStr != "" {
		var data map[string]interface{}
		if err := json.Unmarshal([]byte(jsonStr), &data); err == nil {
			if c, ok := data["charging"].(bool); ok {
				charging = c
			}
		}
	}

	battery, _ := strconv.Atoi(batteryStr)
	var icon, color string

	if charging {
		icon, color = "🔌", "blue"
	} else if battery < 20 {
		icon, color = "🪫", "red"
	} else if battery < 50 {
		icon, color = "🔋", "yellow"
	} else {
		icon, color = "🔋", "green"
	}

	fmt.Printf("%s %s%% | color=%s\n", icon, batteryStr, color)
	fmt.Println("---")
	fmt.Printf("Battery: %s%%\n", batteryStr)
	if charging {
		fmt.Println("Status: Charging ⚡")
	}
	fmt.Println("---")
	fmt.Println("Refresh | refresh=true")
}
