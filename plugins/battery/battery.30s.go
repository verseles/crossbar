package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
)

type BatteryData struct {
	Level    int  `json:"level"`
	Charging bool `json:"charging"`
}

func main() {
	cmd := exec.Command("crossbar", "battery", "--json")
	out, err := cmd.Output()
	if err != nil {
		fmt.Println("🔋 --\n---\nError fetching battery info")
		return
	}

	var data BatteryData
	if err := json.Unmarshal(out, &data); err != nil {
		fmt.Println("🔋 --\n---\nNo battery detected")
		return
	}

	icon := "🔋"
	color := "green"

	if data.Charging {
		icon = "⚡"
		color = "blue"
	} else if data.Level <= 20 {
		icon = "🪫"
		color = "red"
	} else if data.Level <= 50 {
		color = "yellow"
	}

	fmt.Printf("%s %d%% | color=%s\n", icon, data.Level, color)
	fmt.Println("---")
	fmt.Printf("Battery Level: %d%%\n", data.Level)
	if data.Charging {
		fmt.Println("Status: Charging")
	} else {
		fmt.Println("Status: Discharging")
	}
	fmt.Println("---")
	fmt.Println("Refresh | refresh=true")
}