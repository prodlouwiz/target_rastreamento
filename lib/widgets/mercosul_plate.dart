import 'package:flutter/material.dart';

/// Componente visual da Placa Padrão Mercosul (Brasil).
/// Proporciona acabamento profissional para aplicativos automotivos e de rastreamento.
class MercosulPlate extends StatelessWidget {
  final String plate;
  final double width;
  final double height;
  final double fontSize;

  const MercosulPlate({
    super.key,
    required this.plate,
    this.width = 110,
    this.height = 38,
    this.fontSize = 15,
  });

  String get _formattedPlate {
    final clean = plate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (clean.length == 7) {
      // Formato Mercosul ABC1D23
      return clean;
    }
    return plate.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF212121), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Faixa azul superior do Mercosul
          Container(
            height: height * 0.30,
            decoration: const BoxDecoration(
              color: Color(0xFF003399), // Azul Mercosul
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ícone / brasão estilizado
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFCC00),
                    shape: BoxShape.circle,
                  ),
                ),
                const Text(
                  'BRASIL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                // Bandeira mini estilizada
                Container(
                  width: 8,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF009C3B),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          // Área da Placa
          Expanded(
            child: Center(
              child: Text(
                _formattedPlate,
                style: TextStyle(
                  color: const Color(0xFF111111),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

