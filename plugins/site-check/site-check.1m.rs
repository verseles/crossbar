use std::process::Command;
use std::str;
use serde_json::Value; // Import serde_json::Value for JSON parsing

fn main() {
    let url = "https://www.google.com"; // Default site to check
    let (status_code, err_msg) = check_site_crossbar(url);

    let icon: &str;
    let color: &str;
    let status_text: String;

    if let Some(e) = err_msg {
        icon = "\u{274C}"; // Red X
        color = "red";
        status_text = format!("Error: {}", e);
    } else if status_code >= 200 && status_code < 300 {
        icon = "\u{2705}"; // Green check
        color = "green";
        status_text = format!("Up (HTTP {})", status_code);
    } else {
        icon = "\u{26A0}\u{FE0F}"; // Warning triangle
        color = "orange";
        status_text = format!("Down (HTTP {})", status_code);
    }

    println!("{} {} | color={}", icon, status_text, color);
    println!("---");
    println!("Site: {}", url);
    println!("Refresh | refresh=true");
}

fn check_site_crossbar(url: &str) -> (u16, Option<String>) {
    let output = Command::new("crossbar")
        .arg("web")
        .arg(url)
        .arg("--json")
        .output();

    match output {
        Ok(cmd_output) => {
            let stdout = str::from_utf8(&cmd_output.stdout).unwrap_or("");
            if cmd_output.status.success() {
                if let Ok(json_value) = serde_json::from_str::<Value>(stdout) {
                    if let Some(status_code) = json_value["status"].as_u64() {
                        return (status_code as u16, None);
                    }
                }
                (0, Some(format!("Failed to parse JSON or find status code: {}", stdout)))
            } else {
                (0, Some(format!("crossbar web command failed: {}", str::from_utf8(&cmd_output.stderr).unwrap_or(""))))
            }
        }
        Err(e) => (0, Some(format!("Failed to execute crossbar web: {}", e))),
    }
}
