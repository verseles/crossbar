#!/usr/bin/env dart
/// Weather Plugin - Uses Crossbar web API
import 'dart:convert';
import 'dart:io';

String? crossbarWeb(String url) {
  try {
    final result = Process.runSync('crossbar', ['web', url]);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
  } catch (_) {}
  return null;
}

void main() async {
  final apiKey = Platform.environment['WEATHER_API_KEY'] ?? '';
  final city = Platform.environment['WEATHER_CITY'] ?? 'London';

  if (apiKey.isEmpty) {
    print('🌡️ No API Key');
    print('---');
    print('Set WEATHER_API_KEY');
    return;
  }

  final url = 'api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

  // Try Crossbar web first
  var response = crossbarWeb(url);

  // Fallback to HttpClient
  if (response == null || response.isEmpty) {
    try {
      final request = await HttpClient().getUrl(Uri.parse('https://$url'));
      final httpResponse = await request.close();
      response = await httpResponse.transform(utf8.decoder).join();
    } catch (_) {}
  }

  if (response != null && response.isNotEmpty) {
    try {
      final data = jsonDecode(response) as Map<String, dynamic>;
      final temp = data['main']?['temp'] ?? '--';
      final desc = (data['weather'] as List?)?.first?['description'] ?? '';
      
      print('🌡️ $temp°C');
      print('---');
      print('Location: $city');
      print('Temperature: $temp°C');
      print('Condition: $desc');
    } catch (_) {
      print('🌡️ Parse Error');
    }
  } else {
    print('🌡️ Error');
    print('---');
    print('Failed to fetch data');
  }
  
  print('---');
  print('Refresh | refresh=true');
}
