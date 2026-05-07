import 'package:flutter/material.dart';
import 'screens/scan_screen.dart';

void main() {
  runApp(const LanScannerApp());
}

class LanScannerApp extends StatelessWidget {
  const LanScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAN Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF58A6FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'monospace',
      ),
      home: const ScanScreen(),
    );
  }
}
