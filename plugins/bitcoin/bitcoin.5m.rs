//! Bitcoin Price Plugin - Uses Crossbar API for HTTP requests

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

fn format_number(n: f64) -> String {
    let s = format!("{:.0}", n);
    let chars: Vec<char> = s.chars().collect();
    let mut result = String::new();
    for (i, c) in chars.iter().enumerate() {
        if i > 0 && (chars.len() - i) % 3 == 0 {
            result.push(',');
        }
        result.push(*c);
    }
    result
}

fn main() {
    let url = "https://api.coinbase.com/v2/prices/BTC-USD/spot";
    let response = crossbar(&["--web", url, "--json"]);

    if response.is_none() {
        println!("₿ Error");
        println!("---");
        println!("Failed to fetch price");
        return;
    }

    let response = response.unwrap();
    match serde_json::from_str::<Value>(&response) {
        Ok(data) => {
            let price = data["data"]["amount"]
                .as_str()
                .unwrap_or("--");
            
            let formatted = price.parse::<f64>()
                .map(|p| format_number(p))
                .unwrap_or_else(|_| price.to_string());

            println!("₿ ${}", formatted);
            println!("---");
            println!("BTC/USD: ${}", price);
            println!("Source: Coinbase");
        }
        Err(_) => println!("₿ Parse Error"),
    }

    println!("---");
    println!("Refresh | refresh=true");
}
