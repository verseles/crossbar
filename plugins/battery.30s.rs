use std::fs;
use std::path::Path;

fn main() {
    let (level, charging) = get_battery_status();

    if level < 0 {
        println!("\u{1F50C} N/A");
        return;
    }

    // Determine icon and color
    let (icon, color) = if charging {
        ("\u{26A1}", "blue")
    } else {
        match level {
            0..=10 => ("\u{1FAAB}", "red"),
            11..=25 => ("\u{1F50B}", "orange"),
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

fn get_battery_status() -> (i32, bool) {
    // Find battery in /sys/class/power_supply/
    let power_supply = Path::new("/sys/class/power_supply");

    if !power_supply.exists() {
        return (-1, false);
    }

    if let Ok(entries) = fs::read_dir(power_supply) {
        for entry in entries.filter_map(|e| e.ok()) {
            let name = entry.file_name();
            let name_str = name.to_string_lossy();

            if name_str.starts_with("BAT") {
                let bat_path = entry.path();

                // Read capacity
                let capacity_path = bat_path.join("capacity");
                let level = if let Ok(content) = fs::read_to_string(&capacity_path) {
                    content.trim().parse().unwrap_or(-1)
                } else {
                    -1
                };

                // Read status
                let status_path = bat_path.join("status");
                let charging = if let Ok(content) = fs::read_to_string(&status_path) {
                    let status = content.trim();
                    status == "Charging" || status == "Full"
                } else {
                    false
                };

                return (level, charging);
            }
        }
    }

    (-1, false)
}
