import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Crossbar'**
  String get appTitle;

  /// No description provided for @pluginsTab.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get pluginsTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @marketplaceTab.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplaceTab;

  /// No description provided for @noPluginsFound.
  ///
  /// In en, this message translates to:
  /// **'No plugins found'**
  String get noPluginsFound;

  /// No description provided for @noPluginsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add plugins to your ~/.crossbar/plugins directory'**
  String get noPluginsDescription;

  /// No description provided for @refreshAll.
  ///
  /// In en, this message translates to:
  /// **'Refresh All'**
  String get refreshAll;

  /// No description provided for @addPlugin.
  ///
  /// In en, this message translates to:
  /// **'Add Plugin'**
  String get addPlugin;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @runNow.
  ///
  /// In en, this message translates to:
  /// **'Run Now'**
  String get runNow;

  /// No description provided for @configure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configure;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @lastRun.
  ///
  /// In en, this message translates to:
  /// **'Last Run'**
  String get lastRun;

  /// No description provided for @refreshInterval.
  ///
  /// In en, this message translates to:
  /// **'Refresh Interval'**
  String get refreshInterval;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @notInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not Installed'**
  String get notInstalled;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @startOnBoot.
  ///
  /// In en, this message translates to:
  /// **'Start on Boot'**
  String get startOnBoot;

  /// No description provided for @minimizeToTray.
  ///
  /// In en, this message translates to:
  /// **'Minimize to Tray'**
  String get minimizeToTray;

  /// No description provided for @pluginsDirectory.
  ///
  /// In en, this message translates to:
  /// **'Plugins Directory'**
  String get pluginsDirectory;

  /// No description provided for @openPluginsDirectory.
  ///
  /// In en, this message translates to:
  /// **'Open Plugins Directory'**
  String get openPluginsDirectory;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @noUpdatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No updates available'**
  String get noUpdatesAvailable;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @allLanguages.
  ///
  /// In en, this message translates to:
  /// **'All Languages'**
  String get allLanguages;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @bash.
  ///
  /// In en, this message translates to:
  /// **'Bash'**
  String get bash;

  /// No description provided for @python.
  ///
  /// In en, this message translates to:
  /// **'Python'**
  String get python;

  /// No description provided for @node.
  ///
  /// In en, this message translates to:
  /// **'Node.js'**
  String get node;

  /// No description provided for @dart.
  ///
  /// In en, this message translates to:
  /// **'Dart'**
  String get dart;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @rust.
  ///
  /// In en, this message translates to:
  /// **'Rust'**
  String get rust;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @development.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get development;

  /// No description provided for @productivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get productivity;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @utilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get utilities;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @behavior.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get behavior;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @useDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get useDarkTheme;

  /// No description provided for @launchOnLogin.
  ///
  /// In en, this message translates to:
  /// **'Launch Crossbar on login'**
  String get launchOnLogin;

  /// No description provided for @keepInTray.
  ///
  /// In en, this message translates to:
  /// **'Keep icon in tray when minimized'**
  String get keepInTray;

  /// No description provided for @defaultRefreshInterval.
  ///
  /// In en, this message translates to:
  /// **'Default Refresh Interval'**
  String get defaultRefreshInterval;

  /// No description provided for @searchPlugins.
  ///
  /// In en, this message translates to:
  /// **'Search plugins...'**
  String get searchPlugins;

  /// No description provided for @enabledFirst.
  ///
  /// In en, this message translates to:
  /// **'Enabled First'**
  String get enabledFirst;

  /// No description provided for @alphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get alphabetical;

  /// No description provided for @interval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get interval;

  /// No description provided for @noGrouping.
  ///
  /// In en, this message translates to:
  /// **'No Grouping'**
  String get noGrouping;

  /// No description provided for @byLanguage.
  ///
  /// In en, this message translates to:
  /// **'By Language'**
  String get byLanguage;

  /// No description provided for @byConfigurable.
  ///
  /// In en, this message translates to:
  /// **'By Configurable'**
  String get byConfigurable;

  /// No description provided for @noGroups.
  ///
  /// In en, this message translates to:
  /// **'No Groups'**
  String get noGroups;

  /// No description provided for @configurable.
  ///
  /// In en, this message translates to:
  /// **'Configurable'**
  String get configurable;

  /// No description provided for @standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standard;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @liveOutput.
  ///
  /// In en, this message translates to:
  /// **'Live Output'**
  String get liveOutput;

  /// No description provided for @copyOutput.
  ///
  /// In en, this message translates to:
  /// **'Copy output'**
  String get copyOutput;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running...'**
  String get running;

  /// No description provided for @executingPlugin.
  ///
  /// In en, this message translates to:
  /// **'Executing plugin...'**
  String get executingPlugin;

  /// No description provided for @clickRunNow.
  ///
  /// In en, this message translates to:
  /// **'Click \"Run Now\" to see output'**
  String get clickRunNow;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @path.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get path;

  /// No description provided for @interpreter.
  ///
  /// In en, this message translates to:
  /// **'Interpreter'**
  String get interpreter;

  /// No description provided for @lastError.
  ///
  /// In en, this message translates to:
  /// **'Last Error'**
  String get lastError;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @samplePlugins.
  ///
  /// In en, this message translates to:
  /// **'Sample Plugins'**
  String get samplePlugins;

  /// No description provided for @chooseFromPlugins.
  ///
  /// In en, this message translates to:
  /// **'Choose from 20+ ready-to-use plugins'**
  String get chooseFromPlugins;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @createYourOwnPlugin.
  ///
  /// In en, this message translates to:
  /// **'Create your own plugin:'**
  String get createYourOwnPlugin;

  /// No description provided for @createScriptStep.
  ///
  /// In en, this message translates to:
  /// **'1. Create a script in one of these languages:'**
  String get createScriptStep;

  /// No description provided for @nameWithIntervalStep.
  ///
  /// In en, this message translates to:
  /// **'2. Name it with refresh interval:'**
  String get nameWithIntervalStep;

  /// No description provided for @placeInPluginsStep.
  ///
  /// In en, this message translates to:
  /// **'3. Place it in ~/.crossbar/plugins/'**
  String get placeInPluginsStep;

  /// No description provided for @pluginsInstalledSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} plugin(s) installed successfully!'**
  String pluginsInstalledSuccess(int count);

  /// No description provided for @configurationSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved'**
  String get configurationSaved;

  /// No description provided for @noPluginsMatch.
  ///
  /// In en, this message translates to:
  /// **'No plugins match \"{query}\"'**
  String noPluginsMatch(String query);

  /// No description provided for @errorCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Error copied to clipboard'**
  String get errorCopiedToClipboard;

  /// No description provided for @pluginFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Plugin file not found'**
  String get pluginFileNotFound;

  /// No description provided for @failedToOpenEditor.
  ///
  /// In en, this message translates to:
  /// **'Failed to open editor: {error}'**
  String failedToOpenEditor(String error);

  /// No description provided for @clickDeleteAgain.
  ///
  /// In en, this message translates to:
  /// **'Click Delete again to remove \"{name}\"'**
  String clickDeleteAgain(String name);

  /// No description provided for @deletedPlugin.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String deletedPlugin(String name);

  /// No description provided for @failedToDeletePlugin.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete plugin: {error}'**
  String failedToDeletePlugin(String error);

  /// No description provided for @outputCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Output copied to clipboard'**
  String get outputCopiedToClipboard;

  /// No description provided for @andMore.
  ///
  /// In en, this message translates to:
  /// **'... and {count} more'**
  String andMore(int count);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @universalAndAdditionalPlugins.
  ///
  /// In en, this message translates to:
  /// **'{universal} universal + {additional} additional plugins'**
  String universalAndAdditionalPlugins(int universal, int additional);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noPluginsMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No plugins match your filters'**
  String get noPluginsMatchFilters;

  /// No description provided for @mobileCompatible.
  ///
  /// In en, this message translates to:
  /// **'Mobile compatible'**
  String get mobileCompatible;

  /// No description provided for @installedThisSession.
  ///
  /// In en, this message translates to:
  /// **'{count} installed this session'**
  String installedThisSession(int count);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @installedLanguage.
  ///
  /// In en, this message translates to:
  /// **'Installed {name} ({language})'**
  String installedLanguage(String name, String language);

  /// No description provided for @failedToInstall.
  ///
  /// In en, this message translates to:
  /// **'Failed to install {name}: {error}'**
  String failedToInstall(String name, String error);

  /// No description provided for @systemTray.
  ///
  /// In en, this message translates to:
  /// **'System Tray'**
  String get systemTray;

  /// No description provided for @displayMode.
  ///
  /// In en, this message translates to:
  /// **'Display Mode'**
  String get displayMode;

  /// No description provided for @unified.
  ///
  /// In en, this message translates to:
  /// **'Unified'**
  String get unified;

  /// No description provided for @singleTrayIconWithMenu.
  ///
  /// In en, this message translates to:
  /// **'Single tray icon with menu for all plugins'**
  String get singleTrayIconWithMenu;

  /// No description provided for @separate.
  ///
  /// In en, this message translates to:
  /// **'Separate'**
  String get separate;

  /// No description provided for @oneTrayIconPerPlugin.
  ///
  /// In en, this message translates to:
  /// **'One tray icon per plugin (Linux only)'**
  String get oneTrayIconPerPlugin;

  /// No description provided for @smartCollapse.
  ///
  /// In en, this message translates to:
  /// **'Smart Collapse'**
  String get smartCollapse;

  /// No description provided for @autoCollapseWhenManyPlugins.
  ///
  /// In en, this message translates to:
  /// **'Auto-collapse when too many plugins'**
  String get autoCollapseWhenManyPlugins;

  /// No description provided for @smartOverflow.
  ///
  /// In en, this message translates to:
  /// **'Smart Overflow'**
  String get smartOverflow;

  /// No description provided for @showFirstNIconsRestInOverflow.
  ///
  /// In en, this message translates to:
  /// **'Show first N icons, rest in overflow menu'**
  String get showFirstNIconsRestInOverflow;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @trayDisplayMode.
  ///
  /// In en, this message translates to:
  /// **'Tray Display Mode'**
  String get trayDisplayMode;

  /// No description provided for @unifiedSingleIconWithMenu.
  ///
  /// In en, this message translates to:
  /// **'Unified (single icon with menu)'**
  String get unifiedSingleIconWithMenu;

  /// No description provided for @separateOneIconPerPlugin.
  ///
  /// In en, this message translates to:
  /// **'Separate (one icon per plugin)'**
  String get separateOneIconPerPlugin;

  /// No description provided for @noConfigurationRequired.
  ///
  /// In en, this message translates to:
  /// **'No configuration required'**
  String get noConfigurationRequired;

  /// No description provided for @fiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get fiveMinutes;

  /// No description provided for @licenseText.
  ///
  /// In en, this message translates to:
  /// **'Crossbar - Universal Plugin System\n\nCopyright (C) 2025\n\nThis program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.\n\nThis program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.\n\nYou should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.'**
  String get licenseText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'ko',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
