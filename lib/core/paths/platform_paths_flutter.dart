import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String> getMobilePluginsDirectory() async {
  final appDir = await getApplicationDocumentsDirectory();
  return path.join(appDir.path, 'plugins');
}
