//go:build ignore

package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

func main() {
	apiKey := os.Getenv("WEATHER_API_KEY")
	city := os.Getenv("WEATHER_CITY")
	if city == "" {
		city = "London"
	}

	if apiKey == "" {
		fmt.Println("🌡️ No API Key")
		fmt.Println("---")
		fmt.Println("Set WEATHER_API_KEY")
		return
	}

	url := fmt.Sprintf("https://api.openweathermap.org/data/2.5/weather?q=%s&appid=%s&units=metric", city, apiKey)
	resp, err := http.Get(url)
	if err != nil {
		fmt.Println("🌡️ Error")
		return
	}
	defer resp.Body.Close()

	var data map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		fmt.Println("🌡️ Parse Error")
		return
	}

	temp := "--"
	desc := ""
	if main, ok := data["main"].(map[string]interface{}); ok {
		if t, ok := main["temp"].(float64); ok {
			temp = fmt.Sprintf("%.1f", t)
		}
	}
	if weather, ok := data["weather"].([]interface{}); ok && len(weather) > 0 {
		if w, ok := weather[0].(map[string]interface{}); ok {
			desc, _ = w["description"].(string)
		}
	}

	fmt.Printf("🌡️ %s°C\n", temp)
	fmt.Println("---")
	fmt.Printf("Location: %s\n", city)
	fmt.Printf("Temperature: %s°C\n", temp)
	fmt.Printf("Condition: %s\n", desc)
	fmt.Println("---")
	fmt.Println("Refresh | refresh=true")
}
