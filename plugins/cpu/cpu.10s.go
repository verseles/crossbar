//go:build ignore

package main

import (
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
	cpuStr := crossbar("--cpu")
	if cpuStr == "" {
		cpuStr = "N/A"
	}

	color := "green"
	if cpu, err := strconv.ParseFloat(cpuStr, 64); err == nil {
		if cpu > 80 {
			color = "red"
		} else if cpu > 50 {
			color = "yellow"
		}
	}

	fmt.Printf("⚡ %s%% | color=%s\n", cpuStr, color)
	fmt.Println("---")
	fmt.Printf("CPU Usage: %s%%\n", cpuStr)
	fmt.Println("---")
	fmt.Println("Refresh | refresh=true")
}
