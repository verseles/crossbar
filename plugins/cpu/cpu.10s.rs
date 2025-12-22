use std::fs::File;
use std::io::{BufRead, BufReader};
use std::thread;
use std::time::Duration;

fn main() {
    let cpu_percent = get_cpu_usage();

    // Determine color based on usage
    let color = if cpu_percent > 80.0 {
        "red"
    } else if cpu_percent > 50.0 {
        "yellow"
    } else {
        "green"
    };

    println!("\u{1F4BB} {:.1}% | color={}", cpu_percent, color);
    println!("---");
    println!("CPU Usage: {:.1}%", cpu_percent);

    // Get number of CPUs
    if let Ok(file) = File::open("/proc/cpuinfo") {
        let reader = BufReader::new(file);
        let cores = reader.lines()
            .filter_map(|l| l.ok())
            .filter(|l| l.starts_with("processor"))
            .count();
        println!("Cores: {}", cores);
    }

    println!("---");
    println!("Refresh | refresh=true");
}

fn get_cpu_usage() -> f64 {
    let stat1 = read_cpu_stat();
    thread::sleep(Duration::from_millis(100));
    let stat2 = read_cpu_stat();

    if stat1.is_empty() || stat2.is_empty() {
        return 0.0;
    }

    let idle1 = stat1.get(3).copied().unwrap_or(0);
    let idle2 = stat2.get(3).copied().unwrap_or(0);

    let total1: u64 = stat1.iter().sum();
    let total2: u64 = stat2.iter().sum();

    let total_delta = total2.saturating_sub(total1);
    let idle_delta = idle2.saturating_sub(idle1);

    if total_delta == 0 {
        return 0.0;
    }

    100.0 * (total_delta - idle_delta) as f64 / total_delta as f64
}

fn read_cpu_stat() -> Vec<u64> {
    if let Ok(file) = File::open("/proc/stat") {
        let reader = BufReader::new(file);
        for line in reader.lines().filter_map(|l| l.ok()) {
            if line.starts_with("cpu ") {
                return line.split_whitespace()
                    .skip(1)
                    .filter_map(|s| s.parse().ok())
                    .collect();
            }
        }
    }
    Vec::new()
}
