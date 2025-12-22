use std::process::Command;
use std::str;
use std::str::FromStr;

fn main() {
    // Use Crossbar CLI API to get current time
    let output_time = Command::new("crossbar")
        .arg("time")
        .arg("24h")
        .output();

    let time_str = match output_time {
        Ok(cmd_output) => str::from_utf8(&cmd_output.stdout).unwrap_or("N/A").trim().to_string(),
        Err(_) => "N/A".to_string(),
    };

    // Use Crossbar CLI API to get current date
    let output_date = Command::new("crossbar")
        .arg("date")
        .output();

    let date_str = match output_date {
        Ok(cmd_output) => str::from_utf8(&cmd_output.stdout).unwrap_or("N/A").trim().to_string(),
        Err(_) => "N/A".to_string(),
    };

    // Try to parse hour for icon logic
    let mut hour: i32 = -1;
    if let Some(h_str) = time_str.split(':').next() {
        if let Ok(h) = i32::from_str(h_str) {
            hour = h;
        }
    }

    // Determine icon based on time of day
    let icon = match hour {
        6..=11 => "\u{1F305}", // sunrise
        12..=17 => "\u{2600}\u{FE0F}", // sun
        18..=20 => "\u{1F307}", // sunset
        _ => "\u{1F319}", // moon
    };

    println!("{} {}", icon, time_str);
    println!("---");
    println!("Date: {}", date_str);
    // Removed Week and Day of Year as crossbar CLI doesn't provide these directly in a simple format
    println!("---");
    println!("Refresh | refresh=true");
}
