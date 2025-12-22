/// Convert a Map to XML format
String mapToXml(Map<String, dynamic> data, {String root = 'crossbar'}) {
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<$root>');
  _mapToXml(data, buffer, indent: '  ');
  buffer.writeln('</$root>');
  return buffer.toString();
}

void _mapToXml(Map<String, dynamic> data, StringBuffer buffer, {String indent = ''}) {
  for (final entry in data.entries) {
    final key = entry.key.replaceAll(RegExp('[^a-zA-Z0-9_]'), '_');
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      buffer.writeln('$indent<$key>');
      _mapToXml(value, buffer, indent: '$indent  ');
      buffer.writeln('$indent</$key>');
    } else if (value is List) {
      buffer.writeln('$indent<$key>');
      for (final item in value) {
        if (item is Map<String, dynamic>) {
          buffer.writeln('$indent  <item>');
          _mapToXml(item, buffer, indent: '$indent    ');
          buffer.writeln('$indent  </item>');
        } else {
          buffer.writeln('$indent  <item>${escapeXml(item.toString())}</item>');
        }
      }
      buffer.writeln('$indent</$key>');
    } else {
      buffer.writeln('$indent<$key>${escapeXml(value.toString())}</$key>');
    }
  }
}

String escapeXml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
