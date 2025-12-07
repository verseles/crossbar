// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Crossbar';

  @override
  String get pluginsTab => 'Plugins';

  @override
  String get settingsTab => 'Einstellungen';

  @override
  String get marketplaceTab => 'Marktplatz';

  @override
  String get noPluginsFound => 'Keine Plugins gefunden';

  @override
  String get noPluginsDescription =>
      'Fügen Sie Plugins in das Verzeichnis ~/.crossbar/plugins ein';

  @override
  String get refreshAll => 'Alle aktualisieren';

  @override
  String get addPlugin => 'Plugin hinzufügen';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get runNow => 'Jetzt ausführen';

  @override
  String get configure => 'Konfigurieren';

  @override
  String get remove => 'Entfernen';

  @override
  String get lastRun => 'Letzte Ausführung';

  @override
  String get refreshInterval => 'Aktualisierungsintervall';

  @override
  String get seconds => 'Sekunden';

  @override
  String get minutes => 'Minuten';

  @override
  String get hours => 'Stunden';

  @override
  String get days => 'Tage';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get apply => 'Anwenden';

  @override
  String get search => 'Suche';

  @override
  String get install => 'Installieren';

  @override
  String get uninstall => 'Deinstallieren';

  @override
  String get update => 'Aktualisieren';

  @override
  String get installed => 'Installiert';

  @override
  String get notInstalled => 'Nicht installiert';

  @override
  String get language => 'Sprache';

  @override
  String get theme => 'Design';

  @override
  String get lightTheme => 'Hell';

  @override
  String get darkTheme => 'Dunkel';

  @override
  String get systemTheme => 'System';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get startOnBoot => 'Beim Start ausführen';

  @override
  String get minimizeToTray => 'In System-Tray minimieren';

  @override
  String get pluginsDirectory => 'Plugin-Verzeichnis';

  @override
  String get openPluginsDirectory => 'Plugin-Verzeichnis öffnen';

  @override
  String get about => 'Über';

  @override
  String get version => 'Version';

  @override
  String get checkForUpdates => 'Auf Updates prüfen';

  @override
  String get noUpdatesAvailable => 'Keine Updates verfügbar';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get errorOccurred => 'Ein Fehler ist aufgetreten';

  @override
  String get retry => 'Wiederholen';

  @override
  String get loading => 'Laden...';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get allLanguages => 'Alle Sprachen';

  @override
  String get allCategories => 'Alle Kategorien';

  @override
  String get popular => 'Beliebt';

  @override
  String get recent => 'Kürzlich';

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
  String get network => 'Netzwerk';

  @override
  String get development => 'Entwicklung';

  @override
  String get productivity => 'Produktivität';

  @override
  String get finance => 'Finanzen';

  @override
  String get weather => 'Wetter';

  @override
  String get media => 'Medien';

  @override
  String get social => 'Sozial';

  @override
  String get utilities => 'Dienstprogramme';

  @override
  String get other => 'Andere';

  @override
  String get appearance => 'Aussehen';

  @override
  String get behavior => 'Verhalten';

  @override
  String get license => 'Lizenz';

  @override
  String get useDarkTheme => 'Dunkles Design verwenden';

  @override
  String get launchOnLogin => 'Crossbar beim Login starten';

  @override
  String get keepInTray => 'Symbol im Tray behalten';

  @override
  String get defaultRefreshInterval => 'Standard-Aktualisierungsintervall';

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
}
