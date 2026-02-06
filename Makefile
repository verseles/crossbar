.PHONY: all coverage linux macos windows android clean test analyze setup-linux setup-macos setup-windows mix icons \
	install install-linux uninstall precommit help

.DEFAULT_GOAL := help

# Paths
LINUX_BUNDLE = build/linux/x64/release/bundle
MACOS_BUNDLE = build/macos/Build/Products/Release/crossbar.app/Contents/MacOS
WINDOWS_BUNDLE = build/windows/x64/runner/Release

# Detect OS and set default target
UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
    DEFAULT_TARGET = macos
else ifneq (,$(findstring MINGW,$(UNAME_S)))
    DEFAULT_TARGET = windows
else ifneq (,$(findstring CYGWIN,$(UNAME_S)))
    DEFAULT_TARGET = windows
else ifeq ($(OS),Windows_NT)
    DEFAULT_TARGET = windows
else
    DEFAULT_TARGET = linux
endif

help: ## Show this help
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all: $(DEFAULT_TARGET) ## Build for detected OS (alias for linux/macos/windows)
	@echo "Building for detected OS: $(DEFAULT_TARGET)"

precommit: ## Run full pre-commit sequence (analyze, coverage, linux, android)
	@echo "══════════════════════════════════════════════════════════════"
	@echo "  PRECOMMIT VERIFICATION (AGENTS.md)"
	@echo "══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "Step 1/4: Static Analysis"
	@echo "──────────────────────────────────────────────────────────────"
	$(MAKE) analyze
	@echo ""
	@echo "Step 2/4: Tests with Coverage (target: 35-60%)"
	@echo "──────────────────────────────────────────────────────────────"
	$(MAKE) coverage
	@echo ""
	@echo "Step 3/4: Linux Build"
	@echo "──────────────────────────────────────────────────────────────"
	$(MAKE) linux
	@echo ""
	@echo "Step 4/4: Android Build"
	@echo "──────────────────────────────────────────────────────────────"
	$(MAKE) android
	@echo ""
	@echo "══════════════════════════════════════════════════════════════"
	@echo "  ✅ PRECOMMIT PASSED - Safe to commit!"
	@echo "══════════════════════════════════════════════════════════════"

linux: ## Build for Linux (Flutter GUI + CLI + Tray Daemon)
	@echo "Building Flutter GUI..."
	flutter build linux --release
	@echo "Setting up unified architecture..."
	mv $(LINUX_BUNDLE)/crossbar $(LINUX_BUNDLE)/crossbar-gui
	@echo "Compiling unified CLI from packages/crossbar_cli..."
	cd packages/crossbar_cli && dart compile exe bin/crossbar.dart -o ../../$(LINUX_BUNDLE)/crossbar
	@echo "Compiling tray daemon for multi-icon support..."
	dart build cli --target=bin/crossbar_tray_daemon.dart --output=build/tray_daemon_tmp 2>&1 | tail -1
	cp build/tray_daemon_tmp/bundle/bin/crossbar_tray_daemon $(LINUX_BUNDLE)/crossbar_tray_daemon
	rm -rf build/tray_daemon_tmp
	@echo "Copying desktop integration files..."
	cp linux/com.verseles.crossbar.desktop $(LINUX_BUNDLE)/
	cp assets/icons/icon_linux.png $(LINUX_BUNDLE)/crossbar.png
	@echo "Done! Binaries at $(LINUX_BUNDLE)/"
	@echo ""
	@echo "  crossbar             - CLI + launcher (runs GUI if no args)"
	@echo "  crossbar-gui         - Flutter GUI application"
	@echo "  crossbar_tray_daemon - Daemon for multi-icon tray support"
	@echo ""
	@ls -lh $(LINUX_BUNDLE)/crossbar*

install: install-linux ## Install Crossbar to ~/.local/ (Linux only)

