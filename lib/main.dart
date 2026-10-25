import 'package:flutter/material.dart';
import 'screens/landing_page_screen.dart';

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
        scaffoldBackgroundColor: const Color(0xFF121212), // Preto Profundo
        primaryColor: const Color(0xFFFF5252), // Vermelho Target
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5252),
          secondary: Color(0xFF9E9E9E), // Cinza Secundário
          surface: Color(0xFF1E1E1E), // Cinza Superfície
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF9E9E9E)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF9E9E9E).withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
          prefixIconColor: const Color(0xFF9E9E9E),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5252),
            foregroundColor: const Color(0xFFFFFFFF),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
      home: const LandingPageScreen(),
    );
  }
}
