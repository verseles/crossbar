import 'dart:io';

import '../plugin_scaffolding.dart';
import 'base_command.dart';

class InitCommand extends CliCommand {
  @override
  String get name => 'init';

  @override
  String get description => 'Create a new plugin from template';

  @override
  Future<int> execute(List<String> args) async {
    // args: --lang bash --type custom --name my-plugin --output dir
    // We need to parse flags.

    String? lang;
    String type = 'custom';
    String? name;
    String? outputDir;

    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--lang' && i + 1 < args.length) lang = args[i + 1];
      if (args[i] == '--type' && i + 1 < args.length) type = args[i + 1];
      if (args[i] == '--name' && i + 1 < args.length) name = args[i + 1];
      if (args[i] == '--output' && i + 1 < args.length) outputDir = args[i + 1];
    }

    if (lang == null) {
      stderr.writeln('Error: --lang is required');
      stderr.writeln('Usage: crossbar init --lang <bash|python|node|dart|go|rust> --type <clock|monitor|status|api|custom> [--name <name>]');
      stderr.writeln('');
      stderr.writeln('Supported languages: ${PluginScaffolding.supportedLanguages.join(', ')}');
      stderr.writeln('Supported types: ${PluginScaffolding.supportedTypes.join(', ')}');
      return 1;
    }

    if (!PluginScaffolding.supportedLanguages.contains(lang.toLowerCase())) {
      stderr.writeln('Error: Unsupported language: $lang');
      stderr.writeln('Supported: ${PluginScaffolding.supportedLanguages.join(', ')}');
      return 1;
    }

    if (!PluginScaffolding.supportedTypes.contains(type.toLowerCase())) {
      stderr.writeln('Error: Unsupported type: $type');
      stderr.writeln('Supported: ${PluginScaffolding.supportedTypes.join(', ')}');
      return 1;
    }

    const scaffolding = PluginScaffolding();
    final pluginPath = await scaffolding.createPlugin(
      lang: lang,
      type: type,
      name: name,
      outputDir: outputDir,
    );

    if (pluginPath != null) {
      print('Plugin created: $pluginPath');
      print('Config file: $pluginPath.config.json');
      print('');
      print('Next steps:');
      print('  1. Edit the plugin file to add your logic');
      print('  2. Customize the config file for settings');
      print('  3. Test with: crossbar exec "${_getInterpreterCommand(lang)} $pluginPath"');
    } else {
      stderr.writeln('Failed to create plugin');
      return 1;
    }
    return 0;
  }

  String _getInterpreterCommand(String lang) {
    switch (lang.toLowerCase()) {
      case 'bash':
        return 'bash';
      case 'python':
        return 'python3';
      case 'node':
        return 'node';
      case 'dart':
        return 'dart';
      case 'go':
        return 'go run';
      case 'rust':
        return 'rustc -o /tmp/test && /tmp/test #';
      default:
        return lang;
    }
  }
}

class InstallCommand extends CliCommand {
  @override
  String get name => 'install';

  @override
  String get description => 'Install plugin from GitHub repository';

  @override
  Future<int> execute(List<String> args) async {
    final values = args.where((a) => !a.startsWith('--')).toList();
    if (values.isEmpty) {
      stderr.writeln('Error: URL is required');
      stderr.writeln('Usage: crossbar install <github-url>');
      stderr.writeln('');
      stderr.writeln('Example: crossbar install https://github.com/user/my-crossbar-plugin');
      return 1;
    }
    final url = values[0];

    print('Installing plugin from: $url');
    const installer = PluginInstaller();
    final installedPath = await installer.installFromGitHub(url);

    if (installedPath != null) {
      print('Plugin installed: $installedPath');
    } else {
      stderr.writeln('Failed to install plugin');
      stderr.writeln('Make sure:');
      stderr.writeln('  - The URL is a valid GitHub repository');
      stderr.writeln('  - The repository contains plugin files (name.interval.ext)');
      stderr.writeln('  - git is installed and accessible');
      return 1;
    }
    return 0;
  }
}