install-linux: ## Run checks/builds and install Crossbar to ~/.local/ (Linux only)
	@echo "Running checks and build before install..."
	$(MAKE) analyze
	$(MAKE) coverage
	$(MAKE) linux
	@echo "Installing Crossbar to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)/bin
	@mkdir -p $(INSTALL_DIR)/share/crossbar
	@mkdir -p $(INSTALL_DIR)/share/applications
	@mkdir -p $(INSTALL_DIR)/share/icons/hicolor/128x128/apps
	@mkdir -p $(INSTALL_DIR)/share/icons/hicolor/256x256/apps
	@mkdir -p $(HOME)/.crossbar/plugins
	@# Copy entire bundle
	@cp -r $(LINUX_BUNDLE)/* $(INSTALL_DIR)/share/crossbar/
	@# Create symlink in bin
	@ln -sf $(INSTALL_DIR)/share/crossbar/crossbar $(INSTALL_DIR)/bin/crossbar
	@# Install desktop file with correct paths
	@# Note: Exec points to crossbar-gui directly, file named by APPLICATION_ID for GNOME matching
	@sed 's|Icon=com.verseles.crossbar|Icon=$(INSTALL_DIR)/share/icons/hicolor/128x128/apps/com.verseles.crossbar.png|; s|Exec=.*|Exec=$(INSTALL_DIR)/share/crossbar/crossbar-gui|' \
		linux/com.verseles.crossbar.desktop > $(INSTALL_DIR)/share/applications/com.verseles.crossbar.desktop
	@# Install icons with APPLICATION_ID naming for proper GNOME association
	@cp assets/icons/icon_linux.png $(INSTALL_DIR)/share/icons/hicolor/128x128/apps/com.verseles.crossbar.png
	@cp assets/icons/icon_linux.png $(INSTALL_DIR)/share/icons/hicolor/256x256/apps/com.verseles.crossbar.png
	@# Update icon cache
	@gtk-update-icon-cache $(INSTALL_DIR)/share/icons/hicolor 2>/dev/null || true
	@echo ""
	@echo "✅ Crossbar installed successfully!"
	@echo ""
	@echo "Make sure $(INSTALL_DIR)/bin is in your PATH:"
	@echo "  export PATH=\"$$HOME/.local/bin:$$PATH\""
	@echo ""
	@echo "You can now run 'crossbar' from anywhere."
	@echo "A desktop entry has been created - search for 'Crossbar' in your app menu."

INSTALL_DIR = $(HOME)/.local

uninstall: ## Uninstall Crossbar from ~/.local/
	@echo "Uninstalling Crossbar..."
	@rm -f $(INSTALL_DIR)/bin/crossbar
	@rm -rf $(INSTALL_DIR)/share/crossbar
	@rm -f $(INSTALL_DIR)/share/applications/crossbar.desktop
	@rm -f $(INSTALL_DIR)/share/applications/com.verseles.crossbar.desktop
	@rm -f $(INSTALL_DIR)/share/icons/hicolor/128x128/apps/crossbar.png
	@rm -f $(INSTALL_DIR)/share/icons/hicolor/128x128/apps/com.verseles.crossbar.png
	@rm -f $(INSTALL_DIR)/share/icons/hicolor/256x256/apps/crossbar.png
	@rm -f $(INSTALL_DIR)/share/icons/hicolor/256x256/apps/com.verseles.crossbar.png
	@echo "✅ Crossbar uninstalled. User data in ~/.crossbar/ was preserved."

macos: ## Build for macOS (Flutter GUI + CLI)
	@echo "Building Flutter GUI..."
	flutter build macos --release
	@echo "Setting up unified architecture..."
	mv $(MACOS_BUNDLE)/crossbar $(MACOS_BUNDLE)/crossbar-gui
	@echo "Compiling unified CLI from packages/crossbar_cli..."
	cd packages/crossbar_cli && dart compile exe bin/crossbar.dart -o ../../$(MACOS_BUNDLE)/crossbar
	@echo "Done! Binaries at $(MACOS_BUNDLE)/"

windows: ## Build for Windows (Flutter GUI + CLI)
	@echo "Building Flutter GUI..."
	flutter build windows --release
	@echo "Setting up unified architecture..."
	mv $(WINDOWS_BUNDLE)/crossbar.exe $(WINDOWS_BUNDLE)/crossbar-gui.exe
	@echo "Compiling unified CLI from packages/crossbar_cli..."
	cd packages/crossbar_cli && dart compile exe bin/crossbar.dart -o ../../$(WINDOWS_BUNDLE)/crossbar.exe
	@echo "Done! Binaries at $(WINDOWS_BUNDLE)/"

CAPTION ?=
android: ## Build Android APK (and upload if configured)
	flutter build apk --release --target-platform android-arm64
	@if command -v tdl >/dev/null 2>&1; then \
		VERSION=$$(grep '^version:' pubspec.yaml | cut -d' ' -f2); \
		if [ -n "$(CAPTION)" ]; then \
			tdl up -t 6 -c 5891714407 --path=./build/app/outputs/apk/release/crossbar.apk \
				--caption "\"<b>Crossbar v$$VERSION</b>\\n\\n$(CAPTION)\"" ; \
		else \
			tdl up -t 6 -c 5891714407 --path=./build/app/outputs/apk/release/crossbar.apk \
				--caption "\"<b>Crossbar v$$VERSION</b>\"" ; \
		fi; \
	fi
	@echo "Done! APK at build/app/outputs/apk/release/crossbar.apk"

test: ## Run unit/widget tests (excluding hardware)
	flutter test --exclude-tags=hardware

coverage: ## Run tests with coverage report
	flutter test --exclude-tags=hardware --coverage
	@echo "Filtering generated code from coverage..."
	lcov --remove coverage/lcov.info 'lib/l10n/*' 'lib/ui/dialogs/*' 'lib/core/paths/*' -o coverage/lcov_filtered.info 2>/dev/null
	@echo ""
	@echo "=== Coverage Summary (excluding generated code) ==="
	lcov --summary coverage/lcov_filtered.info 2>&1 | grep -E "lines|source"
	@echo ""
	@echo "Target: 35% (see AGENTS.md for rationale)"

analyze: ## Run static analysis
	flutter analyze --no-fatal-infos

clean: ## Clean build artifacts
	flutter clean
	rm -rf build/

deps: ## Get dependencies
	flutter pub get

test-cli: ## Test CLI binary (requires linux build)
	@echo "Testing CLI mode:"
	$(LINUX_BUNDLE)/crossbar --cpu
	@echo ""
	@echo "Testing --version:"
	$(LINUX_BUNDLE)/crossbar --version

run-gui: ## Run GUI (requires linux build)
	$(LINUX_BUNDLE)/crossbar

rebuild: clean linux ## Clean and rebuild Linux

mix: ## Update repomix (if exists)
	@if [ -f repomix-output.xml ]; then npx repomix --truncate-base64 --include-logs --top-files-len 20; fi

icons: ## Generate icons from assets
	@echo "Generating tray icons..."
	@cd assets/icons && \
	magick icon.png -resize 48x48 -alpha extract mask.png && \
	magick -size 48x48 xc:white mask.png -alpha off -compose CopyOpacity -composite PNG32:tray_icon_light.png && \
	magick -size 48x48 xc:black mask.png -alpha off -compose CopyOpacity -composite PNG32:tray_icon_dark.png && \
	magick -size 44x44 xc:black \( icon.png -resize 44x44 -alpha extract \) -alpha off -compose CopyOpacity -composite PNG32:tray_icon_macos.png && \
	magick icon.png -resize 48x48 -define icon:auto-resize=48,32,16 tray_icon.ico && \
	rm -f mask.png
	@echo "Tray icons generated:"
	@ls -la assets/icons/tray_icon*
	@echo ""
	@echo "Generating Linux icon with rounded corners (squircle style)..."
	@cd assets/icons && \
	magick icon_opaque.png -resize 256x256 \
		\( +clone -alpha extract \
			-draw "fill black polygon 0,0 0,48 48,0 fill white circle 48,48 48,0" \
			\( +clone -flip \) -compose Multiply -composite \
			\( +clone -flop \) -compose Multiply -composite \
		\) -alpha off -compose CopyOpacity -composite PNG32:icon_linux.png
	@echo "Linux icon generated:"
	@ls -la assets/icons/icon_linux.png
	@echo ""
	@echo "Generating monochrome icon for Android Material You..."
	@cd assets/icons && \
	magick icon.png -resize 1024x1024 -alpha extract -negate PNG32:icon_monochrome.png
	@echo "Monochrome icon generated:"
	@ls -la assets/icons/icon_monochrome.png
	@echo ""
	@echo "Generating launcher icons (Android, Windows, macOS)..."
	dart run flutter_launcher_icons
	@echo "Done! All icons generated."
