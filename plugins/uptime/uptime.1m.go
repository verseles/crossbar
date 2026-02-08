package main

import (
	"fmt"
	"os/exec"
	"strings"
)

func main() {
	cmd := exec.Command("crossbar", "uptime")
	out, err := cmd.Output()
	if err != nil {
		fmt.Println("⬆️ --\n---\nUnable to get uptime")
		return
	}

	uptime := strings.TrimSpace(string(out))
	if uptime == "" {
		fmt.Println("⬆️ --\n---\nUnable to get uptime")
		return
	}

	fmt.Printf("⬆️ %s\n", uptime)
	fmt.Println("---")
	fmt.Printf("System Uptime: %s\n", uptime)
	fmt.Println("Refresh | refresh=true")
}