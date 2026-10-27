import 'package:flutter/material.dart';

/// Cores Oficiais do Branding Book TARGET
class TargetColors {
  static const Color red = Color(0xFFFF1E2D); // Vermelho de Ação
  static const Color darkBg = Color(0xFF0B1117); // Preto Grafite (Fundo principal)
  static const Color panel = Color(0xFF111A23); // Carvão Azulado (Cards e painéis)
  static const Color panelAlt = Color(0xFF151F2A); // Carvão Secundário
  static const Color line = Color(0xFF26313D); // Cinza Ardósia (Bordas)
  static const Color textMuted = Color(0xFFA8B2BE); // Cinza Claro (Legendas)
  static const Color textWhite = Color(0xFFF5F7FA); // Branco Frio (Títulos)
  static const Color green = Color(0xFF35D49A); // Status online / Ativo
  static const Color amber = Color(0xFFFFB547); // Alerta / Parado
  static const Color blue = Color(0xFF45A8FF); // Informação
}

/// Símbolo Vetorial Oficial TARGET (Baseado na letra T e na estrada/avanço)
class TargetBrandmarkPainter extends CustomPainter {
  final Color? overrideColor;

  TargetBrandmarkPainter({this.overrideColor});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 64.0;
    final sy = size.height / 64.0;

    // Asa Superior (Vermelho de Ação)
    final path1 = Path()
      ..moveTo(7 * sx, 20 * sy)
      ..lineTo(51 * sx, 7 * sy)
      ..lineTo(43 * sx, 20 * sy)
      ..lineTo(3 * sx, 31 * sy)
      ..close();

    final paint1 = Paint()
      ..color = overrideColor ?? TargetColors.red
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path1, paint1);

    // Corpo Principal (Branco Frio / Estrada em Avanço)
    final path2 = Path()
      ..moveTo(20 * sx, 29 * sy)
      ..lineTo(48 * sx, 22 * sy)
      ..lineTo(25 * sx, 57 * sy)
      ..lineTo(10 * sx, 60 * sy)
      ..lineTo(26 * sx, 38 * sy)
      ..lineTo(16 * sx, 41 * sy)
      ..close();

    final paint2 = Paint()
      ..color = overrideColor ?? TargetColors.textWhite
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path2, paint2);

    // Detalhe / Sombra Geométrica Metálica
    final path3 = Path()
      ..moveTo(31 * sx, 31 * sy)
      ..lineTo(43 * sx, 28 * sy)
      ..lineTo(31 * sx, 46 * sy)
      ..lineTo(24 * sx, 48 * sy)
      ..close();

    final paint3 = Paint()
      ..color = overrideColor ?? const Color(0xFF8E9AA6)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant TargetBrandmarkPainter oldDelegate) =>
      oldDelegate.overrideColor != overrideColor;
}

/// Ícone do Símbolo Isolado TARGET
class TargetLogoIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const TargetLogoIcon({super.key, this.size = 38, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: TargetBrandmarkPainter(overrideColor: color),
      ),
    );
  }
}

/// Logo Horizontal Oficial (Símbolo + Wordmark TARGET + Descritor RASTREAMENTO VEICULAR)
class TargetLogoHorizontal extends StatelessWidget {
  final double iconSize;
  final bool compact;
  final Color? overrideColor;

  const TargetLogoHorizontal({
    super.key,
    this.iconSize = 36,
    this.compact = false,
    this.overrideColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TargetLogoIcon(size: iconSize, color: overrideColor),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TARGET',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: iconSize * 0.48,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                color: overrideColor ?? TargetColors.textWhite,
                height: 1.0,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 3),
              Text(
                'RASTREAMENTO VEICULAR',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: iconSize * 0.22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                  color: overrideColor ?? TargetColors.textMuted,
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Logo Vertical para telas de Login e Splash
class TargetLogo extends StatelessWidget {
  final double iconSize;
  final Color? color;

  const TargetLogo({super.key, this.iconSize = 64, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TargetLogoIcon(size: iconSize, color: color),
        const SizedBox(height: 14),
        Text(
          'TARGET',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: iconSize * 0.42,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.5,
            color: color ?? TargetColors.textWhite,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'RASTREAMENTO VEICULAR',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: iconSize * 0.17,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.2,
            color: color ?? TargetColors.textMuted,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
