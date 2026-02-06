#!/bin/sh
# Crossbar installer - https://github.com/verseles/crossbar
# Usage: curl -fsSL https://install.cat/verseles/crossbar | sh
set -e

REPO="verseles/crossbar"
APP_ID="com.verseles.crossbar"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/crossbar"
BIN_DIR="$HOME/.local/bin"
ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
PLUGINS_DIR="$HOME/.crossbar/plugins"

# ---------- helpers ----------

info()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m::\033[0m %s\n' "$*"; }
err()   { printf '\033[1;31m::\033[0m %s\n' "$*" >&2; exit 1; }

need() {
  command -v "$1" >/dev/null 2>&1 || err "Required: $1 (not found in PATH)"
}

fetch() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$1"
  else
    err "Neither curl nor wget found"
  fi
}

# ---------- detect platform ----------

detect_platform() {
  OS="$(uname -s)"
  ARCH="$(uname -m)"

  case "$OS" in
    Linux)  PLATFORM="linux" ;;
    Darwin) PLATFORM="macos" ;;
    *)      err "Unsupported OS: $OS (only Linux and macOS are supported)" ;;
  esac

  case "$ARCH" in
    x86_64|amd64)   ARCH="x64" ;;
    aarch64|arm64)   ARCH="arm64" ;;
    *)               err "Unsupported architecture: $ARCH" ;;
  esac

  info "Detected: $PLATFORM ($ARCH)"
}

# ---------- find latest release ----------

get_latest_version() {
  VERSION=$(fetch "https://api.github.com/repos/$REPO/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')

  [ -n "$VERSION" ] || err "Could not determine latest version"
  info "Latest version: $VERSION"
}

# ---------- download & extract ----------

download_release() {
  ASSET="crossbar-${PLATFORM}-${ARCH}.tar.gz"
  URL="https://github.com/$REPO/releases/download/$VERSION/$ASSET"

  TMPDIR="${TMPDIR:-/tmp}"
  TMP="$TMPDIR/crossbar-install-$$"
  mkdir -p "$TMP"
  trap 'rm -rf "$TMP"' EXIT

  info "Downloading $ASSET..."
  fetch "$URL" > "$TMP/$ASSET" || err "Download failed. Asset '$ASSET' may not exist for $VERSION.
  Check https://github.com/$REPO/releases for available downloads."

  info "Extracting..."
  tar -xzf "$TMP/$ASSET" -C "$TMP"
}

# ---------- install ----------

install_files() {
  info "Installing to $INSTALL_DIR..."

  mkdir -p "$INSTALL_DIR"
  mkdir -p "$BIN_DIR"
  mkdir -p "$ICONS_DIR/128x128/apps"
  mkdir -p "$ICONS_DIR/256x256/apps"
  mkdir -p "$ICONS_DIR/symbolic/apps"
  mkdir -p "$APPS_DIR"
  mkdir -p "$PLUGINS_DIR"

  # Copy bundle
  cp -r "$TMP"/* "$INSTALL_DIR/" 2>/dev/null || true
  # Remove the tarball if it ended up in the install dir
  rm -f "$INSTALL_DIR/$ASSET"

  # Ensure executables are executable
  chmod +x "$INSTALL_DIR/crossbar" 2>/dev/null || true
  chmod +x "$INSTALL_DIR/crossbar-gui" 2>/dev/null || true
  chmod +x "$INSTALL_DIR/crossbar_tray_daemon" 2>/dev/null || true

  # Symlink CLI to bin
  ln -sf "$INSTALL_DIR/crossbar" "$BIN_DIR/crossbar"

  # Desktop entry
  cat > "$APPS_DIR/$APP_ID.desktop" << DESKTOP
[Desktop Entry]
Type=Application
Name=Crossbar
Comment=Universal Plugin System for Taskbar/Menu Bar
Icon=$APP_ID
Exec=$INSTALL_DIR/crossbar-gui
Categories=Utility;System;
Terminal=false
StartupWMClass=$APP_ID
Keywords=plugins;tray;menubar;bitbar;argos;
DESKTOP

  # Icons (from bundle's flutter_assets)
  ASSETS="$INSTALL_DIR/data/flutter_assets/assets/icons"
  if [ -d "$ASSETS" ]; then
    [ -f "$ASSETS/icon_linux.png" ] && cp "$ASSETS/icon_linux.png" "$ICONS_DIR/128x128/apps/$APP_ID.png"
    [ -f "$ASSETS/icon_linux.png" ] && cp "$ASSETS/icon_linux.png" "$ICONS_DIR/256x256/apps/$APP_ID.png"
    [ -f "$ASSETS/$APP_ID-symbolic.svg" ] && cp "$ASSETS/$APP_ID-symbolic.svg" "$ICONS_DIR/symbolic/apps/"
  fi

  # Update icon cache
  gtk-update-icon-cache "$ICONS_DIR" 2>/dev/null || true
}

# ---------- verify ----------

verify() {
  if [ -x "$BIN_DIR/crossbar" ]; then
    ok "Crossbar $VERSION installed successfully!"
  else
    err "Installation failed - binary not found at $BIN_DIR/crossbar"
  fi

  # Check PATH
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
      echo ""
      info "Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
      echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
      ;;
  esac

  echo ""
  ok "Run 'crossbar' to start, or find 'Crossbar' in your app menu."
  echo ""
}

# ---------- uninstall instructions ----------

print_uninstall() {
  info "To uninstall later:"
  echo "  rm -rf \"$INSTALL_DIR\""
  echo "  rm -f \"$BIN_DIR/crossbar\""
  echo "  rm -f \"$APPS_DIR/$APP_ID.desktop\""
  echo "  rm -f \"$ICONS_DIR/128x128/apps/$APP_ID.png\""
  echo "  rm -f \"$ICONS_DIR/256x256/apps/$APP_ID.png\""
  echo "  rm -f \"$ICONS_DIR/symbolic/apps/$APP_ID-symbolic.svg\""
  echo "  # User data preserved in ~/.crossbar/"
}

# ---------- main ----------

main() {
  echo ""
  info "Crossbar Installer"
  echo ""

  detect_platform
  get_latest_version
  download_release
  install_files
  verify
  print_uninstall
  echo ""
}

main "$@"
