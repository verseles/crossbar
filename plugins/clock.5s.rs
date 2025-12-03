use std::time::SystemTime;

fn main() {
    let now = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap();

    let total_secs = now.as_secs();
    let hours = ((total_secs % 86400) / 3600) as u32;
    let minutes = ((total_secs % 3600) / 60) as u32;
    let seconds = (total_secs % 60) as u32;

    // Determine icon based on hour (local time approximation)
    let icon = match hours {
        6..=11 => "\u{1F305}",   // sunrise
        12..=17 => "\u{2600}\u{FE0F}", // sun
        18..=20 => "\u{1F307}",  // sunset
        _ => "\u{1F319}",        // moon
    };

    println!("{} {:02}:{:02}:{:02}", icon, hours, minutes, seconds);
    println!("---");
    println!("UTC Time: {:02}:{:02}:{:02}", hours, minutes, seconds);
    println!("Unix Timestamp: {}", total_secs);
    println!("---");
    println!("Refresh | refresh=true");
}
