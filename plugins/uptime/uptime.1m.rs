use std::process::Command;

fn main() {
    let output = Command::new("crossbar")
        .arg("uptime")
        .output()
        .expect("Failed to execute command");

    let uptime = String::from_utf8_lossy(&output.stdout).trim().to_string();
    println!("⬆️ {} | size=12", uptime);
    println!("---");
    println!("Refresh | refresh=true");
}
