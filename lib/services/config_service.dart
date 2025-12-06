// Conditional export: use stub for pure Dart, full implementation for Flutter
export 'plugin_config_service_stub.dart'
    if (dart.library.ui) 'plugin_config_service.dart';
