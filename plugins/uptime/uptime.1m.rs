use std::process::Command;
use std::str;

fn main() {
    let output = Command::new("crossbar")
        .arg("uptime")
        .output();

    match output {
        Ok(cmd_output) if cmd_output.status.success() => {
            let uptime = str::from_utf8(&cmd_output.stdout).unwrap_or("").trim();
            if !uptime.is_empty() {
                println!("⬆️ {}", uptime);
                println!("---");
                println!("System Uptime: {}", uptime);
                println!("Refresh | refresh=true");
            } else {
                println!("⬆️ --\n---\nUnable to get uptime");
            }
        }
        _ => {
            println!("⬆️ --\n---\nUnable to get uptime");
        }
    }
}