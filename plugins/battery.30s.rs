use std::process::Command;
use std::str;
use std::str::FromStr;

fn main() {
    let (level, charging) = get_battery_status_crossbar();

    if level < 0 {
        println!("\u{1F50C} N/A");
        return;
    }

    // Determine icon and color based on level and charging state
    let (icon, color) = if charging {
        ("\u{26A1}", "blue") // lightning bolt
    } else {
        match level {
            0..=10 => ("\u{1FAAB}", "red"), // empty battery
            11..=25 => ("\u{1F50B}", "orange"), // battery
            26..=50 => ("\u{1F50B}", "yellow"),
            _ => ("\u{1F50B}", "green"),
        }
    };

    println!("{} {}% | color={}", icon, level, color);
    println!("---");
    println!("Battery Level: {}%", level);
    if charging {
        println!("Status: Charging");
    } else {
        println!("Status: Discharging");
    }
    println!("---");
    println!("Refresh | refresh=true");
}

fn get_battery_status_crossbar() -> (i32, bool) {
    let output = Command::new("crossbar")
        .arg("battery")
        .output();

    match output {
        Ok(cmd_output) => {
            let battery_info = str::from_utf8(&cmd_output.stdout).unwrap_or("").trim();
            // Example: "87% ⚡" or "50%"

            let mut level_str = String::new();
            for c in battery_info.chars() {
                if c.is_ascii_digit() {
                    level_str.push(c);
                } else if !level_str.is_empty() {
                    break;
                }
            }

            let level = i32::from_str(&level_str).unwrap_or(-1);
            let charging = battery_info.contains("⚡");

            (level, charging)
        }
        Err(_) => (-1, false),
    }
}
