// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Crossbar';

  @override
  String get pluginsTab => 'Plugin';

  @override
  String get settingsTab => 'Impostazioni';

  @override
  String get marketplaceTab => 'Negozio';

  @override
  String get noPluginsFound => 'Nessun plugin trovato';

  @override
  String get noPluginsDescription =>
      'Aggiungi plugin nella directory ~/.crossbar/plugins';

  @override
  String get refreshAll => 'Aggiorna Tutto';

  @override
  String get addPlugin => 'Aggiungi Plugin';

  @override
  String get enabled => 'Abilitato';

  @override
  String get disabled => 'Disabilitato';

  @override
  String get runNow => 'Esegui Ora';

  @override
  String get configure => 'Configura';

  @override
  String get remove => 'Rimuovi';

  @override
  String get lastRun => 'Ultima Esecuzione';

  @override
  String get refreshInterval => 'Intervallo di Aggiornamento';

  @override
  String get seconds => 'secondi';

  @override
  String get minutes => 'minuti';

  @override
  String get hours => 'ore';

  @override
  String get days => 'giorni';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get apply => 'Applica';

  @override
  String get search => 'Cerca';

  @override
  String get install => 'Installa';

  @override
  String get uninstall => 'Disinstalla';

  @override
  String get update => 'Aggiorna';

  @override
  String get installed => 'Installato';

  @override
  String get notInstalled => 'Non Installato';

  @override
  String get language => 'Lingua';

  @override
  String get theme => 'Tema';

  @override
  String get lightTheme => 'Chiaro';

  @override
  String get darkTheme => 'Scuro';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get notifications => 'Notifiche';

  @override
  String get enableNotifications => 'Abilita Notifiche';

  @override
  String get startOnBoot => 'Avvia all\'Avvio';

  @override
  String get minimizeToTray => 'Riduci a Icona';

  @override
  String get pluginsDirectory => 'Directory Plugin';

  @override
  String get openPluginsDirectory => 'Apri Directory Plugin';

  @override
  String get about => 'Informazioni';

  @override
  String get version => 'Versione';

  @override
  String get checkForUpdates => 'Controlla Aggiornamenti';

  @override
  String get noUpdatesAvailable => 'Nessun aggiornamento disponibile';

  @override
  String get updateAvailable => 'Aggiornamento disponibile';

  @override
  String get errorOccurred => 'Si è verificato un errore';

  @override
  String get retry => 'Riprova';

  @override
  String get loading => 'Caricamento...';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get allLanguages => 'Tutte le lingue';

  @override
  String get allCategories => 'Tutte le categorie';

  @override
  String get popular => 'Popolare';

  @override
  String get recent => 'Recente';

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
  String get system => 'Sistema';

  @override
  String get network => 'Rete';

  @override
  String get development => 'Sviluppo';

  @override
  String get productivity => 'Produttività';

  @override
  String get finance => 'Finanza';

  @override
  String get weather => 'Meteo';

  @override
  String get media => 'Media';

  @override
  String get social => 'Social';

  @override
  String get utilities => 'Utilità';

  @override
  String get other => 'Altro';

  @override
  String get appearance => 'Aspetto';

  @override
  String get behavior => 'Comportamento';

  @override
  String get license => 'Licenza';

  @override
  String get useDarkTheme => 'Usa tema scuro';

  @override
  String get launchOnLogin => 'Avvia Crossbar al login';

  @override
  String get keepInTray => 'Mantieni icona nel vassoio';

  @override
  String get defaultRefreshInterval => 'Intervallo aggiornamento predefinito';

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
