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
		fmt.Println("⬆️ Error")
		return
	}
	uptime := strings.TrimSpace(string(out))
	fmt.Printf("⬆️ %s | size=12\n", uptime)
	fmt.Println("---")
	fmt.Println("Refresh | refresh=true")
}
