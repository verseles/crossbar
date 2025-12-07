#!/usr/bin/env dart
/// Bitcoin Price Plugin - Uses Crossbar web API
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
  var response = crossbarWeb('api.coinbase.com/v2/prices/BTC-USD/spot');
  
  // Fallback to HttpClient
  if (response == null || response.isEmpty) {
    try {
      final request = await HttpClient()
          .getUrl(Uri.parse('https://api.coinbase.com/v2/prices/BTC-USD/spot'));
      final httpResponse = await request.close();
      response = await httpResponse.transform(utf8.decoder).join();
    } catch (_) {}
  }

  if (response != null && response.isNotEmpty) {
    try {
      final data = jsonDecode(response) as Map<String, dynamic>;
      final price = data['data']?['amount'] ?? '--';
      
      String formatted;
      try {
        final numPrice = double.parse(price);
        formatted = numPrice.round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
      } catch (_) {
        formatted = price;
      }
      
      print('₿ \$$formatted');
      print('---');
      print('BTC/USD: \$$price');
      print('Source: Coinbase');
    } catch (_) {
      print('₿ Parse Error');
    }
  } else {
    print('₿ Error');
    print('---');
    print('Failed to fetch price');
  }

  print('---');
  print('Refresh | refresh=true');
}
