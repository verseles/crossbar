import 'package:flutter/material.dart';

import 'ui/main_window.dart';

void main() {
  runApp(const CrossbarApp());
}

class CrossbarApp extends StatelessWidget {
  const CrossbarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainWindow();
  }
}
