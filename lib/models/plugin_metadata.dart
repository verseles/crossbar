/// Plugin language enumeration
enum PluginLanguage {
  bash('bash', '🐚', 'Bash'),
  python('python', '🐍', 'Python'),
  node('node', '📦', 'Node.js'),
  dart('dart', '🎯', 'Dart'),
  go('go', '🐹', 'Go'),
  rust('rust', '🦀', 'Rust'),
  yaml('yaml', '📄', 'YAML (No-Code)');

  const PluginLanguage(this.id, this.icon, this.displayName);
  
  final String id;
  final String icon;
  final String displayName;
  
  static PluginLanguage? fromId(String id) {
    return PluginLanguage.values.cast<PluginLanguage?>().firstWhere(
      (l) => l?.id == id,
      orElse: () => null,
    );
  }
  
  static PluginLanguage? fromExtension(String ext) {
    switch (ext) {
      case 'sh':
        return bash;
      case 'py':
        return python;
      case 'js':
        return node;
      case 'dart':
        return dart;
      case 'go':
        return go;
      case 'rs':
        return rust;
      case 'yaml':
      case 'yml':
        return yaml;
      default:
        return null;
    }
  }
}

/// Plugin category enumeration
enum PluginCategory {
  system('system', '🖥️', 'System'),
  time('time', '⏰', 'Time'),
  network('network', '🌐', 'Network'),
  development('development', '💻', 'Development'),
  productivity('productivity', '📋', 'Productivity'),
  finance('finance', '💰', 'Finance'),
  fun('fun', '🎮', 'Fun'),
  other('other', '📦', 'Other');

  const PluginCategory(this.id, this.icon, this.displayName);
  
  final String id;
  final String icon;
  final String displayName;
  
  static PluginCategory fromId(String id) {
    return PluginCategory.values.firstWhere(
      (c) => c.id == id,
      orElse: () => other,
    );
  }
}

/// Represents a variant of a plugin in a specific language
class PluginVariant {
  const PluginVariant({
    required this.language,
    required this.filename,
    required this.assetPath,
    this.schemaAssetPath,
  });

  final PluginLanguage language;
  final String filename;
  final String assetPath;
  final String? schemaAssetPath;
}

/// Unified metadata for plugins (both sample and installed)
class PluginMetadata {
  const PluginMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.variants,
    this.tags = const [],
    this.configRequired = false,
    this.mobileCompatible = false,
  });

  /// Unique identifier (e.g., 'cpu', 'battery', 'weather')
  final String id;
  
  /// Display name
  final String name;
  
  /// Description of what the plugin does
  final String description;
  
  /// Category for grouping
  final PluginCategory category;
  
  /// Available language variants
  final List<PluginVariant> variants;
  
  /// Tags for filtering/searching
  final List<String> tags;
  
  /// Whether the plugin requires configuration
  final bool configRequired;
  
  /// Whether the plugin is mobile-compatible (uses Crossbar API)
  final bool mobileCompatible;

  /// Get available languages
  List<PluginLanguage> get availableLanguages => 
      variants.map((v) => v.language).toList();

  /// Get variant by language
  PluginVariant? getVariant(PluginLanguage language) {
    return variants.cast<PluginVariant?>().firstWhere(
      (v) => v?.language == language,
      orElse: () => null,
    );
  }

  /// Get the default/preferred variant (Bash first for desktop compatibility)
  PluginVariant get defaultVariant {
    // Prefer Bash for desktop, Dart for mobile
    for (final lang in [PluginLanguage.bash, PluginLanguage.python, PluginLanguage.dart]) {
      final v = getVariant(lang);
      if (v != null) return v;
    }
    return variants.first;
  }

  /// Category icon
  String get categoryIcon => category.icon;
  
  /// Check if a language is available
  bool hasLanguage(PluginLanguage language) =>
      variants.any((v) => v.language == language);
}
