#!/usr/bin/env dart
/// Weather Plugin - Uses Crossbar API for HTTP requests
import 'dart:io';
import 'dart:convert';

String? crossbar(List<String> args) {
  try {
    final result = Process.runSync('crossbar', args);
    return result.exitCode == 0 ? (result.stdout as String).trim() : null;
  } catch (_) {
    return null;
  }
}

void main() {
  final apiKey = Platform.environment['WEATHER_API_KEY'] ?? '';
  final city = Platform.environment['WEATHER_CITY'] ?? 'London';

  if (apiKey.isEmpty) {
    print('🌡️ No API Key');
    print('---');
    print('Set WEATHER_API_KEY in configuration');
    return;
  }

  final url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';
  final response = crossbar(['--web', url, '--json']);

  if (response == null) {
    print('🌡️ Error');
    print('---');
    print('Failed to fetch weather data');
    return;
  }

  try {
    final data = jsonDecode(response) as Map<String, dynamic>;
    final temp = data['main']?['temp'] ?? '--';
    final desc = (data['weather'] as List?)?.first?['description'] ?? '';
    
    print('🌡️ ${temp}°C');
    print('---');
    print('Location: $city');
    print('Temperature: ${temp}°C');
    print('Condition: $desc');
  } catch (_) {
    print('🌡️ Parse Error');
  }

  print('---');
  print('Refresh | refresh=true');
}
