# Specification: Implement CLI Gaps for v1.5.0

## 1. Goal
Implement the missing CLI commands defined in the v1.5.0 roadmap: `crossbar location` (Geolocation) and `crossbar qr` (QR Code generation). This completes the "API Gaps" epic.

## 2. Features

### 2.1 Geolocation (`crossbar location`)
*   **Command:** `crossbar location [options]`
*   **Behavior:**
    *   Returns the current location of the device.
    *   Prioritizes high-accuracy methods (if permission granted) but falls back to IP-based location (`ipapi.co`).
    *   Supports reverse geocoding (Lat/Long -> City/Country).
*   **Options:**
    *   `--json`: Returns structured JSON output.
    *   `--ip`: Forces IP-based geolocation.
*   **Output (Text):** "São Paulo, Brazil (via IP)"
*   **Output (JSON):**
    ```json
    {
      "city": "São Paulo",
      "country": "Brazil",
      "lat": -23.55,
      "lon": -46.63,
      "source": "ip"
    }
    ```

### 2.2 QR Code (`crossbar qr`)
*   **Command:** `crossbar qr <text> [options]`
*   **Behavior:**
    *   Generates a QR code from the provided text.
    *   Default: Prints ASCII QR code to the terminal.
*   **Options:**
    *   `--image`: Returns a base64 encoded PNG string of the QR code.
    *   `--size <int>`: Sets the size of the QR code (default: 200).
*   **Output (ASCII):** (Visual ASCII block)
*   **Output (Image):** `data:image/png;base64,iVBORw0K...`

## 3. Technical Implementation
*   **Geolocation:**
    *   Package: `geolocator` (Flutter) or HTTP request to `ipapi.co` (Pure Dart CLI).
    *   **Constraint:** Since the CLI is a pure Dart binary (see ADR-011), it CANNOT use `package:geolocator` directly if it depends on Flutter plugins.
    *   **Solution:**
        *   **CLI Mode:** Use IP-based geolocation via HTTP.
        *   **GUI Mode (Optional):** If running inside the Flutter app, use `geolocator`.
        *   **Decision:** For v1.5.0 CLI, strictly implement **IP-based geolocation** using `package:http` or `dio`.
*   **QR Code:**
    *   Package: `qr_flutter` or `barcode` (pure Dart).
    *   **Constraint:** Must be pure Dart for CLI. Use `package:barcode` or similar pure Dart generator.

## 4. Quality Assurance
*   Unit tests for location parsing.
*   Unit tests for QR generation (snapshot tests for ASCII/Base64).
*   Mock HTTP requests for IP location to avoid external dependencies in tests.
