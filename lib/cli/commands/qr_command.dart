// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

import 'base_command.dart';

/// CLI command to generate QR codes from text.
///
/// Supports two output modes:
/// - ASCII (default): Unicode block characters for terminal display
/// - Image (--image): Base64-encoded PNG for programmatic use
class QrCommand extends CliCommand {
  @override
  String get name => 'qr';

  @override
  String get description => 'Generate a QR code from text';

  @override
  Future<int> execute(List<String> args) async {
    if (args.isEmpty || args[0] == '--help' || args[0] == '-h') {
      _printUsage();
      return 0;
    }

    // Parse arguments
    final asImage = args.contains('--image');
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    // Extract size if provided
    var size = 200;
    final sizeIdx = args.indexOf('--size');
    if (sizeIdx != -1 && sizeIdx + 1 < args.length) {
      size = int.tryParse(args[sizeIdx + 1]) ?? 200;
    }

    // Get the data (first non-flag argument)
    final data = args.firstWhere(
      (arg) => !arg.startsWith('--'),
      orElse: () => '',
    );

    if (data.isEmpty) {
      stderr.writeln('Error: No text provided for QR code generation');
      return 1;
    }

    try {
      // Generate QR code matrix
      final qrCode = QrCode(4, QrErrorCorrectLevel.L)..addData(data);
      final qrImage = QrImage(qrCode);

      if (asImage) {
        final base64Png = _generatePngBase64(qrImage, size);
        printFormatted(
          {
            'data': data,
            'image': base64Png,
            'format': 'png',
            'encoding': 'base64',
          },
          json: jsonOutput,
          xml: xmlOutput,
          plain: (_) => base64Png,
        );
      } else {
        final ascii = _generateAscii(qrImage);
        printFormatted(
          {'data': data, 'qr': ascii},
          json: jsonOutput,
          xml: xmlOutput,
          plain: (_) => ascii,
        );
      }
      return 0;
    } catch (e) {
      stderr.writeln('Error generating QR code: $e');
      return 1;
    }
  }

  /// Generates ASCII representation using Unicode block characters.
  String _generateAscii(QrImage qrImage) {
    final sb = StringBuffer();
    final moduleCount = qrImage.moduleCount;

    // Quiet zone (top)
    for (var i = 0; i < 2; i++) {
      sb.writeln('  ${'  ' * moduleCount}  ');
    }

    for (var y = 0; y < moduleCount; y++) {
      sb.write('  '); // Quiet zone (left)
      for (var x = 0; x < moduleCount; x++) {
        sb.write(qrImage.isDark(y, x) ? '██' : '  ');
      }
      sb.writeln('  '); // Quiet zone (right)
    }

    // Quiet zone (bottom)
    for (var i = 0; i < 2; i++) {
      sb.writeln('  ${'  ' * moduleCount}  ');
    }

    return sb.toString();
  }

  /// Generates a Base64-encoded PNG image of the QR code.
  String _generatePngBase64(QrImage qrImage, int targetSize) {
    final moduleCount = qrImage.moduleCount;
    final pixelSize = (targetSize / moduleCount).floor().clamp(1, 100);
    final actualSize = pixelSize * moduleCount;

    final image = img.Image(width: actualSize, height: actualSize);

    // Fill with white background
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    // Draw black modules
    for (var y = 0; y < moduleCount; y++) {
      for (var x = 0; x < moduleCount; x++) {
        if (qrImage.isDark(y, x)) {
          img.fillRect(
            image,
            x1: x * pixelSize,
            y1: y * pixelSize,
            x2: (x + 1) * pixelSize,
            y2: (y + 1) * pixelSize,
            color: img.ColorRgb8(0, 0, 0),
          );
        }
      }
    }

    final pngBytes = img.encodePng(image);
    return base64Encode(pngBytes);
  }

  void _printUsage() {
    print('''
Usage: crossbar qr <text> [options]

Generate a QR code from the given text.

Options:
  --image           Output as Base64 encoded PNG image
  --size <px>       Image size in pixels (default: 200, only with --image)
  --json            Output in JSON format
  --xml             Output in XML format

Examples:
  crossbar qr "Hello World"
  crossbar qr "https://example.com" --image
  crossbar qr "data" --image --size 300
  crossbar qr "test" --json
''');
  }
}
