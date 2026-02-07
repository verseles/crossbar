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
      'Fügen Sie Plugins zu Ihrem ~/.crossbar/plugins Verzeichnis hinzu';

  @override
  String get refreshAll => 'Alle Aktualisieren';

  @override
  String get addPlugin => 'Plugin Hinzufügen';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get runNow => 'Jetzt Ausführen';

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
  String get search => 'Suchen';

  @override
  String get install => 'Installieren';

  @override
  String get uninstall => 'Deinstallieren';

  @override
  String get update => 'Aktualisieren';

  @override
  String get installed => 'Installiert';

  @override
  String get notInstalled => 'Nicht Installiert';

  @override
  String get language => 'Sprache';

  @override
  String get theme => 'Thema';

  @override
  String get lightTheme => 'Hell';

  @override
  String get darkTheme => 'Dunkel';

  @override
  String get systemTheme => 'System';

  @override
  String get followSystemTheme => 'Follow system theme automatically';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get enableNotifications => 'Benachrichtigungen Aktivieren';

  @override
  String get startOnBoot => 'Beim Start ausführen';

  @override
  String get minimizeToTray => 'In Taskleiste minimieren';

  @override
  String get keepOnBackground => 'Im Hintergrund behalten';

  @override
  String get showPersistentNotification =>
      'Persistent Benachrichtigung anzeigen';

  @override
  String get pluginsDirectory => 'Plugin-Verzeichnis';

  @override
  String get openPluginsDirectory => 'Plugin-Verzeichnis Öffnen';

  @override
  String get about => 'Über';

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
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get noUpdatesAvailable => 'Keine Updates verfügbar';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get errorOccurred => 'Ein Fehler ist aufgetreten';

  @override
  String get retry => 'Wiederholen';

  @override
  String get loading => 'Wird geladen...';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get allLanguages => 'Alle Sprachen';

  @override
  String get allCategories => 'Alle Kategorien';

  @override
  String get popular => 'Beliebt';

  @override
  String get recent => 'Aktuell';

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
  String get globalHotkey => 'Global Hotkey';

  @override
  String get globalHotkeyDescription => 'Toggle visibility with Ctrl+Alt+C';

  @override
  String get license => 'Lizenz';

  @override
  String get useDarkTheme => 'Dunkles Thema verwenden';

  @override
  String get launchOnLogin => 'Crossbar bei Anmeldung starten';

  @override
  String get keepInTray => 'Symbol in Taskleiste bei Minimierung behalten';

  @override
  String get defaultRefreshInterval => 'Standard-Aktualisierungsintervall';

  @override
  String get searchPlugins => 'Plugins suchen...';

  @override
  String get enabledFirst => 'Aktivierte Zuerst';

  @override
  String get alphabetical => 'Alphabetisch';

  @override
  String get interval => 'Intervall';

  @override
  String get noGrouping => 'Keine Gruppierung';

  @override
  String get byLanguage => 'Nach Sprache';

  @override
  String get byConfigurable => 'Nach Konfigurierbar';

  @override
  String get noGroups => 'Keine Gruppen';

  @override
  String get configurable => 'Konfigurierbar';

  @override
  String get standard => 'Standard';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get liveOutput => 'Live-Ausgabe';

  @override
  String get copyOutput => 'Ausgabe kopieren';

  @override
  String get running => 'Wird ausgeführt...';

  @override
  String get executingPlugin => 'Plugin wird ausgeführt...';

  @override
  String get clickRunNow =>
      'Klicken Sie auf \"Jetzt Ausführen\" um die Ausgabe zu sehen';

  @override
  String get error => 'Fehler';

  @override
  String get unknownError => 'Unbekannter Fehler';

  @override
  String get path => 'Pfad';

  @override
  String get interpreter => 'Interpreter';

  @override
  String get lastError => 'Letzter Fehler';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get disable => 'Deaktivieren';

  @override
  String get enable => 'Aktivieren';

  @override
  String get samplePlugins => 'Beispiel-Plugins';

  @override
  String get chooseFromPlugins =>
      'Wählen Sie aus 20+ gebrauchsfertigen Plugins';

  @override
  String get or => 'ODER';

  @override
  String get createYourOwnPlugin => 'Erstellen Sie Ihr eigenes Plugin:';

  @override
  String get createScriptStep =>
      '1. Erstellen Sie ein Skript in einer dieser Sprachen:';

  @override
  String get nameWithIntervalStep =>
      '2. Benennen Sie es mit Aktualisierungsintervall:';

  @override
  String get placeInPluginsStep =>
      '3. Platzieren Sie es in ~/.crossbar/plugins/';

  @override
  String pluginsInstalledSuccess(int count) {
    return '$count Plugin(s) erfolgreich installiert!';
  }

  @override
  String get configurationSaved => 'Konfiguration gespeichert';

  @override
  String noPluginsMatch(String query) {
    return 'Keine Plugins entsprechen \"$query\"';
  }

  @override
  String get errorCopiedToClipboard => 'Fehler in Zwischenablage kopiert';

  @override
  String get pluginFileNotFound => 'Plugin-Datei nicht gefunden';

  @override
  String failedToOpenEditor(String error) {
    return 'Editor öffnen fehlgeschlagen: $error';
  }

  @override
  String clickDeleteAgain(String name) {
    return 'Klicken Sie erneut auf Löschen um \"$name\" zu entfernen';
  }

  @override
  String deletedPlugin(String name) {
    return '$name gelöscht';
  }

  @override
  String failedToDeletePlugin(String error) {
    return 'Plugin löschen fehlgeschlagen: $error';
  }

  @override
  String get outputCopiedToClipboard => 'Ausgabe in Zwischenablage kopiert';

  @override
  String andMore(int count) {
    return '... und $count mehr';
  }

  @override
  String get justNow => 'Gerade eben';

  @override
  String minutesAgo(int count) {
    return 'vor ${count}m';
  }

  @override
  String hoursAgo(int count) {
    return 'vor ${count}h';
  }

  @override
  String daysAgo(int count) {
    return 'vor ${count}t';
  }

  @override
  String universalAndAdditionalPlugins(int universal, int additional) {
    return '$universal universal + $additional zusätzliche Plugins';
  }

  @override
  String get all => 'Alle';

  @override
  String get noPluginsMatchFilters => 'Keine Plugins entsprechen Ihren Filtern';

  @override
  String get mobileCompatible => 'Mobilkompatibel';

  @override
  String installedThisSession(int count) {
    return '$count in dieser Sitzung installiert';
  }

  @override
  String get done => 'Fertig';

  @override
  String get close => 'Schließen';

  @override
  String installedLanguage(String name, String language) {
    return '$name ($language) installiert';
  }

  @override
  String failedToInstall(String name, String error) {
    return 'Installation von $name fehlgeschlagen: $error';
  }

  @override
  String get systemTray => 'Systemleiste';

  @override
  String get displayMode => 'Anzeigemodus';

  @override
  String get unified => 'Vereinheitlicht';

  @override
  String get singleTrayIconWithMenu =>
      'Einzelnes Taskleisten-Symbol mit Menü für alle Plugins';

  @override
  String get separate => 'Getrennt';

  @override
  String get oneTrayIconPerPlugin => 'Ein Symbol pro Plugin (nur Linux)';

  @override
  String get smartCollapse => 'Intelligentes Zusammenklappen';

  @override
  String get autoCollapseWhenManyPlugins =>
      'Automatisches Zusammenklappen bei vielen Plugins';

  @override
  String get smartOverflow => 'Intelligenter Überlauf';

  @override
  String get showFirstNIconsRestInOverflow =>
      'Zeige erste N Symbole, Rest im Überlaufmenü';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get trayDisplayMode => 'Taskleisten-Anzeigemodus';

  @override
  String get unifiedSingleIconWithMenu =>
      'Vereinheitlicht (einzelnes Symbol mit Menü)';

  @override
  String get separateOneIconPerPlugin => 'Getrennt (ein Symbol pro Plugin)';

  @override
  String get noConfigurationRequired => 'Keine Konfiguration erforderlich';

  @override
  String get fiveMinutes => '5 Minuten';

  @override
  String get licenseText =>
      'Crossbar - Universelles Plugin-System\n\nCopyright (C) 2025\n\nDieses Programm ist freie Software: Sie können es unter den Bedingungen der GNU Affero General Public License wie von der Free Software Foundation veröffentlicht, entweder Version 3 der Lizenz oder (nach Ihrer Wahl) jeder späteren Version, weitergeben und/oder modifizieren.\n\nDieses Programm wird in der Hoffnung verteilt, dass es nützlich sein wird, aber OHNE JEDE GARANTIE; sogar ohne die implizite Garantie der MARKTFÄHIGKEIT oder EIGNUNG FÜR EINEN BESTIMMTEN ZWECK. Siehe die GNU Affero General Public License für weitere Details.\n\nSie sollten eine Kopie der GNU Affero General Public License zusammen mit diesem Programm erhalten haben. Falls nicht, siehe <https://www.gnu.org/licenses/>.';

  @override
  String get widgetConfiguration => 'Widget-Konfiguration';

  @override
  String get selectPluginsForWidget => 'Plugins zum Anzeigen auswählen';

  @override
  String get selectOnePlugin => 'Ein Plugin auswählen';

  @override
  String get selectPlugins => 'Plugins auswählen';

  @override
  String get noPluginsAvailable =>
      'Keine Plugins verfügbar. Installieren Sie zuerst einige Plugins.';

  @override
  String get widgetUpdateNote =>
      'Widgets werden im Hintergrund alle 15 Min. aktualisiert. Öffnen Sie die App für sofortige Updates.';
}
