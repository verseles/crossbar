#!/usr/bin/env dart
/// Bitcoin Price Plugin - Uses Crossbar API for HTTP requests
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

String? crossbar(List<String> args) {
  try {
    final result = Process.runSync('crossbar', args);
    return result.exitCode == 0 ? (result.stdout as String).trim() : null;
  } catch (_) {
    return null;
  }
}

void main() {
  const url = 'https://api.coinbase.com/v2/prices/BTC-USD/spot';
  final response = crossbar(['--web', url, '--json']);

  if (response == null) {
    print('₿ Error');
    print('---');
    print('Failed to fetch price');
    return;
  }

  try {
    final data = jsonDecode(response) as Map<String, dynamic>;
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
    print('₿ Parse Error');
  }

  print('---');
  print('Refresh | refresh=true');
}
