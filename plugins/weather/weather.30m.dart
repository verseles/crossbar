#!/usr/bin/env dart
/// Weather Plugin - Uses HttpClient
import 'dart:io';
import 'dart:convert';

void main() async {
  final apiKey = Platform.environment['WEATHER_API_KEY'] ?? '';
  final city = Platform.environment['WEATHER_CITY'] ?? 'London';

  if (apiKey.isEmpty) {
    print('🌡️ No API Key');
    print('---');
    print('Set WEATHER_API_KEY');
    return;
  }

  final url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

  try {
    final request = await HttpClient().getUrl(Uri.parse(url));
    finalresponse = await request.close();
    final body = await finalresponse.transform(utf8.decoder).join();
    
    final data = jsonDecode(body) as Map<String, dynamic>;
    final temp = data['main']?['temp'] ?? '--';
    final desc = (data['weather'] as List?)?.first?['description'] ?? '';
    
    print('🌡️ ${temp}°C');
    print('---');
    print('Location: $city');
    print('Temperature: ${temp}°C');
    print('Condition: $desc');
  } catch (_) {
    print('🌡️ Error');
    print('---');
    print('Failed to fetch data');
  }
  
  print('---');
  print('Refresh | refresh=true');
}
