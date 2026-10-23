import 'package:flutter/material.dart';

class TargetLogo extends StatelessWidget {
  final double iconSize;

  const TargetLogo({super.key, this.iconSize = 80});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.radar,
          size: iconSize,
          color: const Color(0xFFFF5252), // Vermelho Target (#FF5252)
        ),
        const SizedBox(height: 16),
        const Text(
          'TARGET',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 4.0,
            color: Color(0xFFFFFFFF), // Branco
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'RASTREAMENTO VEICULAR',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            letterSpacing: 3.0,
            color: Color(0xFF9E9E9E), // Cinza Secundário
          ),
        ),
      ],
    );
  }
}

