import '../../core/api/utils_api.dart';
import 'base_command.dart';

class WallpaperCommand extends CliCommand {
  @override
  String get name => 'wallpaper';

  @override
  String get description => 'Get or set desktop wallpaper';

  @override
  Future<int> execute(List<String> args) async {
    const api = UtilsApi();
    final values = args.where((a) => !a.startsWith('--')).toList();
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    if (values.isEmpty) {
      // Get
      final result = await api.getWallpaper();
      printFormatted(
          {'wallpaper': result},
          json: jsonOutput,
          xml: xmlOutput,
          plain: (_) => result
      );
    } else {
      // Set
      final path = values[0];
      final result = await api.setWallpaper(path);
      printFormatted(
          {'success': result, 'wallpaper': path},
          json: jsonOutput,
          xml: xmlOutput,
          plain: (_) => result ? 'Wallpaper set to $path' : 'Failed to set wallpaper'
      );
      return result ? 0 : 1;
    }
    return 0;
  }
}
