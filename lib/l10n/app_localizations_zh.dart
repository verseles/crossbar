// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Crossbar';

  @override
  String get pluginsTab => '插件';

  @override
  String get settingsTab => '设置';

  @override
  String get marketplaceTab => '市场';

  @override
  String get noPluginsFound => '未找到插件';

  @override
  String get noPluginsDescription => '请将插件添加到 ~/.crossbar/plugins 目录';

  @override
  String get refreshAll => '全部刷新';

  @override
  String get addPlugin => '添加插件';

  @override
  String get enabled => '已启用';

  @override
  String get disabled => '已禁用';

  @override
  String get runNow => '立即运行';

  @override
  String get configure => '配置';

  @override
  String get remove => '移除';

  @override
  String get lastRun => '上次运行';

  @override
  String get refreshInterval => '刷新间隔';

  @override
  String get seconds => '秒';

  @override
  String get minutes => '分';

  @override
  String get hours => '小时';

  @override
  String get days => '天';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get apply => '应用';

  @override
  String get search => '搜索';

  @override
  String get install => '安装';

  @override
  String get uninstall => '卸载';

  @override
  String get update => '更新';

  @override
  String get installed => '已安装';

  @override
  String get notInstalled => '未安装';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get lightTheme => '浅色';

  @override
  String get darkTheme => '深色';

  @override
  String get systemTheme => '系统';

  @override
  String get notifications => '通知';

  @override
  String get enableNotifications => '启用通知';

  @override
  String get startOnBoot => '开机自启';

  @override
  String get minimizeToTray => '最小化到托盘';

  @override
  String get pluginsDirectory => '插件目录';

  @override
  String get openPluginsDirectory => '打开插件目录';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get noUpdatesAvailable => '无可用更新';

  @override
  String get updateAvailable => '有可用更新';

  @override
  String get errorOccurred => '发生错误';

  @override
  String get retry => '重试';

  @override
  String get loading => '加载中...';

  @override
  String get noResults => '无结果';

  @override
  String get allLanguages => '所有语言';

  @override
  String get allCategories => '所有分类';

  @override
  String get popular => '热门';

  @override
  String get recent => '最近';

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
  String get system => '系统';

  @override
  String get network => '网络';

  @override
  String get development => '开发';

  @override
  String get productivity => '生产力';

  @override
  String get finance => '金融';

  @override
  String get weather => '天气';

  @override
  String get media => '媒体';

  @override
  String get social => '社交';

  @override
  String get utilities => '工具';

  @override
  String get other => '其他';

  @override
  String get appearance => '外观';

  @override
  String get behavior => '行为';

  @override
  String get license => '许可证';

  @override
  String get useDarkTheme => '使用深色主题';

  @override
  String get launchOnLogin => '登录时启动 Crossbar';

  @override
  String get keepInTray => '最小化时保留托盘图标';

  @override
  String get defaultRefreshInterval => '默认刷新间隔';

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
