use std::io::{Read, Write};
use std::net::TcpStream;
use std::time::{Duration, Instant};

// Sites to check (name, hostname, port, path)
const SITES: &[(&str, &str, u16, &str)] = &[
    ("Google", "google.com", 80, "/"),
    ("GitHub", "github.com", 80, "/"),
    ("Cloudflare", "cloudflare.com", 80, "/"),
];

struct SiteStatus {
    name: &'static str,
    up: bool,
    latency_ms: u128,
    error: String,
}

fn main() {
    let results = check_sites();

    // Count up/down
    let up_count = results.iter().filter(|r| r.up).count();
    let total = results.len();

    // Header
    let (icon, color) = if up_count == total {
        ("\u{2705}", "green")
    } else if up_count == 0 {
        ("\u{274C}", "red")
    } else {
        ("\u{26A0}\u{FE0F}", "yellow")
    };

    println!("{} {}/{} Up | color={}", icon, up_count, total, color);
    println!("---");

    // Individual site status
    for r in &results {
        if r.up {
            println!("\u{2705} {} - {}ms", r.name, r.latency_ms);
        } else {
            println!("\u{274C} {} - {} | color=red", r.name, r.error);
        }
    }

    println!("---");
    println!("Refresh | refresh=true");
}

fn check_sites() -> Vec<SiteStatus> {
    SITES.iter().map(|(name, host, port, path)| {
        check_site(name, host, *port, path)
    }).collect()
}

fn check_site(name: &'static str, host: &str, port: u16, path: &str) -> SiteStatus {
    let start = Instant::now();

    // Connect using hostname:port (ToSocketAddrs trait handles DNS)
    let addr = format!("{}:{}", host, port);

    match TcpStream::connect(&addr) {
        Ok(mut stream) => {
            stream.set_read_timeout(Some(Duration::from_secs(5))).ok();
            stream.set_write_timeout(Some(Duration::from_secs(5))).ok();

            // Send HTTP request
            let request = format!(
                "GET {} HTTP/1.1\r\nHost: {}\r\nConnection: close\r\n\r\n",
                path, host
            );

            if stream.write_all(request.as_bytes()).is_err() {
                return SiteStatus {
                    name,
                    up: false,
                    latency_ms: 0,
                    error: "Write failed".to_string(),
                };
            }

            // Read response
            let mut response = [0u8; 1024];
            match stream.read(&mut response) {
                Ok(n) if n > 0 => {
                    let latency = start.elapsed().as_millis();
                    let response_str = String::from_utf8_lossy(&response[..n]);
                    let up = response_str.contains("HTTP/1.") &&
                             (response_str.contains(" 200 ") ||
                              response_str.contains(" 301 ") ||
                              response_str.contains(" 302 "));

                    SiteStatus {
                        name,
                        up,
                        latency_ms: latency,
                        error: String::new(),
                    }
                }
                _ => SiteStatus {
                    name,
                    up: false,
                    latency_ms: 0,
                    error: "No response".to_string(),
                }
            }
        }
        Err(e) => SiteStatus {
            name,
            up: false,
            latency_ms: 0,
            error: format!("{}", e),
        }
    }
}
