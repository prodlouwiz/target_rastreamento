import 'dart:math' as math;
import 'package:flutter/material.dart';

class DashboardView extends StatefulWidget {
  final String plate;
  final String model;
  final String deviceType;
  final String clientName;

  const DashboardView({
    super.key,
    this.plate = 'MQA6E92',
    this.model = 'Chevrolet Corsa 2020',
    this.deviceType = 'GT06',
    this.clientName = 'Vidal Rastreamento',
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  DateTime _startDate = DateTime(2026, 10, 29);
  DateTime _endDate = DateTime(2026, 10, 29);
  final int _speedLimit = 90;
  bool _isSyncing = false;
  String _lastSync = '22:24:42 29.10.2026';

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      final now = DateTime.now();
      final h = now.hour.toString().padLeft(2, '0');
      final m = now.minute.toString().padLeft(2, '0');
      final s = now.second.toString().padLeft(2, '0');
      setState(() {
        _lastSync = '$h:$m:$s 29.10.2026';
        _isSyncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard sincronizado com a telemetria do veículo!'),
          backgroundColor: Color(0xFF1E293B),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1080;

        return Scaffold(
          backgroundColor: const Color(0xFF0B1117),
          body: Column(
            children: [
              // 1. Barra de Filtro de Período & Limite de Velocidade
              _buildTopFilterBar(),

              // 2. Conteúdo Principal
              Expanded(
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Coluna Esquerda: Árvore de Objetos (Desktop)
                          SizedBox(
                            width: 320,
                            child: _buildObjetosTree(),
                          ),
                          const VerticalDivider(color: Color(0xFF1E293B), width: 1),
                          // Coluna Direita: Dashboard Completo
                          Expanded(
                            child: _buildMainDashboardScrollable(),
                          ),
                        ],
                      )
                    : _buildMainDashboardScrollable(),
              ),

              // 3. Rodapé com Sincronização & Exportar
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  // BARRA DE FILTRO SUPERIOR
  Widget _buildTopFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF111A23),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.analytics_outlined, color: Color(0xFFFF1E2D), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Dashboard de Telemetria',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // Seletor Data Inicial
          _buildDatePill(
            label: 'Data de Início',
            date: '${_startDate.day.toString().padLeft(2, '0')}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.year}',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _startDate = picked);
            },
          ),

          // Seletor Data Final
          _buildDatePill(
            label: 'End Date',
            date: '${_endDate.day.toString().padLeft(2, '0')}.${_endDate.month.toString().padLeft(2, '0')}.${_endDate.year}',
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _endDate = picked);
            },
          ),

