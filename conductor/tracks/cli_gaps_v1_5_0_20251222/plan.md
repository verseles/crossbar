# Plan: Implement CLI Gaps for v1.5.0

## Phase 1: Infrastructure & Dependencies

- [ ] Task: Add dependencies
  -   Add `http` (or verify existing) for IP Geolocation.
  -   Add `barcode` (pure Dart) or equivalent for QR generation.
  -   Run `flutter pub get`.
  -   **Verify:** Check `pubspec.yaml` and run `make analyze`.

## Phase 2: Geolocation Command (`crossbar location`)

- [ ] Task: Create `LocationService` (Pure Dart)
  -   **Sub-task:** Create `lib/core/services/location_service.dart`.
  -   **Sub-task:** Implement `getLocation()` using `ipapi.co` (or similar free API).
  -   **Sub-task:** Implement error handling (timeout, no network).
  -   **Test:** Write unit tests mocking the HTTP client.

- [ ] Task: Implement `crossbar location` CLI Handler
  -   **Sub-task:** Update `lib/cli/cli_handler.dart`.
  -   **Sub-task:** Add `location` case.
  -   **Sub-task:** Handle `--json` flag.
  -   **Test:** Integration test in `test/functional/cli_location_test.dart`.

- [ ] Task: Conductor - User Manual Verification 'Geolocation Command' (Protocol in workflow.md)

## Phase 3: QR Code Command (`crossbar qr`)

- [ ] Task: Create `QrService` (Pure Dart)
  -   **Sub-task:** Create `lib/core/services/qr_service.dart`.
  -   **Sub-task:** Implement `generateAscii(String text)`.
  -   **Sub-task:** Implement `generateBase64(String text)` (requires image encoding lib if not present).
  -   **Test:** Unit tests verifying string output format.

- [ ] Task: Implement `crossbar qr` CLI Handler
  -   **Sub-task:** Update `lib/cli/cli_handler.dart`.
  -   **Sub-task:** Add `qr` case.
  -   **Sub-task:** Handle `--image` and `--size` flags.
  -   **Test:** Integration test in `test/functional/cli_qr_test.dart`.

- [ ] Task: Conductor - User Manual Verification 'QR Code Command' (Protocol in workflow.md)

## Phase 4: Finalization

- [ ] Task: Documentation
  -   Update `docs/api-reference.md` with new commands.
  -   Update `README.md` (Features section).

- [ ] Task: Final Quality Gate
  -   Run `make precommit`.
  -   Verify code coverage >60%.

- [ ] Task: Conductor - User Manual Verification 'Finalization' (Protocol in workflow.md)
