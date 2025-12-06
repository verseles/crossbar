//! Bitcoin Price Plugin - Uses curl via Command

use std::process::Command;
use serde_json::Value;

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
    let output = Command::new("curl")
        .args(&["-s", url])
        .output();

    if let Ok(out) = output {
        let json_str = String::from_utf8_lossy(&out.stdout);
        match serde_json::from_str::<Value>(&json_str) {
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
    } else {
        println!("₿ Error");
        println!("---");
        println!("Failed to run curl");
    }

    println!("---");
    println!("Refresh | refresh=true");
}
