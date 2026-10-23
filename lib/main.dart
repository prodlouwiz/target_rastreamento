import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const TargetApp());
}

class TargetApp extends StatelessWidget {
  const TargetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Target Rastreamento',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.redAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.redAccent,
          secondary: Colors.white,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}