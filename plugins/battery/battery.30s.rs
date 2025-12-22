use std::process::Command;
use std::str;

fn main() {
    let output = Command::new("crossbar")
        .args(&["battery", "--json"])
        .output();

    match output {
        Ok(cmd_output) if cmd_output.status.success() => {
            let json_str = str::from_utf8(&cmd_output.stdout).unwrap_or("");
            // Simple parsing without serde dependency for portability
            let level = extract_int(json_str, "level");
            let charging = json_str.contains("\"charging\":true");

            match level {
                Some(l) => {
                    let mut icon = "🔋";
                    let mut color = "green";

                    if charging {
                        icon = "⚡"; color = "blue";
                    } else if l <= 20 {
                        icon = "🪫"; color = "red";
                    } else if l <= 50 {
                        color = "yellow";
                    }

                    println!("{} {}% | color={}", icon, l, color);
                    println!("---");
                    println!("Battery Level: {}%", l);
                    println!("Status: {}", if charging { "Charging" } else { "Discharging" });
                    println!("---");
                    println!("Refresh | refresh=true");
                }
                None => {
                    println!("🔋 --\n---\nNo battery detected");
                }
            }
        }
        _ => {
            println!("🔋 --\n---
Error fetching battery info");
        }
    }
}

fn extract_int(json: &str, key: &str) -> Option<i32> {
    let pattern = format!("\"{}\":", key);
    if let Some(pos) = json.find(&pattern) {
        let start = pos + pattern.len();
        let end = json[start..].find(|c: char| !c.is_digit(10)).unwrap_or(json.len() - start);
        return json[start..start+end].trim().parse().ok();
    }
    None
}