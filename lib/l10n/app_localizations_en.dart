// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Crossbar';

  @override
  String get pluginsTab => 'Plugins';

  @override
  String get settingsTab => 'Settings';

  @override
  String get marketplaceTab => 'Marketplace';

  @override
  String get noPluginsFound => 'No plugins found';

  @override
  String get noPluginsDescription =>
      'Add plugins to your ~/.crossbar/plugins directory';

  @override
  String get refreshAll => 'Refresh All';

  @override
  String get addPlugin => 'Add Plugin';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get runNow => 'Run Now';

  @override
  String get configure => 'Configure';

  @override
  String get remove => 'Remove';

  @override
  String get lastRun => 'Last Run';

  @override
  String get refreshInterval => 'Refresh Interval';

  @override
  String get seconds => 'seconds';

  @override
  String get minutes => 'minutes';

  @override
  String get hours => 'hours';

  @override
  String get days => 'days';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get apply => 'Apply';

  @override
  String get search => 'Search';

  @override
  String get install => 'Install';

  @override
  String get uninstall => 'Uninstall';

  @override
  String get update => 'Update';

  @override
  String get installed => 'Installed';

  @override
  String get notInstalled => 'Not Installed';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get followSystemTheme => 'Follow system theme automatically';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get startOnBoot => 'Start on Boot';

  @override
  String get minimizeToTray => 'Minimize to Tray';

  @override
  String get keepOnBackground => 'Keep on Background';

  @override
  String get showPersistentNotification => 'Show persistent notification';

  @override
  String get pluginsDirectory => 'Plugins Directory';

  @override
  String get openPluginsDirectory => 'Open Plugins Directory';

  @override
  String get about => 'About';

  @override
  String get widgetLogStorage => 'Widget log storage';

  @override
  String get widgetLogStoragePersistent => 'Persistent (diagnostic)';

  @override
  String get widgetLogStorageMemory => 'In-memory (fast)';

  @override
  String get debugLogsTitle => 'Debug Logs';

  @override
  String get debugLogsCopy => 'Copy logs';

  @override
  String get debugLogsClear => 'Clear logs';

  @override
  String get debugLogsEmpty => 'No logs yet';

  @override
  String get debugLogsCopied => 'Logs copied to clipboard';

  @override
  String get debugLogsWidgetTitle => 'Widget native logs';

  @override
  String get debugLogsWidgetEmpty => 'No widget logs yet';

  @override
  String debugLogsWidgetDiscarded(int count) {
    return 'Discarded logs: $count';
  }

  @override
  String get debugWebCacheTitle => 'Web cache';

  @override
  String get debugWebCacheEntries => 'Memory entries';

  @override
  String get debugWebCacheHitRate => 'Hit rate';

  @override
  String get debugWebCacheHits => 'Hits';

  @override
  String get debugWebCacheMisses => 'Misses';

  @override
  String get debugWebCacheEvictions => 'Evictions';

  @override
  String get debugWebCacheCompression => 'Compression';

  @override
  String get debugWebCacheBytesSaved => 'Space saved';

  @override
  String get debugWebCacheDiskSize => 'Disk size';

  @override
  String get debugWebCacheFiles => 'Files';

  @override
  String debugWebCacheFilesCount(int total, int compressed, int plain) {
    return '$total total (compressed $compressed, plain $plain)';
  }

  @override
  String get debugLogsRange => 'Range';

  @override
  String get debugLogsCategory => 'Category';

  @override
  String get version => 'Version';

  @override
  String get checkForUpdates => 'Check for Updates';

  @override
  String get noUpdatesAvailable => 'No updates available';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get noResults => 'No results';

  @override
  String get allLanguages => 'All Languages';

  @override
  String get allCategories => 'All Categories';

  @override
  String get popular => 'Popular';

  @override
  String get recent => 'Recent';

  @override
  String get lua => 'Lua';

  @override
  String get bash => 'Bash';

  @override
  String get python => 'Python';

  @override
  String get node => 'Node.js';

  @override
  String get dart => 'Dart';

  @override
  String get go => 'Go';

  @override
  String get rust => 'Rust';

  @override
  String get system => 'System';

  @override
  String get network => 'Network';

  @override
  String get development => 'Development';

  @override
  String get productivity => 'Productivity';

  @override
  String get finance => 'Finance';

  @override
  String get weather => 'Weather';

  @override
  String get media => 'Media';

  @override
  String get social => 'Social';

  @override
  String get utilities => 'Utilities';

  @override
  String get other => 'Other';

  @override
  String get appearance => 'Appearance';

  @override
  String get behavior => 'Behavior';

  @override
  String get globalHotkey => 'Global Hotkey';

  @override
  String get globalHotkeyDescription => 'Toggle visibility with Ctrl+Alt+C';

  @override
  String get license => 'License';

  @override
  String get useDarkTheme => 'Use dark theme';

  @override
  String get launchOnLogin => 'Launch Crossbar on login';

  @override
  String get keepInTray => 'Keep icon in tray when minimized';

  @override
  String get defaultRefreshInterval => 'Default Refresh Interval';

  @override
  String get searchPlugins => 'Search plugins...';

  @override
  String get enabledFirst => 'Enabled First';

  @override
  String get alphabetical => 'Alphabetical';

  @override
  String get interval => 'Interval';

  @override
  String get noGrouping => 'No Grouping';

  @override
  String get byLanguage => 'By Language';

  @override
  String get byConfigurable => 'By Configurable';

  @override
  String get noGroups => 'No Groups';

  @override
  String get configurable => 'Configurable';

  @override
  String get standard => 'Standard';

  @override
  String get refresh => 'Refresh';

  @override
  String get liveOutput => 'Live Output';

  @override
  String get copyOutput => 'Copy output';

  @override
  String get running => 'Running...';

  @override
  String get executingPlugin => 'Executing plugin...';

  @override
  String get clickRunNow => 'Click \"Run Now\" to see output';

  @override
  String get error => 'Error';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get path => 'Path';

  @override
  String get interpreter => 'Interpreter';

  @override
  String get lastError => 'Last Error';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get disable => 'Disable';

  @override
  String get enable => 'Enable';

  @override
  String get samplePlugins => 'Sample Plugins';

  @override
  String get chooseFromPlugins => 'Choose from 20+ ready-to-use plugins';

  @override
  String get or => 'OR';

  @override
  String get createYourOwnPlugin => 'Create your own plugin:';

  @override
  String get createScriptStep =>
      '1. Create a script in one of these languages:';

  @override
  String get nameWithIntervalStep => '2. Name it with refresh interval:';

  @override
  String get placeInPluginsStep => '3. Place it in ~/.crossbar/plugins/';

  @override
  String pluginsInstalledSuccess(int count) {
    return '$count plugin(s) installed successfully!';
  }

  @override
  String get configurationSaved => 'Configuration saved';

  @override
  String noPluginsMatch(String query) {
    return 'No plugins match \"$query\"';
  }

  @override
  String get errorCopiedToClipboard => 'Error copied to clipboard';

  @override
  String get pluginFileNotFound => 'Plugin file not found';

  @override
  String failedToOpenEditor(String error) {
    return 'Failed to open editor: $error';
  }

  @override
  String clickDeleteAgain(String name) {
    return 'Click Delete again to remove \"$name\"';
  }

  @override
  String deletedPlugin(String name) {
    return 'Deleted $name';
  }

  @override
  String failedToDeletePlugin(String error) {
    return 'Failed to delete plugin: $error';
  }

  @override
  String get outputCopiedToClipboard => 'Output copied to clipboard';

  @override
  String andMore(int count) {
    return '... and $count more';
  }

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String universalAndAdditionalPlugins(int universal, int additional) {
    return '$universal universal + $additional additional plugins';
  }

  @override
  String get all => 'All';

  @override
  String get noPluginsMatchFilters => 'No plugins match your filters';

  @override
  String get mobileCompatible => 'Mobile compatible';

  @override
  String installedThisSession(int count) {
    return '$count installed this session';
  }

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String installedLanguage(String name, String language) {
    return 'Installed $name ($language)';
  }

  @override
  String failedToInstall(String name, String error) {
    return 'Failed to install $name: $error';
  }

  @override
  String get systemTray => 'System Tray';

  @override
  String get displayMode => 'Display Mode';

  @override
  String get unified => 'Unified';

  @override
  String get singleTrayIconWithMenu =>
      'Single tray icon with menu for all plugins';

  @override
  String get separate => 'Separate';

  @override
  String get oneTrayIconPerPlugin => 'One tray icon per plugin (Linux only)';

  @override
  String get smartCollapse => 'Smart Collapse';

  @override
  String get autoCollapseWhenManyPlugins =>
      'Auto-collapse when too many plugins';

  @override
  String get smartOverflow => 'Smart Overflow';

  @override
  String get showFirstNIconsRestInOverflow =>
      'Show first N icons, rest in overflow menu';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get trayDisplayMode => 'Tray Display Mode';

  @override
  String get unifiedSingleIconWithMenu => 'Unified (single icon with menu)';

  @override
  String get separateOneIconPerPlugin => 'Separate (one icon per plugin)';

  @override
  String get noConfigurationRequired => 'No configuration required';

  @override
  String get fiveMinutes => '5 minutes';

  @override
  String get licenseText =>
      'Crossbar - Universal Plugin System\n\nCopyright (C) 2025\n\nThis program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\nThis program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.\n\nYou should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.';

  @override
  String get notificationStyle => 'Notification Style';

  @override
  String get notificationStyleCombined => 'Combined';

  @override
  String get notificationStyleIndividual => 'Individual';

  @override
  String get notificationStyleBoth => 'Both';

  @override
  String get notificationStyleCombinedDesc =>
      'Single notification grouping all plugins';

  @override
  String get notificationStyleIndividualDesc => 'One notification per plugin';

  @override
  String get notificationStyleBothDesc =>
      'Combined summary + individual notifications';

  @override
  String get desktopOnly => 'Desktop only';

  @override
  String get widgetConfiguration => 'Widget Configuration';

  @override
  String get selectPluginsForWidget => 'Select plugins to display';

  @override
  String get selectOnePlugin => 'Select one plugin';

  @override
  String get selectPlugins => 'Select plugins';

  @override
  String get noPluginsAvailable =>
      'No plugins available. Install some plugins first.';

  @override
  String get widgetUpdateNote =>
      'Widgets update every 15 min in background. Open the app for instant updates.';
}
