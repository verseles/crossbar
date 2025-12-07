// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Crossbar';

  @override
  String get pluginsTab => '플러그인';

  @override
  String get settingsTab => '설정';

  @override
  String get marketplaceTab => '마켓플레이스';

  @override
  String get noPluginsFound => '플러그인을 찾을 수 없습니다';

  @override
  String get noPluginsDescription => '~/.crossbar/plugins 디렉토리에 플러그인을 추가하세요';

  @override
  String get refreshAll => '모두 새로고침';

  @override
  String get addPlugin => '플러그인 추가';

  @override
  String get enabled => '활성화됨';

  @override
  String get disabled => '비활성화됨';

  @override
  String get runNow => '지금 실행';

  @override
  String get configure => '구성';

  @override
  String get remove => '제거';

  @override
  String get lastRun => '최근 실행';

  @override
  String get refreshInterval => '새로고침 간격';

  @override
  String get seconds => '초';

  @override
  String get minutes => '분';

  @override
  String get hours => '시간';

  @override
  String get days => '일';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get apply => '적용';

  @override
  String get search => '검색';

  @override
  String get install => '설치';

  @override
  String get uninstall => '제거';

  @override
  String get update => '업데이트';

  @override
  String get installed => '설치됨';

  @override
  String get notInstalled => '설치되지 않음';

  @override
  String get language => '언어';

  @override
  String get theme => '테마';

  @override
  String get lightTheme => '라이트';

  @override
  String get darkTheme => '다크';

  @override
  String get systemTheme => '시스템';

  @override
  String get notifications => '알림';

  @override
  String get enableNotifications => '알림 활성화';

  @override
  String get startOnBoot => '부팅 시 시작';

  @override
  String get minimizeToTray => '트레이로 최소화';

  @override
  String get pluginsDirectory => '플러그인 디렉토리';

  @override
  String get openPluginsDirectory => '플러그인 디렉토리 열기';

  @override
  String get about => '정보';

  @override
  String get version => '버전';

  @override
  String get checkForUpdates => '업데이트 확인';

  @override
  String get noUpdatesAvailable => '업데이트 없음';

  @override
  String get updateAvailable => '업데이트 가능';

  @override
  String get errorOccurred => '오류가 발생했습니다';

  @override
  String get retry => '재시도';

  @override
  String get loading => '로딩 중...';

  @override
  String get noResults => '결과 없음';

  @override
  String get allLanguages => '모든 언어';

  @override
  String get allCategories => '모든 카테고리';

  @override
  String get popular => '인기';

  @override
  String get recent => '최신';

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
  String get system => '시스템';

  @override
  String get network => '네트워크';

  @override
  String get development => '개발';

  @override
  String get productivity => '생산성';

  @override
  String get finance => '금융';

  @override
  String get weather => '날씨';

  @override
  String get media => '미디어';

  @override
  String get social => '소셜';

  @override
  String get utilities => '유틸리티';

  @override
  String get other => '기타';

  @override
  String get appearance => '모양';

  @override
  String get behavior => '동작';

  @override
  String get license => '라이선스';

  @override
  String get useDarkTheme => '다크 테마 사용';

  @override
  String get launchOnLogin => '로그인 시 Crossbar 실행';

  @override
  String get keepInTray => '최소화 시 트레이 아이콘 유지';

  @override
  String get defaultRefreshInterval => '기본 새로고침 간격';

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
