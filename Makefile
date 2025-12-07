.PHONY: all linux macos windows android clean test analyze setup-linux setup-macos setup-windows mix icons \
	install uninstall \
	docker-build docker-shell docker-test docker-linux podman-build podman-shell podman-test podman-linux

# Paths
LINUX_BUNDLE = build/linux/x64/release/bundle
MACOS_BUNDLE = build/macos/Build/Products/Release/crossbar.app/Contents/MacOS
WINDOWS_BUNDLE = build/windows/x64/runner/Release

# Default target
all: linux

# Linux build with unified CLI entry point
# Architecture: crossbar (CLI + launcher) + crossbar-gui (Flutter)
linux:
	@echo "Building Flutter GUI..."
	flutter build linux --release
	@echo "Setting up unified architecture..."
	mv $(LINUX_BUNDLE)/crossbar $(LINUX_BUNDLE)/crossbar-gui
	@echo "Compiling unified CLI..."
	dart compile exe bin/crossbar.dart -o $(LINUX_BUNDLE)/crossbar
	@echo "Copying desktop integration files..."
	cp linux/com.verseles.crossbar.desktop $(LINUX_BUNDLE)/
	cp assets/icons/icon_linux.png $(LINUX_BUNDLE)/crossbar.png
	@echo "Done! Binaries at $(LINUX_BUNDLE)/"
	@echo ""
	@echo "  crossbar     - CLI + launcher (runs GUI if no args)"
	@echo "  crossbar-gui - Flutter GUI application"
	@echo ""
	@ls -lh $(LINUX_BUNDLE)/crossbar*


# Install Crossbar on Linux (after build)
# Installs to ~/.local/ for user-level installation
INSTALL_DIR = $(HOME)/.local
install:
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
	@echo "  export PATH=\"\$$HOME/.local/bin:\$$PATH\""
	@echo ""
	@echo "You can now run 'crossbar' from anywhere."
	@echo "A desktop entry has been created - search for 'Crossbar' in your app menu."

# Uninstall Crossbar
uninstall:
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


# macOS build with unified CLI entry point
macos:
	@echo "Building Flutter GUI..."
	flutter build macos --release
	@echo "Setting up unified architecture..."
	mv $(MACOS_BUNDLE)/crossbar $(MACOS_BUNDLE)/crossbar-gui
	dart compile exe bin/crossbar.dart -o $(MACOS_BUNDLE)/crossbar
	@echo "Done! Binaries at $(MACOS_BUNDLE)/"

# Windows build with unified CLI entry point
windows:
	@echo "Building Flutter GUI..."
	flutter build windows --release
	@echo "Setting up unified architecture..."
	mv $(WINDOWS_BUNDLE)/crossbar.exe $(WINDOWS_BUNDLE)/crossbar-gui.exe
	dart compile exe bin/crossbar.dart -o $(WINDOWS_BUNDLE)/crossbar.exe
	@echo "Done! Binaries at $(WINDOWS_BUNDLE)/"

# Android build
android:
	flutter build apk --release && tdl up -t 6 --path=./build/app/outputs/flutter-apk/app-release.apk
	@echo "Done! APK at build/app/outputs/flutter-apk/app-release.apk"

# Run tests
test:
	flutter test

# Analyze code
analyze:
	flutter analyze --no-fatal-infos

# Clean build artifacts
clean:
	flutter clean
	rm -rf build/

# Install dependencies
deps:
	flutter pub get

# Quick test of CLI (after linux build)
test-cli:
	@echo "Testing CLI mode:"
	$(LINUX_BUNDLE)/crossbar --cpu
	@echo ""
	@echo "Testing --version:"
	$(LINUX_BUNDLE)/crossbar --version

# Run GUI (after linux build)
run-gui:
	$(LINUX_BUNDLE)/crossbar

# Full rebuild
rebuild: clean linux

# Mix (update repomix if exists)
mix:
	@if [ -f repomix-output.xml ]; then npx repomix --truncate-base64 --include-logs --top-files-len 20; fi

# Generate all icons from source files (requires imagemagick)
# Source: assets/icons/icon.png (transparent) and icon_opaque.png (with background)
icons:
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
	@echo "Generating launcher icons (Android, Windows, macOS)..."
	dart run flutter_launcher_icons
	@echo "Done! All icons generated."

# ===============================
# Docker/Podman Container Commands
# ===============================

# Detect compose command (prefer podman-compose on systems with podman)
COMPOSE := $(shell command -v podman-compose 2>/dev/null || command -v docker-compose 2>/dev/null || echo "docker compose")

# Docker commands
docker-build:
	docker compose build

docker-shell:
	docker compose run --rm flutter-linux bash

docker-test:
	docker compose run --rm flutter-test

docker-linux:
	docker compose run --rm flutter-build

docker-android:
	docker compose run --rm flutter-apk

# Podman commands
podman-build:
	podman-compose build

podman-shell:
	podman-compose run --rm flutter-linux bash

podman-test:
	podman-compose run --rm flutter-test

podman-linux:
	podman-compose run --rm flutter-build

podman-android:
	podman-compose run --rm flutter-apk

# Generic container commands (auto-detect compose)
container-build:
	$(COMPOSE) build

container-shell:
	$(COMPOSE) run --rm flutter-linux bash

container-test:
	$(COMPOSE) run --rm flutter-test

container-linux:
	$(COMPOSE) run --rm flutter-build

container-android:
	$(COMPOSE) run --rm flutter-apk
