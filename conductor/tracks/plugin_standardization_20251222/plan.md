# Implementation Plan: Standardize Example Plugins and GUI Consistency

## Phase 1: Directory Restructuring & Discovery Logic [checkpoint: 7c9435a]
Goal: Organize the `plugins/` folder and update the system to discover plugins within subdirectories.

- [x] Task: Create subdirectories for all existing plugins in the `plugins/` folder. ec87ea5
- [x] Task: Move existing plugin files into their respective subdirectories. ec87ea5
- [x] Task: Update `PluginManager` (in `crossbar_core` or `crossbar_cli`) to support recursive discovery or specific folder-based discovery. 8d50254
- [x] Task: Write tests in `plugin_manager_test.dart` to verify that plugins in subdirectories are correctly detected. 8d50254
- [x] Task: Conductor - User Manual Verification 'Phase 1: Directory Restructuring' (Protocol in workflow.md) ec87ea5

## Phase 2: Showcase Plugins (Battery & Uptime) [checkpoint: 3853b37]
Goal: Implement the showcase plugins in all 7 supported languages.

- [x] Task: Standardize `plugins/battery/` to include: `.lua`, `.sh`, `.py`, `.dart`, `.js`, `.go`, `.rs`. 1f4d48d
- [x] Task: Standardize `plugins/uptime/` to include: `.lua`, `.sh`, `.py`, `.dart`, `.js`, `.go`, `.rs`. bf49297
- [x] Task: Verify that all showcase scripts execute and produce valid Crossbar/BitBar output using `crossbar run <plugin_path>`. 8a34532
- [x] Task: Conductor - User Manual Verification 'Phase 2: Showcase Plugins' (Protocol in workflow.md) 8a34532

## Phase 3: Baseline Standardization & Legacy Porting [checkpoint: 96ae9cd]
Goal: Ensure every plugin has at least Lua and Bash versions, and remove non-standard versions.

- [x] Task: Identify plugins missing Lua or Bash versions. 5660b47
- [x] Task: Port missing versions to Lua (using `crossbar` API) and Bash. 5660b47
- [x] Task: Delete original non-standard language files (Python, Go, etc.) for plugins that are not `battery` or `uptime`. 5660b47
- [x] Task: Verify all standardized plugins in `plugins/` directory have both `.lua` and `.sh` files. 5660b47
- [x] Task: Conductor - User Manual Verification 'Phase 3: Baseline Standardization' (Protocol in workflow.md) 5660b47

## Phase 4: GUI Dynamic Language Selection
Goal: Update the Flutter GUI to dynamically populate the language dropdown from the plugin folder.

- [ ] Task: Modify the Plugin UI model/view-model to scan the directory of a plugin for all supported file extensions.
- [ ] Task: Update the "Language" dropdown in `lib/ui/tabs/plugins_tab.dart` (or relevant widget) to use this dynamic list.
- [ ] Task: Implement/Verify that the `RefreshService` trigger updates the available language list for the selected plugin.
- [ ] Task: Add a widget test to verify the dropdown updates when the file system changes.
- [ ] Task: Conductor - User Manual Verification 'Phase 4: GUI Dynamic Selection' (Protocol in workflow.md)
