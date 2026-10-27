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
        scaffoldBackgroundColor: const Color(0xFF0B1117), // Preto Grafite (#0B1117)
        primaryColor: const Color(0xFFFF1E2D), // Vermelho Target (#FF1E2D)
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF1E2D),
          secondary: Color(0xFFA8B2BE), // Cinza Claro (#A8B2BE)
          surface: Color(0xFF111A23), // Carvão Azulado (#111A23)
        ),
        dividerColor: const Color(0xFF26313D), // Cinza Ardósia (#26313D)
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF26313D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF26313D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFF1E2D), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFFA8B2BE)),
          prefixIconColor: const Color(0xFFA8B2BE),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF1E2D),
            foregroundColor: const Color(0xFFF5F7FA),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      home: const LandingPageScreen(),
    );
  }
}
