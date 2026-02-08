// ignore_for_file: avoid_print
import 'dart:io';

import 'package:dio/dio.dart';

import 'base_command.dart';

/// CLI command for geolocation: IP lookup, geocoding, and reverse geocoding.
///
/// Usage:
///   `crossbar location`              - Geolocate current IP
///   `crossbar location <ip>`         - Geolocate specific IP
///   `crossbar location geocode <address>` - Address to coordinates
///   `crossbar location reverse <lat> <lon>` - Coordinates to address
class LocationCommand extends CliCommand {
  @override
  String get name => 'location';

  @override
  String get description =>
      'Get location from IP, geocode address, or reverse geocode coordinates';

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'User-Agent': 'Crossbar/1.12'},
  ));

  @override
  Future<int> execute(List<String> args) async {
    if (args.contains('--help') || args.contains('-h')) {
      _printUsage();
      return 0;
    }

    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    // Strip flags from args for positional parsing
    final positional =
        args.where((a) => !a.startsWith('--')).toList();

    try {
      if (positional.isEmpty) {
        // No args: geolocate caller's IP
        return _outputResult(
          await _ipGeolocate(),
          json: jsonOutput,
          xml: xmlOutput,
        );
      }

      final subcommand = positional[0];

      if (subcommand == 'geocode') {
        if (positional.length < 2) {
          stderr.writeln('Error: geocode requires an address');
          return 1;
        }
        final address = positional.sublist(1).join(' ');
        return _outputResult(
          await _geocode(address),
          json: jsonOutput,
          xml: xmlOutput,
        );
      }

      if (subcommand == 'reverse') {
        if (positional.length < 3) {
          stderr.writeln('Error: reverse requires <lat> <lon>');
          return 1;
        }
        final lat = double.tryParse(positional[1]);
        final lon = double.tryParse(positional[2]);
        if (lat == null || lon == null) {
          stderr.writeln('Error: Invalid coordinates');
          return 1;
        }
        return _outputResult(
          await _reverseGeocode(lat, lon),
          json: jsonOutput,
          xml: xmlOutput,
        );
      }

      // Otherwise treat as IP address
      return _outputResult(
        await _ipGeolocate(subcommand),
        json: jsonOutput,
        xml: xmlOutput,
      );
    } on DioException catch (e) {
      stderr.writeln('Error: Network request failed: ${e.message}');
      return 1;
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }
  }

  int _outputResult(
    Map<String, dynamic> data, {
    required bool json,
    required bool xml,
  }) {
    printFormatted(
      data,
      json: json,
      xml: xml,
      xmlRoot: 'location',
      plain: (_) => _formatPlain(data),
    );
    return 0;
  }

  String _formatPlain(Map<String, dynamic> data) {
    final lines = <String>[];

    // IP geolocation output
    if (data.containsKey('city') && data.containsKey('ip')) {
      final city = data['city'] ?? '';
      final region = data['region'] ?? '';
      final country = data['country'] ?? '';
      final locationParts =
          [city, region, country].where((s) => s.isNotEmpty).join(', ');
      lines.add('Location: $locationParts');
      lines.add('IP: ${data['ip']}');
      if (data['latitude'] != null && data['longitude'] != null) {
        lines.add('Coordinates: ${data['latitude']}, ${data['longitude']}');
      }
      if (data['timezone'] != null) {
        lines.add('Timezone: ${data['timezone']}');
      }
      if (data['org'] != null) {
        lines.add('ISP: ${data['org']}');
      }
      if (data['postal'] != null) {
        lines.add('Postal: ${data['postal']}');
      }
    }
    // Geocode output
    else if (data.containsKey('query') && data.containsKey('latitude')) {
      lines.add('Query: ${data['query']}');
      lines.add('Coordinates: ${data['latitude']}, ${data['longitude']}');
      if (data['display_name'] != null) {
        lines.add('Address: ${data['display_name']}');
      }
    }
    // Reverse geocode output
    else if (data.containsKey('display_name') &&
        data.containsKey('latitude')) {
      lines.add('Address: ${data['display_name']}');
      lines.add('Coordinates: ${data['latitude']}, ${data['longitude']}');
      if (data['city'] != null) {
        lines.add('City: ${data['city']}');
      }
      if (data['country'] != null) {
        lines.add('Country: ${data['country']}');
      }
    }

    return lines.join('\n');
  }

  /// Geolocate an IP address using ipapi.co with ip-api.com as fallback.
  Future<Map<String, dynamic>> _ipGeolocate([String? ip]) async {
    // Try ipapi.co first
    try {
      final url =
          ip != null ? 'https://ipapi.co/$ip/json/' : 'https://ipapi.co/json/';
      final response = await _dio.get<Map<String, dynamic>>(url);
      final data = response.data;
      if (data != null && data['error'] != true) {
        return {
          'ip': data['ip'] ?? ip ?? '',
          'city': data['city'] ?? '',
          'region': data['region'] ?? '',
          'country': data['country_name'] ?? '',
          'country_code': data['country_code'] ?? '',
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'timezone': data['timezone'],
          'org': data['org'],
          'postal': data['postal'],
          'currency': data['currency'],
        };
      }
    } catch (_) {
      // Fall through to fallback
    }

    // Fallback: ip-api.com
    final fallbackUrl = ip != null
        ? 'http://ip-api.com/json/$ip'
        : 'http://ip-api.com/json/';
    final response = await _dio.get<Map<String, dynamic>>(fallbackUrl);
    final data = response.data;
    if (data == null || data['status'] == 'fail') {
      throw Exception(data?['message'] ?? 'Geolocation failed');
    }
    return {
      'ip': data['query'] ?? ip ?? '',
      'city': data['city'] ?? '',
      'region': data['regionName'] ?? '',
      'country': data['country'] ?? '',
      'country_code': data['countryCode'] ?? '',
      'latitude': data['lat'],
      'longitude': data['lon'],
      'timezone': data['timezone'],
      'org': data['isp'] ?? data['org'],
      'postal': data['zip'],
    };
  }

  /// Convert an address to coordinates using Nominatim (OpenStreetMap).
  Future<Map<String, dynamic>> _geocode(String address) async {
    final response = await _dio.get<List<dynamic>>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'q': address,
        'format': 'json',
        'limit': '1',
      },
    );
    final results = response.data;
    if (results == null || results.isEmpty) {
      throw Exception('No results found for: $address');
    }
    final place = results[0] as Map<String, dynamic>;
    return {
      'query': address,
      'latitude': double.tryParse(place['lat']?.toString() ?? '') ?? 0.0,
      'longitude': double.tryParse(place['lon']?.toString() ?? '') ?? 0.0,
      'display_name': place['display_name'],
      'type': place['type'],
    };
  }

  /// Convert coordinates to an address using Nominatim (OpenStreetMap).
  Future<Map<String, dynamic>> _reverseGeocode(
      double lat, double lon) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://nominatim.openstreetmap.org/reverse',
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'json',
      },
    );
    final data = response.data;
    if (data == null || data['error'] != null) {
      throw Exception(data?['error'] ?? 'Reverse geocoding failed');
    }
    final address = data['address'] as Map<String, dynamic>? ?? {};
    return {
      'latitude': lat,
      'longitude': lon,
      'display_name': data['display_name'],
      'city': address['city'] ?? address['town'] ?? address['village'] ?? '',
      'state': address['state'] ?? '',
      'country': address['country'] ?? '',
      'country_code': address['country_code'] ?? '',
      'postal': address['postcode'],
    };
  }

  void _printUsage() {
    print('''
Usage: crossbar location [subcommand] [options]

Get geolocation from IP, geocode address, or reverse geocode coordinates.

Subcommands:
  (none)                      Geolocate your current IP
  <ip>                        Geolocate a specific IP address
  geocode <address>           Convert address to coordinates
  reverse <lat> <lon>         Convert coordinates to address

Options:
  --json            Output in JSON format
  --xml             Output in XML format

Examples:
  crossbar location
  crossbar location 8.8.8.8
  crossbar location geocode "São Paulo, Brazil"
  crossbar location reverse -23.55 -46.63
  crossbar location --json
  crossbar location 8.8.8.8 --json
''');
  }
}