          // Botão Pesquisar
          InkWell(
            onTap: _syncData,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Filtrar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Limite de Velocidade
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: true,
                activeColor: const Color(0xFFFF1E2D),
                checkColor: Colors.white,
                onChanged: (_) {},
              ),
              Text(
                'Speed limit: $_speedLimit km/h',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePill({required String label, required String date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            Text(date, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today, color: Color(0xFF38BDF8), size: 13),
          ],
        ),
      ),
    );
  }

  // ÁRVORE DE OBJETOS (COLUNA LATERAL)
  Widget _buildObjetosTree() {
    return Container(
      color: const Color(0xFF0F1722),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF16202C),
            child: const Row(
              children: [
                Icon(Icons.directions_car, color: Color(0xFF38BDF8), size: 16),
                SizedBox(width: 8),
                Text('Objetos Monitorados', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grupo do Cliente
                Row(
                  children: [
                    const Icon(Icons.folder_open, color: Color(0xFFFFB300), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      widget.clientName,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Item do Veículo Selecionado
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF1E2D), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_box, color: Color(0xFFFF1E2D), size: 18),
                      const SizedBox(width: 8),
                      const Icon(Icons.directions_car, color: Color(0xFF35D49A), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.plate, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('${widget.model} · ${widget.deviceType}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF35D49A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Online', style: TextStyle(color: Color(0xFF35D49A), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // DASHBOARD PRINCIPAL SCROLLABLE
  Widget _buildMainDashboardScrollable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEÇÃO 1: INFOBLOCOS DO VEÍCULO (12+ CARDS)
          _buildSectionHeader('Infoblocos do veículo', Icons.grid_view),
          const SizedBox(height: 10),
          _buildInfoblocksGrid(),

          const SizedBox(height: 24),

          // SEÇÃO 2: SPEED PIES (DONUT CHARTS)
          _buildSectionHeader('Speed pies (Objetos: 1)', Icons.pie_chart_outline),
          const SizedBox(height: 10),
          _buildSpeedPiesRow(),

          const SizedBox(height: 24),

          // SEÇÃO 3: VEHICLE GRAPHS (GRÁFICOS DE DIAS)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Vehicle graphs', Icons.bar_chart),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Text('Dividir por dias', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildVehicleGraphsRow(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ],
    );
  }

  // GRADE DE INFOBLOCOS (KPI CARDS)
  Widget _buildInfoblocksGrid() {
    final items = [
      {'title': 'Amount of expenses', 'val': '0,00', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Idle time', 'val': '22h 39min', 'cor': const Color(0xFF94A3B8)},
      {'title': 'Ignition time', 'val': '1h 19min', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Combustível consumido', 'val': '0,00 l', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Duração de estacionamento', 'val': '27min', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Driving time', 'val': '1h 12min', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Driving distance', 'val': '13,80 km', 'cor': const Color(0xFF35D49A)},
      {'title': 'Número do veículo', 'val': widget.plate, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Modelo', 'val': 'Chevrolet Corsa', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Ano de lançamento', 'val': '2020', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Código VIN', 'val': '9BG116490LC...', 'cor': const Color(0xFF94A3B8)},
      {'title': 'Número do motor', 'val': 'N20X148...', 'cor': const Color(0xFF94A3B8)},
      {'title': 'Tipo de dispositivo', 'val': 'GT06', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Período', 'val': '29.10.2026 - 29.10.2026', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Número de viagens', 'val': '3', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Combustível abastecido', 'val': '0,00 l', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Combustível drenado', 'val': '0,00 l', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Média de veículos on-line', 'val': '1', 'cor': const Color(0xFF35D49A)},
      {'title': 'Consumo de combustível', 'val': '0,00 km/l', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Ocioso por dia', 'val': '22h 39min', 'cor': const Color(0xFF94A3B8)},
      {'title': 'Average work time in day', 'val': '1h 19min', 'cor': const Color(0xFF38BDF8)},
      {'title': 'Average mileage in period', 'val': '13,80 km', 'cor': const Color(0xFF35D49A)},
      {'title': 'Km costs', 'val': '0', 'cor': const Color(0xFF38BDF8)},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 6 : (constraints.maxWidth > 600 ? 3 : 2);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 2.3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final it = items[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF111A23),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    it['title'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    it['val'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: it['cor'] as Color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // SPEED PIES (DONUT CHARTS)
  Widget _buildSpeedPiesRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isRow = constraints.maxWidth >= 700;

        final pieQuilometragem = _buildPieCard(
          title: 'Quilometragem',
          chart: CustomPaint(
            size: const Size(130, 130),
            painter: _DonutChartPainter(
              lowRatio: 1.0, // < 60 km/h: 100%
              midRatio: 0.0, // 60 - 90 km/h: 0%
              highRatio: 0.0, // > 90 km/h: 0%
            ),
          ),
        );

        final pieTempo = _buildPieCard(
          title: 'Tempo',
          chart: CustomPaint(
            size: const Size(130, 130),
            painter: _DonutChartPainter(
              lowRatio: 0.96, // < 60 km/h: 96%
              midRatio: 0.04, // 60 - 90 km/h: 4%
              highRatio: 0.0, // > 90 km/h: 0%
            ),
          ),
        );

        if (isRow) {
          return Row(
            children: [
              Expanded(child: pieQuilometragem),
              const SizedBox(width: 14),
              Expanded(child: pieTempo),
            ],
          );
        } else {
          return Column(
            children: [
              pieQuilometragem,
              const SizedBox(height: 12),
              pieTempo,
            ],
          );
        }
      },
    );
  }

  Widget _buildPieCard({required String title, required Widget chart}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111A23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          chart,
          const SizedBox(height: 14),
          // Legenda
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('< 60 km/h', const Color(0xFF38BDF8)),
              const SizedBox(width: 14),
              _buildLegendItem('60 - 90 km/h', const Color(0xFF818CF8)),
              const SizedBox(width: 14),
              _buildLegendItem('> 90 km/h', const Color(0xFF34D399)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
      ],
    );
  }

  // VEHICLE GRAPHS (BAR CHARTS POR DIA)
  Widget _buildVehicleGraphsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMulti = constraints.maxWidth >= 700;

        final graph1 = _buildBarGraphCard('Cars on line, Cars', '1', '29.10', 1.0, 2.0);
        final graph2 = _buildBarGraphCard('Driving distance, km', '13.8 km', '29.10', 13.8, 16.0);
        final graph3 = _buildBarGraphCard('Driving time, horas', '1.2 h', '29.10', 1.2, 4.0);
        final graph4 = _buildBarGraphCard('Combustível consumido, l', '0.00 l', '29.10', 0.0, 10.0);

        if (isMulti) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: graph1),
                  const SizedBox(width: 12),
                  Expanded(child: graph2),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: graph3),
                  const SizedBox(width: 12),
                  Expanded(child: graph4),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              graph1,
              const SizedBox(height: 10),
              graph2,
              const SizedBox(height: 10),
              graph3,
              const SizedBox(height: 10),
              graph4,
            ],
          );
        }
      },
    );
  }

  Widget _buildBarGraphCard(String title, String currentVal, String dayLabel, double val, double maxVal) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111A23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(currentVal, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          // Gráfico de barra simples
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Eixo Y
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${maxVal.toInt()}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                    Text('${(maxVal / 2).toInt()}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                    const Text('0', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                  ],
                ),
                const SizedBox(width: 12),
                // Área da barra
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Linhas de Grade
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(height: 1, color: const Color(0xFF1E293B)),
                          Container(height: 1, color: const Color(0xFF1E293B)),
                          Container(height: 1, color: const Color(0xFF334155)),
                        ],
                      ),
                      // Barra preenchida
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: maxVal > 0 ? (val / maxVal).clamp(0.05, 1.0) : 0.05,
                          widthFactor: 0.18,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(dayLabel, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // RODAPÉ DE SINCRONIZAÇÃO & EXPORTAR
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF111A23),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: _isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF1E2D)),
                  )
                : const Icon(Icons.sync, size: 16, color: Color(0xFF38BDF8)),
            label: const Text('Sync now', style: TextStyle(fontSize: 11)),
            onPressed: _isSyncing ? null : _syncData,
          ),
          const SizedBox(width: 12),
          Text(
            'Last sync\'d at $_lastSync',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.download, size: 16, color: Color(0xFF35D49A)),
            label: const Text('Exportar', style: TextStyle(fontSize: 11)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Relatório de dados exportado com sucesso (CSV / Excel).'),
                  backgroundColor: Color(0xFF1E293B),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// PINTOR CUSTOMIZADO DO DONUT CHART (SPEED PIES)
class _DonutChartPainter extends CustomPainter {
  final double lowRatio;
  final double midRatio;
  final double highRatio;

  _DonutChartPainter({
    required this.lowRatio,
    required this.midRatio,
    required this.highRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;

    final lowPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final midPaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final highPaint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2));

    double startAngle = -math.pi / 2;

    // Arco < 60 km/h
    final sweepLow = 2 * math.pi * lowRatio;
    if (sweepLow > 0) {
      canvas.drawArc(rect, startAngle, sweepLow, false, lowPaint);
      startAngle += sweepLow;
    }

    // Arco 60 - 90 km/h
    final sweepMid = 2 * math.pi * midRatio;
    if (sweepMid > 0) {
      canvas.drawArc(rect, startAngle, sweepMid, false, midPaint);
      startAngle += sweepMid;
    }

    // Arco > 90 km/h
    final sweepHigh = 2 * math.pi * highRatio;
    if (sweepHigh > 0) {
      canvas.drawArc(rect, startAngle, sweepHigh, false, highPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.lowRatio != lowRatio || oldDelegate.midRatio != midRatio || oldDelegate.highRatio != highRatio;
  }
}
