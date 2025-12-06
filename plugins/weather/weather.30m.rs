//! Weather Plugin - Uses Crossbar API for HTTP requests

use std::env;
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
    let api_key = env::var("WEATHER_API_KEY").unwrap_or_default();
    let city = env::var("WEATHER_CITY").unwrap_or_else(|_| "London".to_string());

    if api_key.is_empty() {
        println!("🌡️ No API Key");
        println!("---");
        println!("Set WEATHER_API_KEY in configuration");
        return;
    }

    let url = format!(
        "https://api.openweathermap.org/data/2.5/weather?q={}&appid={}&units=metric",
        city, api_key
    );
    
    let response = crossbar(&["--web", &url, "--json"]);

    if response.is_none() {
        println!("🌡️ Error");
        println!("---");
        println!("Failed to fetch weather data");
        return;
    }

    let response = response.unwrap();
    match serde_json::from_str::<Value>(&response) {
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

    println!("---");
    println!("Refresh | refresh=true");
}
