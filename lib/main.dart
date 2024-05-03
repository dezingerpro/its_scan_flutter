import 'package:flutter/material.dart';
import 'package:its_scan/login_screen.dart';

void main() {
  runApp(ItsScannerApp());
}

class ItsScannerApp extends StatelessWidget {
  const ItsScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ITS Scanner',
      home: LoginPage(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false, // Removes the debug banner
    );
  }
}

