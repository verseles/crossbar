import 'package:crossbar_core/crossbar_core.dart';

void main() {
  final bridge = CrossbarBridge.instance;
  
  print('Time HH:mm:ss.SSS: ${bridge.time('HH:mm:ss.SSS')}');
  print('Date MM/dd/yyyy: ${bridge.date('MM/dd/yyyy')}');
  print('Date long: ${bridge.date('EEEE, MMMM d, yyyy')}');
  print('UUID: ${bridge.uuid()}');
}
