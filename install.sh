#!/bin/sh
# Crossbar installer - https://github.com/verseles/crossbar
# Usage (Linux/macOS): curl -fsSL https://install.cat/verseles/crossbar | sh
set -eu

REPO="verseles/crossbar"
APP_ID="com.verseles.crossbar"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/crossbar"
BIN_DIR="$HOME/.local/bin"
ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
PLUGINS_DIR="$HOME/.crossbar/plugins"
MAC_APPS_DIR="$HOME/Applications"

PLATFORM=""
ARCH=""
ASSET=""
VERSION=""
RELEASE_JSON=""
TMP=""
MAC_APP_DEST=""

# ---------- helpers ----------

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m::\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m::\033[0m %s\n' "$*" >&2; exit 1; }

fetch() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$1"
  else
    err "Neither curl nor wget found"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || err "Required command not found: $1"
}

# ---------- platform/release ----------

detect_platform() {
  os="$(uname -s)"
  raw_arch="$(uname -m)"

  case "$os" in
    Linux) PLATFORM="linux" ;;
    Darwin) PLATFORM="macos" ;;
    *) err "Unsupported OS: $os (only Linux and macOS are supported). For Windows use install.ps1." ;;
  esac

  case "$raw_arch" in
    x86_64|amd64) ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) err "Unsupported architecture: $raw_arch" ;;
  esac

  ASSET="crossbar-${PLATFORM}-${ARCH}.tar.gz"
  info "Detected: $PLATFORM ($ARCH)"
}

get_latest_release() {
  RELEASE_JSON="$(fetch "https://api.github.com/repos/$REPO/releases/latest")"
  VERSION="$(printf '%s' "$RELEASE_JSON" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$VERSION" ] || err "Could not determine latest release version."
  info "Latest version: $VERSION"
}

release_has_asset() {
  printf '%s\n' "$RELEASE_JSON" | grep -F "\"name\": \"$1\"" >/dev/null 2>&1
}

print_available_assets() {
  printf '%s\n' "$RELEASE_JSON" | sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' | grep '^crossbar-' || true
}

# ---------- download/extract ----------

download_release() {
  if ! release_has_asset "$ASSET"; then
    err "Asset '$ASSET' not found in release $VERSION.
Available assets:
$(print_available_assets)"
  fi

  TMPDIR="${TMPDIR:-/tmp}"
  TMP="$TMPDIR/crossbar-install-$$"
  mkdir -p "$TMP"
  trap 'rm -rf "$TMP"' EXIT

  URL="https://github.com/$REPO/releases/download/$VERSION/$ASSET"
  info "Downloading $ASSET..."
  fetch "$URL" > "$TMP/$ASSET" || err "Download failed: $ASSET"

  info "Extracting..."
  tar -xzf "$TMP/$ASSET" -C "$TMP"
}

# ---------- Linux install ----------

install_linux() {
  info "Installing Linux bundle to $INSTALL_DIR..."

  mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$ICONS_DIR/128x128/apps" "$ICONS_DIR/256x256/apps" "$ICONS_DIR/symbolic/apps" "$APPS_DIR" "$PLUGINS_DIR"

  cp -r "$TMP"/* "$INSTALL_DIR/" 2>/dev/null || true
  rm -f "$INSTALL_DIR/$ASSET"

  chmod +x "$INSTALL_DIR/crossbar" 2>/dev/null || true
  chmod +x "$INSTALL_DIR/crossbar-gui" 2>/dev/null || true
  chmod +x "$INSTALL_DIR/crossbar_tray_daemon" 2>/dev/null || true

  ln -sf "$INSTALL_DIR/crossbar" "$BIN_DIR/crossbar"

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

  ASSETS="$INSTALL_DIR/data/flutter_assets/assets/icons"
  if [ -d "$ASSETS" ]; then
    [ -f "$ASSETS/icon_linux.png" ] && cp "$ASSETS/icon_linux.png" "$ICONS_DIR/128x128/apps/$APP_ID.png"
    [ -f "$ASSETS/icon_linux.png" ] && cp "$ASSETS/icon_linux.png" "$ICONS_DIR/256x256/apps/$APP_ID.png"
    [ -f "$ASSETS/$APP_ID-symbolic.svg" ] && cp "$ASSETS/$APP_ID-symbolic.svg" "$ICONS_DIR/symbolic/apps/"
  fi

  gtk-update-icon-cache "$ICONS_DIR" 2>/dev/null || true
}

# ---------- macOS install ----------

install_macos() {
  info "Installing macOS app bundle..."

  APP_SRC="$TMP/crossbar.app"
  [ -d "$APP_SRC" ] || err "crossbar.app not found in archive."

  MAC_APP_DEST="$MAC_APPS_DIR/Crossbar.app"
  mkdir -p "$MAC_APPS_DIR" "$BIN_DIR" "$PLUGINS_DIR"
  rm -rf "$MAC_APP_DEST"
  cp -R "$APP_SRC" "$MAC_APP_DEST"
  # Remove macOS quarantine attribute so Gatekeeper does not block the app.
  xattr -cr "$MAC_APP_DEST" 2>/dev/null || true

  chmod +x "$MAC_APP_DEST/Contents/MacOS/crossbar" 2>/dev/null || true
  chmod +x "$MAC_APP_DEST/Contents/MacOS/crossbar-gui" 2>/dev/null || true

  ln -sf "$MAC_APP_DEST/Contents/MacOS/crossbar" "$BIN_DIR/crossbar"
}

# ---------- post-install ----------

verify() {
  case "$PLATFORM" in
    linux)
      [ -x "$BIN_DIR/crossbar" ] || err "Installation failed: $BIN_DIR/crossbar not found."
      ;;
    macos)
      [ -x "$BIN_DIR/crossbar" ] || err "Installation failed: $BIN_DIR/crossbar not found."
      [ -d "$MAC_APP_DEST" ] || err "Installation failed: $MAC_APP_DEST not found."
      ;;
  esac

  ok "Crossbar $VERSION installed successfully."

  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
      echo ""
      info "Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
      echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
      ;;
  esac

  echo ""
  if [ "$PLATFORM" = "macos" ]; then
    ok "Run 'crossbar' in terminal, or open '$MAC_APP_DEST'."
  else
    ok "Run 'crossbar' to start, or find 'Crossbar' in your app menu."
  fi
  echo ""
}

print_uninstall() {
  info "To uninstall later:"
  echo "  rm -f \"$BIN_DIR/crossbar\""
  if [ "$PLATFORM" = "linux" ]; then
    echo "  rm -rf \"$INSTALL_DIR\""
    echo "  rm -f \"$APPS_DIR/$APP_ID.desktop\""
    echo "  rm -f \"$ICONS_DIR/128x128/apps/$APP_ID.png\""
    echo "  rm -f \"$ICONS_DIR/256x256/apps/$APP_ID.png\""
    echo "  rm -f \"$ICONS_DIR/symbolic/apps/$APP_ID-symbolic.svg\""
  else
    echo "  rm -rf \"$MAC_APP_DEST\""
  fi
  echo "  # User data preserved in ~/.crossbar/"
}

# ---------- main ----------

main() {
  echo ""
  info "Crossbar Installer"
  echo ""

  require_cmd tar
  detect_platform
  get_latest_release
  download_release

  if [ "$PLATFORM" = "linux" ]; then
    install_linux
  else
    install_macos
  fi

  verify
  print_uninstall
  echo ""
}

main "$@"
