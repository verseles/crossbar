//! Battery Monitor Plugin - Uses Crossbar API for portability

use std::process::Command;
use serde_json::Value;

fn crossbar(args: &[&str]) -> Option<String> {
    let output = Command::new("crossbar")
        .args(args)
        .output()
        .ok()?;
    
    if output.status.success() {
        Some(String::from_utf8_lossy(&output.stdout).trim().to_string())
    } else {
        None
    }
}

fn main() {
    let battery_str = crossbar(&["battery"]).unwrap_or_else(|| "N/A".to_string());
    
    let mut charging = false;
    if let Some(json_str) = crossbar(&["battery", "--json"]) {
        if let Ok(data) = serde_json::from_str::<Value>(&json_str) {
            charging = data["charging"].as_bool().unwrap_or(false);
        }
    }

    let battery: i32 = battery_str.parse().unwrap_or(0);
    
    let (icon, color) = if charging {
        ("🔌", "blue")
    } else if battery < 20 {
        ("🪫", "red")
    } else if battery < 50 {
        ("🔋", "yellow")
    } else {
        ("🔋", "green")
    };

    println!("{} {}% | color={}", icon, battery_str, color);
    println!("---");
    println!("Battery: {}%", battery_str);
    if charging {
        println!("Status: Charging ⚡");
    }
    println!("---");
    println!("Refresh | refresh=true");
}
