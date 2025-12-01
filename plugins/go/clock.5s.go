// +build ignore

package main

import (
	"fmt"
	"time"
)

func main() {
	now := time.Now()
	hour := now.Hour()

	// Determine icon based on time of day
	var icon string
	switch {
	case hour >= 6 && hour < 12:
		icon = "\U0001F305" // sunrise
	case hour >= 12 && hour < 18:
		icon = "\u2600\uFE0F" // sun
	case hour >= 18 && hour < 21:
		icon = "\U0001F307" // sunset
	default:
		icon = "\U0001F319" // moon
	}

	// Format time
	timeStr := now.Format("15:04:05")

	fmt.Printf("%s %s\n", icon, timeStr)
	fmt.Println("---")
	fmt.Printf("Date: %s\n", now.Format("Monday, January 2, 2006"))
	_, week := now.ISOWeek()
	fmt.Printf("Week: %d\n", week)
	fmt.Printf("Day of Year: %d\n", now.YearDay())
	fmt.Println("---")
	fmt.Println("Refresh | refresh=true")
}
