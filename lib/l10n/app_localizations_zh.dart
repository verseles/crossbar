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
  String get marketplaceTab => '商店';

  @override
  String get noPluginsFound => '未找到插件';

  @override
  String get noPluginsDescription => '将插件添加到 ~/.crossbar/plugins 目录';

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
  String get minutes => '分钟';

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
  String get followSystemTheme => 'Follow system theme automatically';

  @override
  String get notifications => '通知';

  @override
  String get enableNotifications => '启用通知';

  @override
  String get startOnBoot => '开机启动';

  @override
  String get minimizeToTray => '最小化到托盘';

  @override
  String get keepOnBackground => '保持后台运行';

  @override
  String get showPersistentNotification => '显示持久通知';

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
  String get noUpdatesAvailable => '没有可用更新';

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
  String get searchPlugins => '搜索插件...';

  @override
  String get enabledFirst => '启用的优先';

  @override
  String get alphabetical => '按字母排序';

  @override
  String get interval => '间隔';

  @override
  String get noGrouping => '不分组';

  @override
  String get byLanguage => '按语言';

  @override
  String get byConfigurable => '按可配置性';

  @override
  String get noGroups => '无分组';

  @override
  String get configurable => '可配置';

  @override
  String get standard => '标准';

  @override
  String get refresh => '刷新';

  @override
  String get liveOutput => '实时输出';

  @override
  String get copyOutput => '复制输出';

  @override
  String get running => '运行中...';

  @override
  String get executingPlugin => '执行插件中...';

  @override
  String get clickRunNow => '点击【立即运行】查看输出';

  @override
  String get error => '错误';

  @override
  String get unknownError => '未知错误';

  @override
  String get path => '路径';

  @override
  String get interpreter => '解释器';

  @override
  String get lastError => '上次错误';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get disable => '禁用';

  @override
  String get enable => '启用';

  @override
  String get samplePlugins => '示例插件';

  @override
  String get chooseFromPlugins => '从20+个即用型插件中选择';

  @override
  String get or => '或';

  @override
  String get createYourOwnPlugin => '创建您自己的插件：';

  @override
  String get createScriptStep => '1. 用以下语言之一创建脚本：';

  @override
  String get nameWithIntervalStep => '2. 用刷新间隔命名：';

  @override
  String get placeInPluginsStep => '3. 放置在 ~/.crossbar/plugins/';

  @override
  String pluginsInstalledSuccess(int count) {
    return '$count 个插件安装成功！';
  }

  @override
  String get configurationSaved => '配置已保存';

  @override
  String noPluginsMatch(String query) {
    return '没有插件匹配 \"$query\"';
  }

  @override
  String get errorCopiedToClipboard => '错误已复制到剪贴板';

  @override
  String get pluginFileNotFound => '插件文件未找到';

  @override
  String failedToOpenEditor(String error) {
    return '打开编辑器失败：$error';
  }

  @override
  String clickDeleteAgain(String name) {
    return '再次点击删除以移除 \"$name\"';
  }

  @override
  String deletedPlugin(String name) {
    return '$name 已删除';
  }

  @override
  String failedToDeletePlugin(String error) {
    return '删除插件失败：$error';
  }

  @override
  String get outputCopiedToClipboard => '输出已复制到剪贴板';

  @override
  String andMore(int count) {
    return '... 还有 $count 个';
  }

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String hoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String daysAgo(int count) {
    return '$count天前';
  }

  @override
  String universalAndAdditionalPlugins(int universal, int additional) {
    return '$universal 个通用 + $additional 个附加插件';
  }

  @override
  String get all => '全部';

  @override
  String get noPluginsMatchFilters => '没有插件匹配您的筛选条件';

  @override
  String get mobileCompatible => '移动端兼容';

  @override
  String installedThisSession(int count) {
    return '本次会话已安装 $count 个';
  }

  @override
  String get done => '完成';

  @override
  String get close => '关闭';

  @override
  String installedLanguage(String name, String language) {
    return '已安装 $name ($language)';
  }

  @override
  String failedToInstall(String name, String error) {
    return '安装 $name 失败：$error';
  }

  @override
  String get systemTray => '系统托盘';

  @override
  String get displayMode => '显示模式';

  @override
  String get unified => '统一';

  @override
  String get singleTrayIconWithMenu => '单个托盘图标带菜单显示所有插件';

  @override
  String get separate => '分离';

  @override
  String get oneTrayIconPerPlugin => '每个插件一个图标（仅限 Linux）';

  @override
  String get smartCollapse => '智能折叠';

  @override
  String get autoCollapseWhenManyPlugins => '插件过多时自动折叠';

  @override
  String get smartOverflow => '智能溢出';

  @override
  String get showFirstNIconsRestInOverflow => '显示前 N 个图标，其余在溢出菜单';

  @override
  String get comingSoon => '即将推出';

  @override
  String get trayDisplayMode => '托盘显示模式';

  @override
  String get unifiedSingleIconWithMenu => '统一（单图标带菜单）';

  @override
  String get separateOneIconPerPlugin => '分离（每插件一图标）';

  @override
  String get noConfigurationRequired => '无需配置';

  @override
  String get fiveMinutes => '5 分钟';

  @override
  String get licenseText =>
      'Crossbar - 通用插件系统\n\nCopyright (C) 2025\n\n本程序为自由软件：您可以根据自由软件基金会发布的 GNU Affero 通用公共许可证的条款重新分发和/或修改它，可以是许可证的第 3 版，也可以是（由您选择）任何更高版本。\n\n本程序的分发是希望它有用，但没有任何担保；甚至没有适销性或特定用途适用性的暗示担保。有关更多详细信息，请参阅 GNU Affero 通用公共许可证。\n\n您应该已经收到一份 GNU Affero 通用公共许可证的副本以及本程序。如果没有，请参阅 <https://www.gnu.org/licenses/>。';

  @override
  String get configureWidget => 'Configure Widget';

  @override
  String get selectOnePlugin => 'Select a plugin to display:';

  @override
  String selectUpToPlugins(int count) {
    return 'Select up to $count plugins:';
  }

  @override
  String get noEnabledPlugins =>
      'No enabled plugins found.\nEnable some plugins first.';

  @override
  String get selectAtLeastOnePlugin => 'Select at least one plugin';

  @override
  String get selected => 'Selected';
}
