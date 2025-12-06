//! Weather Plugin - Uses curl via Command (no external deps)

use std::env;
use std::process::Command;
use serde_json::Value;

fn main() {
    let api_key = env::var("WEATHER_API_KEY").unwrap_or_default();
    let city = env::var("WEATHER_CITY").unwrap_or_else(|_| "London".to_string());

    if api_key.is_empty() {
        println!("🌡️ No API Key");
        println!("---");
        println!("Set WEATHER_API_KEY");
        return;
    }

    let url = format!(
        "https://api.openweathermap.org/data/2.5/weather?q={}&appid={}&units=metric",
        city, api_key
    );
    
    // Fallback to curl since we don't carry reqwest
    let output = Command::new("curl")
        .args(&["-s", &url])
        .output();
        
    if let Ok(out) = output {
        let json_str = String::from_utf8_lossy(&out.stdout);
        match serde_json::from_str::<Value>(&json_str) {
            Ok(data) => {
                let temp = data["main"]["temp"].as_f64()
                    .map(|t| format!("{:.1}", t))
                    .unwrap_or_else(|| "--".to_string());
                let desc = data["weather"][0]["description"]
                    .as_str()
                    .unwrap_or("");

                println!("🌡️ {}°C", temp);
                println!("---");
                println!("Location: {}", city);
                println!("Temperature: {}°C", temp);
                println!("Condition: {}", desc);
            }
            Err(_) => println!("🌡️ Parse Error"),
        }
    } else {
        println!("🌡️ Error");
        println!("---");
        println!("Failed to run curl");
    }

    println!("---");
    println!("Refresh | refresh=true");
}
