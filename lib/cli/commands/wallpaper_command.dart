import 'dart:io';

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

    if (values.isEmpty) {
      // Get
      final result = await api.getWallpaper();
      print(result);
    } else {
      // Set
      final path = values[0];
      final result = await api.setWallpaper(path);
      print(result ? 'Wallpaper set to $path' : 'Failed to set wallpaper');
      return result ? 0 : 1;
    }
    return 0;
  }
}
