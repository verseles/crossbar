//! CPU Monitor Plugin - Uses Crossbar API for portability

use std::process::Command;

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
    let cpu_str = crossbar("--cpu").unwrap_or_else(|| "N/A".to_string());
    
    let color = if let Ok(cpu) = cpu_str.parse::<f64>() {
        if cpu > 80.0 { "red" }
        else if cpu > 50.0 { "yellow" }
        else { "green" }
    } else {
        "gray"
    };

    println!("⚡ {}% | color={}", cpu_str, color);
    println!("---");
    println!("CPU Usage: {}%", cpu_str);
    println!("---");
    println!("Refresh | refresh=true");
}
