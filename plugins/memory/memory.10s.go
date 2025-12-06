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
	memoryStr := crossbar("--memory")
	if memoryStr == "" {
		memoryStr = "N/A"
	}

	color := "green"
	if memory, err := strconv.Atoi(strings.TrimSuffix(memoryStr, "%")); err == nil {
		if memory > 80 {
			color = "red"
		} else if memory > 60 {
			color = "yellow"
		}
	}

	fmt.Printf("🧠 %s%% | color=%s\n", memoryStr, color)
	fmt.Println("---")
	fmt.Printf("Memory Usage: %s%%\n", memoryStr)
	fmt.Println("---")
	fmt.Println("Refresh | refresh=true")
}
