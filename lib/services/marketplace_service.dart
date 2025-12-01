import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../core/plugin_manager.dart';

class MarketplaceService {
  static final MarketplaceService _instance = MarketplaceService._internal();

  factory MarketplaceService() => _instance;

  MarketplaceService._internal();

  static const String _defaultRepoOwner = 'verseles';
  static const String _defaultRepoName = 'crossbar-plugins';
  static const String _githubApiBase = 'https://api.github.com';
  static const String _rawContentBase = 'https://raw.githubusercontent.com';

  final PluginManager _pluginManager = PluginManager();
  final Dio _dio = Dio();
  final List<MarketplacePlugin> _plugins = [];
  String? _lastError;

  List<MarketplacePlugin> get plugins => List.unmodifiable(_plugins);
  String? get lastError => _lastError;

  Future<List<MarketplacePlugin>> searchPlugins({
    String? query,
    String? language,
    String? category,
    String owner = _defaultRepoOwner,
    String repo = _defaultRepoName,
  }) async {
    try {
      _lastError = null;

      // Search for plugins in the official repository
      final pluginsListUrl =
          '$_rawContentBase/$owner/$repo/main/plugins.json';

      final response = await _dio.get(
        pluginsListUrl,
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode != 200) {
        // Fallback to GitHub API to list files
        return await _searchViaGitHubApi(
          query: query,
          language: language,
          category: category,
          owner: owner,
          repo: repo,
        );
      }

      final List<dynamic> pluginList = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      _plugins.clear();

      for (final item in pluginList) {
        final plugin = MarketplacePlugin.fromJson(item);

        // Apply filters
        if (query != null &&
            query.isNotEmpty &&
            !plugin.name.toLowerCase().contains(query.toLowerCase()) &&
            !plugin.description.toLowerCase().contains(query.toLowerCase())) {
          continue;
        }

        if (language != null &&
            language.isNotEmpty &&
            plugin.language.toLowerCase() != language.toLowerCase()) {
          continue;
        }

        if (category != null &&
            category.isNotEmpty &&
            plugin.category.toLowerCase() != category.toLowerCase()) {
          continue;
        }

        _plugins.add(plugin);
      }

      return _plugins;
    } catch (e) {
      _lastError = e.toString();
      return [];
    }
  }

