// +build ignore

package main

import (
	"fmt"
	"net/http"
	"time"
)

// Sites to monitor
var sites = []string{
	"https://google.com",
	"https://github.com",
	"https://cloudflare.com",
}

type SiteStatus struct {
	URL      string
	Up       bool
	Latency  time.Duration
	Status   int
	Error    string
}

func main() {
	results := checkSites()

	// Count up/down
	upCount := 0
	for _, r := range results {
		if r.Up {
			upCount++
		}
	}

	// Header
	var color string
	if upCount == len(results) {
		color = "green"
		fmt.Printf("\u2705 %d/%d Up | color=%s\n", upCount, len(results), color)
	} else if upCount == 0 {
		color = "red"
		fmt.Printf("\u274C %d/%d Up | color=%s\n", upCount, len(results), color)
	} else {
		color = "yellow"
		fmt.Printf("\u26A0\uFE0F %d/%d Up | color=%s\n", upCount, len(results), color)
	}

	fmt.Println("---")

	// Individual site status
	for _, r := range results {
		if r.Up {
			fmt.Printf("\u2705 %s - %dms (HTTP %d)\n", r.URL, r.Latency.Milliseconds(), r.Status)
		} else {
			fmt.Printf("\u274C %s - %s | color=red\n", r.URL, r.Error)
		}
	}

	fmt.Println("---")
	fmt.Printf("Last checked: %s\n", time.Now().Format("15:04:05"))
	fmt.Println("Refresh | refresh=true")
}

func checkSites() []SiteStatus {
	results := make([]SiteStatus, len(sites))

	for i, url := range sites {
		results[i] = checkSite(url)
	}

	return results
}

func checkSite(url string) SiteStatus {
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	start := time.Now()
	resp, err := client.Get(url)
	latency := time.Since(start)

	if err != nil {
		return SiteStatus{
			URL:   url,
			Up:    false,
			Error: "Connection failed",
		}
	}
	defer resp.Body.Close()

	up := resp.StatusCode >= 200 && resp.StatusCode < 400

	return SiteStatus{
		URL:     url,
		Up:      up,
		Latency: latency,
		Status:  resp.StatusCode,
	}
}
