.PHONY: all linux macos windows android clean test analyze setup-linux setup-macos setup-windows mix

# Paths
LINUX_BUNDLE = build/linux/x64/release/bundle
MACOS_BUNDLE = build/macos/Build/Products/Release/crossbar.app/Contents/MacOS
WINDOWS_BUNDLE = build/windows/x64/runner/Release

# Default target
all: linux

# Linux build with launcher architecture
linux:
	@echo "Building Flutter GUI..."
	flutter build linux --release
	@echo "Setting up launcher architecture..."
	mv $(LINUX_BUNDLE)/crossbar $(LINUX_BUNDLE)/crossbar-gui
	dart compile exe bin/crossbar.dart -o $(LINUX_BUNDLE)/crossbar-cli
	dart compile exe bin/launcher.dart -o $(LINUX_BUNDLE)/crossbar
	@echo "Done! Binaries at $(LINUX_BUNDLE)/"
	@ls -lh $(LINUX_BUNDLE)/crossbar*

# macOS build with launcher architecture
macos:
	@echo "Building Flutter GUI..."
	flutter build macos --release
	@echo "Setting up launcher architecture..."
	mv $(MACOS_BUNDLE)/crossbar $(MACOS_BUNDLE)/crossbar-gui
	dart compile exe bin/crossbar.dart -o $(MACOS_BUNDLE)/crossbar-cli
	dart compile exe bin/launcher.dart -o $(MACOS_BUNDLE)/crossbar
	@echo "Done! Binaries at $(MACOS_BUNDLE)/"

# Windows build with launcher architecture
windows:
	@echo "Building Flutter GUI..."
	flutter build windows --release
	@echo "Setting up launcher architecture..."
	mv $(WINDOWS_BUNDLE)/crossbar.exe $(WINDOWS_BUNDLE)/crossbar-gui.exe
	dart compile exe bin/crossbar.dart -o $(WINDOWS_BUNDLE)/crossbar-cli.exe
	dart compile exe bin/launcher.dart -o $(WINDOWS_BUNDLE)/crossbar.exe
	@echo "Done! Binaries at $(WINDOWS_BUNDLE)/"

# Android build
android:
	flutter build apk --release
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
	@if [ -f repomix-output.xml ]; then npx repomix; fi
