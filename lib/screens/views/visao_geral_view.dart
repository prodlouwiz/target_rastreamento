import 'package:flutter/material.dart';

import '../map_screen.dart' show VeiculoInfo;

class VisaoGeralView extends StatelessWidget {
  final VeiculoInfo? veiculo;
  final String plate;
  final String model;
  final String clientName;
  final Function(int targetTab) onNavigateTab;

  const VisaoGeralView({
    super.key,
    this.veiculo,
    this.plate = 'MQA6E92',
    this.model = 'Chevrolet Corsa 2020',
    this.clientName = 'Vidal Rastreamento',
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return Scaffold(
          backgroundColor: const Color(0xFF0B1117),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Cabeçalho de Boas-Vindas
                    _buildHeader(isDesktop),
                    const SizedBox(height: 20),

                    // 2. Stat Cards Responsivos (4 em linha no Desktop, 2x2 no Celular)
                    _buildStatCards(isDesktop),
                    const SizedBox(height: 24),

                    // 3. Grid Principal: Mapa de Monitoramento + Seus Veículos
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildCardMapaMonitoramento(context),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: _buildCardSeusVeiculos(context),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildCardMapaMonitoramento(context),
                          const SizedBox(height: 16),
                          _buildCardSeusVeiculos(context),
                        ],
                      ),

                    const SizedBox(height: 28),

                    // 4. Atalhos de Acesso Rápido
                    _buildSectionTitle('Acesso rápido', 'Atalhos para tarefas frequentes'),
                    const SizedBox(height: 14),
                    _buildQuickAccessCards(isDesktop),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // CABEÇALHO DE BOAS-VINDAS
  Widget _buildHeader(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PAINEL DE CONTROLE',
                style: TextStyle(
                  color: Color(0xFFFF1E2D),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Olá, $clientName 👋',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aqui está um resumo da sua operação e dos veículos monitorados na região.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4 STAT CARDS RESPONSIVOS
  Widget _buildStatCards(bool isDesktop) {
    final isMoving = veiculo != null && veiculo!.velocidade > 0;
    final movingCount = isMoving ? '01' : '00';
    final movingSub = isMoving ? '● ${veiculo!.velocidade} km/h em rota' : '● 0 em rota agora';
    final parkingCount = isMoving ? '00' : '01';
    final parkingSub = isMoving ? '0 estacionados' : 'Estacionado em segurança';

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: _buildStatCard('Veículos cadastrados', '01', '1 ativo no período', Icons.directions_car, null)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Em movimento', movingCount, movingSub, Icons.timeline, const Color(0xFF35D49A))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Parados', parkingCount, parkingSub, Icons.local_parking, const Color(0xFFFFB300))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Alertas pendentes', '00', 'Sistema operacional', Icons.notifications_active, const Color(0xFF35D49A))),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Veículos', '01', '1 cadastrado', Icons.directions_car, null)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('Em movimento', movingCount, movingSub, Icons.timeline, const Color(0xFF35D49A))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatCard('Parados', parkingCount, parkingSub, Icons.local_parking, const Color(0xFFFFB300))),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('Alertas', '00', 'Operacional', Icons.notifications_active, const Color(0xFF35D49A))),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(String title, String val, String sub, IconData icon, Color? corDestaque) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111A23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              Icon(icon, size: 16, color: corDestaque ?? const Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: TextStyle(
              color: corDestaque ?? Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              color: corDestaque ?? const Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // CARD MAPA DE MONITORAMENTO (MACAÉ & RIO DAS OSTRAS)
  Widget _buildCardMapaMonitoramento(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111A23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mapa de monitoramento',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Macaé & Rio das Ostras · Atualização em tempo real 4G',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => onNavigateTab(1), // Vai para o Mapa Ao Vivo
                  child: const Text('Abrir mapa ↗', style: TextStyle(color: Color(0xFFFF1E2D), fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // Canvas do Mapa Vetorial Escuro
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: SizedBox(
              height: 280,
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFF0F1722),
                    width: double.infinity,
                    height: double.infinity,
                    child: CustomPaint(painter: _VectorGridMapPainter()),
                  ),

                  // Tag informativa de localização
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1117).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.radar, color: Color(0xFFFF1E2D), size: 13),
                          SizedBox(width: 6),
                          Text(
                            'RODOVIA AMARAL PEIXOTO & RJ-106 · RIO DAS OSTRAS/RJ',
                            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Marcador do Carro Ativo
                  Positioned(
                    left: 140,
                    top: 100,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFF1E2D), width: 1.2),
                            boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 10)],
                          ),
                          child: Text(
                            '🚘 $plate · $model',
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1E2D),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFFF1E2D).withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.navigation, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),

                  // Legenda do Mapa
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildLegendChip(const Color(0xFF35D49A), 'Origem (Costazul)'),
                        _buildLegendChip(const Color(0xFFFF1E2D), 'Destino (Jardim Mariléa)'),
                        _buildLegendChip(const Color(0xFF38BDF8), 'Cobertura 4G/5G Ativa'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1117).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  // CARD SEUS VEÍCULOS
  Widget _buildCardSeusVeiculos(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111A23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Seus veículos', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => onNavigateTab(1),
                child: const Text('Ver no mapa ↗', style: TextStyle(color: Color(0xFFFF1E2D), fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Veículo 1: O Carro Real do Usuário (MQA6E92)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF1E2D), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1E2D).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_car, color: Color(0xFFFF1E2D), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('$plate · GT06 · Rio das Ostras', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: Color(0xFFFF1E2D)),
                          SizedBox(width: 3),
                          Text('Av. Brasília, Costazul', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFFB300), width: 0.8),
                  ),
                  child: const Text('Parado', style: TextStyle(color: Color(0xFFFFB300), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Informações de Telemetria do Veículo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1722),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bateria Principal', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    Text('12,6 V · 98%', style: TextStyle(color: Color(0xFF35D49A), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Satélites GPS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    Text('16 satélites fixos', style: TextStyle(color: Color(0xFFFFB300), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sinal de Rede Celular', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    Text('4G LTE Conectado', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ATALHOS DE ACESSO RÁPIDO
  Widget _buildQuickAccessCards(bool isDesktop) {
    final card1 = _buildFeatureCard(
      icone: Icons.timeline,
      titulo: 'Consultar trajetos',
      desc: 'Revise percursos, paradas e velocidades no mapa interativo com reprodutor.',
      botao: 'Abrir histórico →',
      onTap: () => onNavigateTab(2), // Histórico
    );

    final card2 = _buildFeatureCard(
      icone: Icons.notifications_none,
      titulo: 'Central de alertas',
      desc: 'Veja eventos recentes de ignição, cercas virtuais e notificações.',
      botao: 'Ver eventos →',
      onTap: () => onNavigateTab(5), // Eventos
    );

    final card3 = _buildFeatureCard(
      icone: Icons.bar_chart,
      titulo: 'Relatórios operacionais',
      desc: 'Emita relatórios sobre velocidade, viagens e exporte em PDF ou Excel.',
      botao: 'Abrir relatórios →',
      onTap: () => onNavigateTab(4), // Relatórios
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: card1),
          const SizedBox(width: 14),
          Expanded(child: card2),
          const SizedBox(width: 14),
          Expanded(child: card3),
        ],
      );
    } else {
      return Column(
        children: [
          card1,
          const SizedBox(height: 12),
          card2,
          const SizedBox(height: 12),
          card3,
        ],
      );
    }
  }

  Widget _buildFeatureCard({
    required IconData icone,
    required String titulo,
    required String desc,
    required String botao,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111A23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1E2D).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: const Color(0xFFFF1E2D), size: 20),
          ),
          const SizedBox(height: 12),
          Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.4)),
          const SizedBox(height: 12),
          InkWell(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(botao, style: const TextStyle(color: Color(0xFFFF1E2D), fontSize: 11.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Text('· $subtitle', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
      ],
    );
  }
}

// PINTOR DO MAPA VETORIAL ILUSTRATIVO
class _VectorGridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    final roadPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = const Color(0xFFFF1E2D)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Grade de fundo
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Rodovia Amaral Peixoto (linha de base da via)
    final roadPath = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.60, size.width, size.height * 0.35);
    canvas.drawPath(roadPath, roadPaint);

    // Traçado Ativo em Vermelho Target
    final routePath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.58, size.width * 0.55, size.height * 0.48);
    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