  Future<List<MarketplacePlugin>> _searchViaGitHubApi({
    String? query,
    String? language,
    String? category,
    required String owner,
    required String repo,
  }) async {
    final url = '$_githubApiBase/repos/$owner/$repo/contents/plugins';
    final response = await _dio.get(
      url,
      options: Options(
        headers: {'Accept': 'application/vnd.github.v3+json'},
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    if (response.statusCode != 200) {
      _lastError = 'GitHub API error: ${response.statusCode}';
      return [];
    }

    final List<dynamic> contents = response.data is String
        ? jsonDecode(response.data)
        : response.data;
    _plugins.clear();

    for (final item in contents) {
      if (item['type'] == 'file') {
        final name = item['name'] as String;
        final ext = p.extension(name);

        // Filter by language/extension
        final pluginLanguage = _extensionToLanguage(ext);
        if (pluginLanguage == null) continue;

        if (language != null &&
            language.isNotEmpty &&
            pluginLanguage.toLowerCase() != language.toLowerCase()) {
          continue;
        }

        // Apply name filter
        if (query != null &&
            query.isNotEmpty &&
            !name.toLowerCase().contains(query.toLowerCase())) {
          continue;
        }

        _plugins.add(MarketplacePlugin(
          id: name,
          name: _formatPluginName(name),
          description: 'Plugin from $owner/$repo',
          author: owner,
          language: pluginLanguage,
          category: category ?? 'General',
          version: '1.0.0',
          downloadUrl: item['download_url'] ?? '',
          stars: 0,
          downloads: 0,
        ));
      }
    }

    return _plugins;
  }

  Future<bool> installPlugin(MarketplacePlugin plugin) async {
    try {
      _lastError = null;

      final response = await _dio.get(
        plugin.downloadUrl,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      if (response.statusCode != 200) {
        _lastError = 'Failed to download plugin: ${response.statusCode}';
        return false;
      }

      final pluginDir = _pluginManager.pluginsDirectory;
      final dir = Directory(pluginDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final filePath = p.join(pluginDir, plugin.id);
      final file = File(filePath);
      final content = response.data is String ? response.data : jsonEncode(response.data);
      await file.writeAsString(content);

      // Make executable on Unix systems
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['+x', filePath]);
      }

      // Reload plugins
      await _pluginManager.discoverPlugins();

      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> uninstallPlugin(String pluginId) async {
    try {
      _lastError = null;

      final pluginDir = _pluginManager.pluginsDirectory;
      final filePath = p.join(pluginDir, pluginId);
      final file = File(filePath);

      if (file.existsSync()) {
        await file.delete();
      }

      // Also remove config file if exists
      final configPath = '$filePath.json';
      final configFile = File(configPath);
      if (configFile.existsSync()) {
        await configFile.delete();
      }

      // Reload plugins
      await _pluginManager.discoverPlugins();

      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<MarketplacePlugin?> getPluginDetails(
    String pluginId, {
    String owner = _defaultRepoOwner,
    String repo = _defaultRepoName,
  }) async {
    try {
      _lastError = null;

      // Try to get plugin metadata from .json file
      final metadataUrl =
          '$_rawContentBase/$owner/$repo/main/metadata/$pluginId.json';

      final response = await _dio.get(
        metadataUrl,
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return MarketplacePlugin.fromJson(data);
      }

      // Fallback to basic info
      final plugin = _plugins.firstWhere(
        (p) => p.id == pluginId,
        orElse: () => MarketplacePlugin(
          id: pluginId,
          name: _formatPluginName(pluginId),
          description: 'No description available',
          author: owner,
          language: _extensionToLanguage(p.extension(pluginId)) ?? 'unknown',
          category: 'General',
          version: '1.0.0',
          downloadUrl:
              '$_rawContentBase/$owner/$repo/main/plugins/$pluginId',
          stars: 0,
          downloads: 0,
        ),
      );

      return plugin;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  bool isInstalled(String pluginId) {
    return _pluginManager.getPlugin(pluginId) != null;
  }

  String? _extensionToLanguage(String ext) {
    switch (ext.toLowerCase()) {
      case '.sh':
        return 'bash';
      case '.py':
        return 'python';
      case '.js':
        return 'node';
      case '.dart':
        return 'dart';
      case '.go':
        return 'go';
      case '.rs':
        return 'rust';
      default:
        return null;
    }
  }

  String _formatPluginName(String filename) {
    // Remove extension and interval suffix, format nicely
    var name = p.basenameWithoutExtension(filename);
    // Remove interval like .10s, .5m, .1h
    name = name.replaceAll(RegExp(r'\.\d+[smhd]$'), '');
    // Convert snake_case/kebab-case to Title Case
    name = name
        .replaceAll(RegExp(r'[_-]'), ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
    return name;
  }
}

class MarketplacePlugin {
  final String id;
  final String name;
  final String description;
  final String author;
  final String language;
  final String category;
  final String version;
  final String downloadUrl;
  final int stars;
  final int downloads;
  final String? readme;
  final String? screenshot;
  final List<String> tags;

  const MarketplacePlugin({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.language,
    required this.category,
    required this.version,
    required this.downloadUrl,
    this.stars = 0,
    this.downloads = 0,
    this.readme,
    this.screenshot,
    this.tags = const [],
  });

  factory MarketplacePlugin.fromJson(Map<String, dynamic> json) {
    return MarketplacePlugin(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? '',
      language: json['language'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      version: json['version'] as String? ?? '1.0.0',
      downloadUrl: json['downloadUrl'] as String? ?? json['download_url'] as String? ?? '',
      stars: json['stars'] as int? ?? 0,
      downloads: json['downloads'] as int? ?? 0,
      readme: json['readme'] as String?,
      screenshot: json['screenshot'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'author': author,
      'language': language,
      'category': category,
      'version': version,
      'downloadUrl': downloadUrl,
      'stars': stars,
      'downloads': downloads,
      'readme': readme,
      'screenshot': screenshot,
      'tags': tags,
    };
  }
}

class PluginCategory {
  static const String system = 'System';
  static const String network = 'Network';
  static const String dev = 'Development';
  static const String productivity = 'Productivity';
  static const String finance = 'Finance';
  static const String weather = 'Weather';
  static const String media = 'Media';
  static const String social = 'Social';
  static const String utilities = 'Utilities';
  static const String other = 'Other';

  static const List<String> all = [
    system,
    network,
    dev,
    productivity,
    finance,
    weather,
    media,
    social,
    utilities,
    other,
  ];
}
