/// Model class for tray menu items.
///
/// Used by TrayBackend implementations to represent menu items
/// in a cross-platform way without depending on specific packages.
class TrayMenuItem {
  /// Creates a regular menu item.
  const TrayMenuItem({
    required this.label,
    this.key,
    this.disabled = false,
    this.submenu,
    this.onClicked,
  }) : isSeparator = false;

  /// Creates a separator menu item.
  const TrayMenuItem.separator()
      : label = '',
        key = null,
        disabled = false,
        isSeparator = true,
        submenu = null,
        onClicked = null;

  /// The label displayed for this menu item.
  final String label;

  /// Optional key identifier for the menu item.
  final String? key;

  /// Whether this menu item is disabled.
  final bool disabled;

  /// Whether this is a separator line.
  final bool isSeparator;

  /// Submenu items, if this is a submenu.
  final List<TrayMenuItem>? submenu;

  /// Callback when menu item is clicked.
  final void Function()? onClicked;

  /// Returns true if this item has a submenu.
  bool get hasSubmenu => submenu != null && submenu!.isNotEmpty;
}
