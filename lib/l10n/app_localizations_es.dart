// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Crossbar';

  @override
  String get pluginsTab => 'Plugins';

  @override
  String get settingsTab => 'Ajustes';

  @override
  String get marketplaceTab => 'Tienda';

  @override
  String get noPluginsFound => 'No se encontraron plugins';

  @override
  String get noPluginsDescription =>
      'Añade plugins a tu directorio ~/.crossbar/plugins';

  @override
  String get refreshAll => 'Actualizar Todo';

  @override
  String get addPlugin => 'Añadir Plugin';

  @override
  String get enabled => 'Habilitado';

  @override
  String get disabled => 'Deshabilitado';

  @override
  String get runNow => 'Ejecutar Ahora';

  @override
  String get configure => 'Configurar';

  @override
  String get remove => 'Eliminar';

  @override
  String get lastRun => 'Última Ejecución';

  @override
  String get refreshInterval => 'Intervalo de Actualización';

  @override
  String get seconds => 'segundos';

  @override
  String get minutes => 'minutos';

  @override
  String get hours => 'horas';

  @override
  String get days => 'días';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get apply => 'Aplicar';

  @override
  String get search => 'Buscar';

  @override
  String get install => 'Instalar';

  @override
  String get uninstall => 'Desinstalar';

  @override
  String get update => 'Actualizar';

  @override
  String get installed => 'Instalado';

  @override
  String get notInstalled => 'No Instalado';

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get lightTheme => 'Claro';

  @override
  String get darkTheme => 'Oscuro';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get enableNotifications => 'Habilitar Notificaciones';

  @override
  String get startOnBoot => 'Iniciar al arrancar';

  @override
  String get minimizeToTray => 'Minimizar a la bandeja';

  @override
  String get pluginsDirectory => 'Directorio de Plugins';

  @override
  String get openPluginsDirectory => 'Abrir Directorio de Plugins';

  @override
  String get about => 'Acerca de';

  @override
  String get version => 'Versión';

  @override
  String get checkForUpdates => 'Buscar actualizaciones';

  @override
  String get noUpdatesAvailable => 'No hay actualizaciones disponibles';

  @override
  String get updateAvailable => 'Actualización disponible';

  @override
  String get errorOccurred => 'Ocurrió un error';

  @override
  String get retry => 'Reintentar';

  @override
  String get loading => 'Cargando...';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get allLanguages => 'Todos los idiomas';

  @override
  String get allCategories => 'Todas las categorías';

  @override
  String get popular => 'Popular';

  @override
  String get recent => 'Reciente';

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
  String get network => 'Red';

  @override
  String get development => 'Desarrollo';

  @override
  String get productivity => 'Productividad';

  @override
  String get finance => 'Finanzas';

  @override
  String get weather => 'Tiempo';

  @override
  String get media => 'Medios';

  @override
  String get social => 'Social';

  @override
  String get utilities => 'Utilidades';

  @override
  String get other => 'Otros';

  @override
  String get appearance => 'Apariencia';

  @override
  String get behavior => 'Comportamiento';

  @override
  String get license => 'Licencia';

  @override
  String get useDarkTheme => 'Usar tema oscuro';

  @override
  String get launchOnLogin => 'Iniciar Crossbar al iniciar sesión';

  @override
  String get keepInTray => 'Mantener icono en bandeja al minimizar';

  @override
  String get defaultRefreshInterval =>
      'Intervalo de actualización predeterminado';

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
