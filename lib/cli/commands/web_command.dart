import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'base_command.dart';

/// HTTP client command powered by Dio
///
/// Usage:
///   `crossbar web <url> [options]`
/// 
/// Options:
///   --method GET|POST|PUT|DELETE|PATCH|HEAD  (default: GET)
///   --headers '{"key":"value"}'              JSON headers
///   --body '{"key":"value"}'                 Request body
///   --body-file path.json                    Read body from file
///   --timeout 10                             Timeout in seconds (default: 30)
///   --user-agent "Custom Agent"              Custom User-Agent
///   --insecure                               Skip SSL verification
///   --follow-redirects                       Follow redirects (default: true)
///   --json                                   Output as JSON
///   --xml                                    Output as XML
class WebCommand extends CliCommand {
  @override
  String get name => 'web';

  @override
  String get description => 'HTTP client (GET, POST, etc.)';

  @override
  Future<int> execute(List<String> args) async {
    // Show help
    if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
      stderr.writeln('Usage: crossbar web <url> [options]');
      stderr.writeln('');
      stderr.writeln('Options:');
      stderr.writeln('  --method GET|POST|PUT|DELETE|PATCH|HEAD');
      stderr.writeln('  --headers \'{"key":"value"}\'');
      stderr.writeln('  --body \'{"key":"value"}\'');
      stderr.writeln('  --body-file path.json');
      stderr.writeln('  --timeout 10');
      stderr.writeln('  --user-agent "Custom Agent"');
      stderr.writeln('  --insecure');
      stderr.writeln('  --json / --xml');
      stderr.writeln('');
      stderr.writeln('Examples:');
      stderr.writeln('  crossbar web api.github.com/users/octocat');
      stderr.writeln('  crossbar web httpbin.org/post --method POST --body \'{"test":1}\'');
      return args.isEmpty ? 1 : 0;
    }

    // Parse arguments
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');
    final insecure = args.contains('--insecure');
    final followRedirects = !args.contains('--no-redirects');

    // Extract URL (first non-flag argument)
    String? url;
    for (final arg in args) {
      if (!arg.startsWith('--')) {
        url = arg;
        break;
      }
    }

    if (url == null || url.isEmpty) {
      stderr.writeln('Error: URL is required');
      return 1;
    }

    // Auto-prefix https:// if no protocol specified
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    // Parse options
    var method = 'GET';
    Map<String, dynamic>? headers;
    dynamic body;
    var timeout = 30;
    String? userAgent;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      final hasNext = i + 1 < args.length;

      switch (arg) {
        case '--method':
          if (hasNext) method = args[++i].toUpperCase();
        case '--headers':
          if (hasNext) {
            try {
              headers = jsonDecode(args[++i]) as Map<String, dynamic>;
            } catch (e) {
              stderr.writeln('Error: Invalid JSON in --headers');
              return 1;
            }
          }
        case '--body':
          if (hasNext) {
            final bodyStr = args[++i];
            // Try to parse as JSON, otherwise use as string
            try {
              body = jsonDecode(bodyStr);
            } catch (_) {
              body = bodyStr;
            }
          }
        case '--body-file':
          if (hasNext) {
            final filePath = args[++i];
            try {
              final file = File(filePath);
              if (!file.existsSync()) {
                stderr.writeln('Error: Body file not found: $filePath');
                return 1;
              }
              final content = file.readAsStringSync();
              try {
                body = jsonDecode(content);
              } catch (_) {
                body = content;
              }
            } catch (e) {
              stderr.writeln('Error reading body file: $e');
              return 1;
            }
          }
        case '--timeout':
          if (hasNext) timeout = int.tryParse(args[++i]) ?? 30;
        case '--user-agent':
          if (hasNext) userAgent = args[++i];
      }
    }

    // Configure Dio
    final dio = Dio(BaseOptions(
      connectTimeout: Duration(seconds: timeout),
      receiveTimeout: Duration(seconds: timeout),
      sendTimeout: Duration(seconds: timeout),
      followRedirects: followRedirects,
      maxRedirects: 5,
      validateStatus: (status) => true, // Accept all status codes
      headers: {
        'User-Agent': userAgent ?? 'Crossbar/1.0',
        if (headers != null) ...headers,
      },
    ));

    // Handle insecure (skip SSL verification)
    if (insecure) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
    }

    try {
      final Response<dynamic> response;

      switch (method) {
        case 'GET':
          response = await dio.get<dynamic>(url);
        case 'POST':
          response = await dio.post<dynamic>(url, data: body);
        case 'PUT':
          response = await dio.put<dynamic>(url, data: body);
        case 'DELETE':
          response = await dio.delete<dynamic>(url, data: body);
        case 'PATCH':
          response = await dio.patch<dynamic>(url, data: body);
        case 'HEAD':
          response = await dio.head<dynamic>(url);
        default:
          stderr.writeln('Error: Unknown method: $method');
          return 1;
      }

      // Build result
      final result = <String, dynamic>{
        'status': response.statusCode,
        'statusMessage': response.statusMessage,
      };

      // Add response body
      if (response.data != null) {
        if (response.data is Map || response.data is List) {
          result['data'] = response.data;
        } else {
          // Try to parse as JSON
          try {
            result['data'] = jsonDecode(response.data.toString());
          } catch (_) {
            result['data'] = response.data.toString();
          }
        }
      }

      // Add headers if JSON/XML output requested
      if (jsonOutput || xmlOutput) {
        result['headers'] = response.headers.map.map(
          (key, value) => MapEntry(key, value.length == 1 ? value.first : value),
        );
      }

      // Output
      printFormatted(
        result,
        json: jsonOutput,
        xml: xmlOutput,
        xmlRoot: 'response',
        plain: (_) {
          // For plain output, just return the body
          final data = result['data'];
          if (data is String) return data;
          if (data is Map || data is List) return jsonEncode(data);
          return data?.toString() ?? '';
        },
      );

      // Return non-zero for HTTP errors in non-JSON mode
      final statusCode = response.statusCode ?? 0;
      if (!jsonOutput && !xmlOutput && statusCode >= 400) {
        return 1;
      }

      return 0;
    } on DioException catch (e) {
      final errorData = <String, dynamic>{
        'error': true,
        'type': e.type.toString(),
        'message': e.message ?? 'Unknown error',
      };

      if (e.response != null) {
        errorData['status'] = e.response?.statusCode;
        errorData['data'] = e.response?.data;
      }

      printFormatted(
        errorData,
        json: jsonOutput,
        xml: xmlOutput,
        xmlRoot: 'error',
        plain: (_) => 'Error: ${e.message}',
      );
      return 1;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }
}
