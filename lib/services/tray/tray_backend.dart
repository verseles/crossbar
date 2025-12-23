import 'tray_menu_item.dart';

/// Abstract interface for tray icon backends.
///
/// This interface allows for multiple implementations:
/// - [SniMultiTrayBackend]: Uses StatusNotifierItem for multiple icons (Linux)
/// - [LegacyTrayBackend]: Uses tray_manager for single icon (cross-platform)
/// - [HybridTrayBackend]: Automatically chooses the best backend with fallback
abstract class TrayBackend {
  /// Initializes the backend.
  ///
  /// Returns `true` if the backend is supported and ready to use.
  /// Returns `false` if the backend is not supported on this system.
  Future<bool> init();

  /// Creates a new tray icon for a plugin.
  ///
  /// Returns the icon ID if successful, or `null` if creation failed.
  /// The [pluginId] is used to uniquely identify this icon.
  /// The [iconPath] can be a file path or icon name (for SNI).
  /// The [tooltip] is displayed when hovering over the icon.
  Future<int?> createIcon({
    required String pluginId,
    required String iconPath,
    required String tooltip,
  });

  /// Updates an existing tray icon.
  ///
  /// The [iconId] must be a valid ID returned by [createIcon].
  /// Only non-null parameters will be updated.
  Future<void> updateIcon({
    required int iconId,
    String? iconPath,
    String? title,
    String? tooltip,
    List<TrayMenuItem>? menu,
  });

  /// Destroys a tray icon and releases its resources.
  ///
  /// The [iconId] must be a valid ID returned by [createIcon].
  Future<void> destroyIcon(int iconId);

  /// Releases all resources used by this backend.
  Future<void> dispose();

  /// The maximum number of icons this backend supports.
  ///
  /// Returns 1 for single-icon backends, higher for multi-icon backends.
  int get maxIcons;

  /// Returns `true` if this backend supports multiple simultaneous icons.
  bool get supportsMultipleIcons;

  /// Returns `true` if this backend is currently initialized.
  bool get isInitialized;

  /// Returns a human-readable name for this backend.
  String get name;
}
