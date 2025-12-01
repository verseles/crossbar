import 'package:flutter/material.dart';

class MarketplaceTab extends StatefulWidget {
  const MarketplaceTab({super.key});

  @override
  State<MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends State<MarketplaceTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLanguage = 'all';
  bool _isLoading = false;

  final List<Map<String, String>> _languages = [
    {'code': 'all', 'name': 'All Languages'},
    {'code': 'shell', 'name': 'Bash'},
    {'code': 'python', 'name': 'Python'},
    {'code': 'javascript', 'name': 'Node.js'},
    {'code': 'dart', 'name': 'Dart'},
    {'code': 'go', 'name': 'Go'},
    {'code': 'rust', 'name': 'Rust'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search plugins...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedLanguage,
                  items: _languages.map((lang) {
                    return DropdownMenuItem(
                      value: lang['code'],
                      child: Text(lang['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'Crossbar Marketplace',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Search for plugins on GitHub',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tag your repository with #crossbar to appear here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.search),
            label: const Text('Search Plugins'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              _showInstallFromUrlDialog();
            },
            icon: const Icon(Icons.link),
            label: const Text('Install from URL'),
          ),
        ],
      ),
    );
  }

  void _search() {
    setState(() {
      _isLoading = true;
    });

    Future<void>.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marketplace search coming soon!'),
          ),
        );
      }
    });
  }

  void _showInstallFromUrlDialog() {
    final urlController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Install from URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the GitHub repository URL:'),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://github.com/user/plugin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Example: https://github.com/verseles/crossbar-weather',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _installFromUrl(urlController.text);
            },
            child: const Text('Install'),
          ),
        ],
      ),
    );
  }

  void _installFromUrl(String url) {
    if (url.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Installing from $url...'),
      ),
    );

    // TODO: Implement actual installation
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plugin installation coming soon!'),
          ),
        );
      }
    });
  }
}
