# Track Spec: Standardize Example Plugins and GUI Consistency

## Overview
Currently, the `plugins/` directory is inconsistent. Some plugins exist in multiple languages while others do not, and the GUI only shows language selection options for a few. This track aims to standardize the example plugin library, providing a clean "Subdirectory per Plugin" structure and ensuring a consistent baseline of languages (Lua and Bash) for all examples, plus two "Showcase" plugins that demonstrate all supported interpreters.

## Functional Requirements
1.  **Directory Restructuring**:
    *   Move every plugin into its own subdirectory within `plugins/` (e.g., `plugins/cpu/cpu.10s.sh`).
    *   The subdirectory name should match the base name of the plugin.
2.  **GUI Dynamic Detection**:
    *   The Crossbar GUI MUST populate the "Language" dropdown for a plugin by scanning its specific subdirectory.
    *   It must verify which extensions (`.lua`, `.sh`, `.py`, etc.) are present in that folder to build the list of available languages dynamically.
    *   **Automatic Refresh:** Any changes to the folder contents (e.g., adding a file) must be reflected in the GUI upon the next refresh/load, without requiring a restart.
3.  **Language Standardization (Baseline)**:
    *   Every example plugin MUST have at least a **Lua** (`.lua`) version and a **Bash** (`.sh`) version.
    *   Lua is the default for cross-platform compatibility; Bash is for BitBar/Argos compatibility.
4.  **Showcase Plugins**:
    *   Two specific plugins, **`battery`** and **`uptime`**, MUST be implemented in ALL languages supported by Crossbar:
        *   Lua, Python, Bash, Dart, Go, Rust, and JavaScript (JS).
5.  **Legacy Migration & Cleanup**:
    *   Existing plugins that are NOT in Lua or Bash (and are not part of the showcase set) must be ported to Lua and/or Bash.
    *   The original non-standard versions (e.g., a standalone Python `bitcoin` plugin) will be deleted after migration.

## Non-Functional Requirements
*   **Code Quality**: Ported scripts must be idiomatic to their respective languages.
*   **Portability**: Lua versions must use the `crossbar` global API (ADR-006/ADR-010) to ensure they work on both Desktop and Mobile.

## Acceptance Criteria
- [ ] Every folder in `plugins/` contains at least a `.lua` and a `.sh` file.
- [ ] `plugins/battery/` and `plugins/uptime/` contain versions for all 7 supported languages.
- [ ] No standalone plugin files remain in the root of the `plugins/` directory.
- [ ] The GUI "Language" dropdown is dynamically populated based on the files in the plugin's folder.
- [ ] Adding a new language version to a folder and hitting "Refresh" updates the dropdown options immediately.
- [ ] All ported plugins are functional and pass basic manual verification.

## Out of Scope
*   Adding new functionality to the plugins (only porting existing logic).
*   Implementing mobile-specific widgets for every language (interpreted languages like Python/JS remain Desktop-only as per ADR-003).
