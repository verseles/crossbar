// +build ignore

package main

import (
	"bufio"
	"fmt"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"
)

func main() {
	cpuPercent := getCPUUsage()

	// Determine color based on usage
	var color string
	switch {
	case cpuPercent > 80:
		color = "red"
	case cpuPercent > 50:
		color = "yellow"
	default:
		color = "green"
	}

	fmt.Printf("\U0001F4BB %.1f%% | color=%s\n", cpuPercent, color)
	fmt.Println("---")
	fmt.Printf("CPU Usage: %.1f%%\n", cpuPercent)
	fmt.Printf("Cores: %d\n", runtime.NumCPU())
	fmt.Printf("Architecture: %s\n", runtime.GOARCH)
	fmt.Println("---")
	fmt.Println("Refresh | refresh=true")
}

func getCPUUsage() float64 {
	if runtime.GOOS == "linux" {
		return getLinuxCPU()
	}
	// Fallback for other OS
	return 0.0
}

func getLinuxCPU() float64 {
	stat1 := readCPUStat()
	time.Sleep(100 * time.Millisecond)
	stat2 := readCPUStat()

	idle1 := stat1[3]
	idle2 := stat2[3]

	total1 := sum(stat1)
	total2 := sum(stat2)

	totalDelta := total2 - total1
	idleDelta := idle2 - idle1

	if totalDelta == 0 {
		return 0.0
	}

	return 100.0 * float64(totalDelta-idleDelta) / float64(totalDelta)
}

func readCPUStat() []int64 {
	file, err := os.Open("/proc/stat")
	if err != nil {
		return make([]int64, 10)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "cpu ") {
			fields := strings.Fields(line)[1:]
			stats := make([]int64, len(fields))
			for i, f := range fields {
				val, _ := strconv.ParseInt(f, 10, 64)
				stats[i] = val
			}
			return stats
		}
	}
	return make([]int64, 10)
}

func sum(arr []int64) int64 {
	var total int64
	for _, v := range arr {
		total += v
	}
	return total
}
