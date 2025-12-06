//go:build ignore

package main

import (
	"fmt"
	"os/exec"
	"strings"
	"time"
)

func crossbar(args ...string) string {
	cmd := exec.Command("crossbar", args...)
	out, err := cmd.Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func main() {
	now := time.Now()
	
	timeStr := crossbar("time")
	if timeStr == "" {
		timeStr = now.Format("15:04:05")
	}
	
	dateStr := crossbar("date")
	if dateStr == "" {
		dateStr = now.Format("2006-01-02")
	}

	fmt.Printf("🕐 %s\n", timeStr)
	fmt.Println("---")
	fmt.Printf("Time: %s\n", timeStr)
	fmt.Printf("Date: %s\n", dateStr)
	fmt.Println("---")
	fmt.Println("Refresh | refresh=true")
}
