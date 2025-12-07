// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Crossbar';

  @override
  String get pluginsTab => 'プラグイン';

  @override
  String get settingsTab => '設定';

  @override
  String get marketplaceTab => 'マーケット';

  @override
  String get noPluginsFound => 'プラグインが見つかりません';

  @override
  String get noPluginsDescription =>
      '~/.crossbar/plugins ディレクトリにプラグインを追加してください';

  @override
  String get refreshAll => 'すべて更新';

  @override
  String get addPlugin => 'プラグインを追加';

  @override
  String get enabled => '有効';

  @override
  String get disabled => '無効';

  @override
  String get runNow => '今すぐ実行';

  @override
  String get configure => '設定';

  @override
  String get remove => '削除';

  @override
  String get lastRun => '前回の実行';

  @override
  String get refreshInterval => '更新間隔';

  @override
  String get seconds => '秒';

  @override
  String get minutes => '分';

  @override
  String get hours => '時間';

  @override
  String get days => '日';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get apply => '適用';

  @override
  String get search => '検索';

  @override
  String get install => 'インストール';

  @override
  String get uninstall => 'アンインストール';

  @override
  String get update => '更新';

  @override
  String get installed => 'インストール済み';

  @override
  String get notInstalled => '未インストール';

  @override
  String get language => '言語';

  @override
  String get theme => 'テーマ';

  @override
  String get lightTheme => 'ライト';

  @override
  String get darkTheme => 'ダーク';

  @override
  String get systemTheme => 'システム';

  @override
  String get notifications => '通知';

  @override
  String get enableNotifications => '通知を有効化';

  @override
  String get startOnBoot => '起動時に開始';

  @override
  String get minimizeToTray => 'トレイに最小化';

  @override
  String get pluginsDirectory => 'プラグインディレクトリ';

  @override
  String get openPluginsDirectory => 'プラグインディレクトリを開く';

  @override
  String get about => '情報';

  @override
  String get version => 'バージョン';

  @override
  String get checkForUpdates => '更新を確認';

  @override
  String get noUpdatesAvailable => '更新はありません';

  @override
  String get updateAvailable => '更新があります';

  @override
  String get errorOccurred => 'エラーが発生しました';

  @override
  String get retry => '再試行';

  @override
  String get loading => '読み込み中...';

  @override
  String get noResults => '結果なし';

  @override
  String get allLanguages => 'すべての言語';

  @override
  String get allCategories => 'すべてのカテゴリ';

  @override
  String get popular => '人気';

  @override
  String get recent => '最新';

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
  String get system => 'システム';

  @override
  String get network => 'ネットワーク';

  @override
  String get development => '開発';

  @override
  String get productivity => '生産性';

  @override
  String get finance => '金融';

  @override
  String get weather => '天気';

  @override
  String get media => 'メディア';

  @override
  String get social => 'ソーシャル';

  @override
  String get utilities => 'ユーティリティ';

  @override
  String get other => 'その他';

  @override
  String get appearance => '外観';

  @override
  String get behavior => '動作';

  @override
  String get license => 'ライセンス';

  @override
  String get useDarkTheme => 'ダークテーマを使用';

  @override
  String get launchOnLogin => 'ログイン時にCrossbarを起動';

  @override
  String get keepInTray => '最小化時にトレイにアイコンを表示';

  @override
  String get defaultRefreshInterval => 'デフォルト更新間隔';

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
