/// Common interface for all tray backends
/// This abstraction allows switching between different tray implementations
/// (e.g., StatusNotifierItem vs Legacy GtkStatusIcon) at runtime.
abstract class TrayBackend {
  /// Initialize the backend
  /// Returns true if initialization was successful
  Future<bool> init();

  /// Update the system tray menu
  Future<void> updateMenu(List<TrayMenuItem> items);

  /// Update the tray icon
  Future<void> updateIcon(String iconPath);

  /// Update the tray title (tooltip)
  Future<void> updateTitle(String title);

  /// Set tooltip text (may not be supported on all platforms)
  Future<void> setTooltip(String tooltip);

  /// Cleanup resources
  Future<void> dispose();

  /// Backend capabilities
  bool get supportsMultipleIcons;
  bool get supportsTitle;
  bool get supportsTooltip;
  String get backendName;
}

/// Menu item representation for tray backends
/// Renamed from MenuItem to TrayMenuItem to avoid conflict with tray_manager
class TrayMenuItem {
  final String label;
  final bool disabled;
  final bool separator;
  final String? key;
  final List<TrayMenuItem>? submenu;

  const TrayMenuItem({
    required this.label,
    this.disabled = false,
    this.separator = false,
    this.key,
    this.submenu,
  });

  factory TrayMenuItem.separator() => const TrayMenuItem(
    label: '',
    separator: true,
  );

  factory TrayMenuItem.submenu({
    required String label,
    required List<TrayMenuItem> submenu,
    String? key,
  }) =>
      TrayMenuItem(
        label: label,
        submenu: submenu,
        key: key,
      );
}
