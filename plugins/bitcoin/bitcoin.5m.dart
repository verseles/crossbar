#!/usr/bin/env dart
/// Bitcoin Price Plugin - Uses HttpClient
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() async {
  const url = 'https://api.coinbase.com/v2/prices/BTC-USD/spot';

  try {
    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    final data = jsonDecode(body) as Map<String, dynamic>;
    final price = data['data']?['amount'] ?? '--';
    
    String formatted;
    try {
      final numPrice = double.parse(price);
      formatted = NumberFormat('#,###').format(numPrice.round());
    } catch (_) {
      formatted = price;
    }
    
    print('₿ \$$formatted');
    print('---');
    print('BTC/USD: \$$price');
    print('Source: Coinbase');
  } catch (_) {
    print('₿ Error');
    print('---');
    print('Failed to fetch price');
  }

  print('---');
  print('Refresh | refresh=true');
}
