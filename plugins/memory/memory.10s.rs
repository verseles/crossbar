//! Memory Monitor Plugin - Uses Crossbar API for portability

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
    let memory_str = crossbar("--memory").unwrap_or_else(|| "N/A".to_string());
    
    let color = if let Ok(memory) = memory_str.trim_end_matches('%').parse::<i32>() {
        if memory > 80 { "red" }
        else if memory > 60 { "yellow" }
        else { "green" }
    } else {
        "gray"
    };

    println!("🧠 {}% | color={}", memory_str, color);
    println!("---");
    println!("Memory Usage: {}%", memory_str);
    println!("---");
    println!("Refresh | refresh=true");
}
