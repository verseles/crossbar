//! Clock Plugin - Shows current time using Crossbar API

use std::process::Command;
use chrono::Local;

fn crossbar(args: &str) -> Option<String> {
    let output = Command::new("crossbar")
        .args(args.split_whitespace())
        .output()
        .ok()?;
    
    if output.status.success() {
        Some(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        None
    }
}

fn main() {
    let now = Local::now();
    
    let time_str = crossbar("--time")
        .unwrap_or_else(|| now.format("%H:%M:%S").to_string());
    let date_str = crossbar("--time --format date")
        .unwrap_or_else(|| now.format("%Y-%m-%d").to_string());
    let tz = crossbar("--timezone")
        .unwrap_or_else(|| now.format("%Z").to_string());

    println!("🕐 {}", time_str);
    println!("---");
    println!("Time: {}", time_str);
    println!("Date: {}", date_str);
    println!("Timezone: {}", tz);
    println!("---");
    println!("Refresh | refresh=true");
}
