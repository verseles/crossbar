//go:build ignore

package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

func crossbar(args ...string) string {
	cmd := exec.Command("crossbar", args...)
	out, err := cmd.Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}

func formatNumber(n float64) string {
	str := strconv.FormatFloat(n, 'f', 0, 64)
	result := ""
	for i, c := range str {
		if i > 0 && (len(str)-i)%3 == 0 {
			result += ","
		}
		result += string(c)
	}
	return result
}

func main() {
	url := "https://api.coinbase.com/v2/prices/BTC-USD/spot"
	response := crossbar("--web", url, "--json")

	if response == "" {
		fmt.Println("₿ Error")
		fmt.Println("---")
		fmt.Println("Failed to fetch price")
		return
	}

	var data map[string]interface{}
	if err := json.Unmarshal([]byte(response), &data); err != nil {
		fmt.Println("₿ Parse Error")
		return
	}

	price := "--"
	formatted := "--"
	if d, ok := data["data"].(map[string]interface{}); ok {
		if amount, ok := d["amount"].(string); ok {
			price = amount
			if p, err := strconv.ParseFloat(amount, 64); err == nil {
				formatted = formatNumber(p)
			}
		}
	}

	fmt.Printf("₿ $%s\n", formatted)
	fmt.Println("---")
	fmt.Printf("BTC/USD: $%s\n", price)
	fmt.Println("Source: Coinbase")
	fmt.Println("---")
	fmt.Println("Refresh | refresh=true")
}
