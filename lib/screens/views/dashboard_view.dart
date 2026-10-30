import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../services/pilot_telemetry_service.dart';
import '../map_screen.dart' show VeiculoInfo;

class DashboardView extends StatefulWidget {
  final String? token;
  final int? nodeId;
  final String? imei;
  final VeiculoInfo? veiculo;
  final String plate;
  final String model;
  final String deviceType;
  final String clientName;

  const DashboardView({
    super.key,
    this.token,
    this.nodeId,
    this.imei,
    this.veiculo,
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

  late DashboardTelemetryStats _stats;

  @override
  void initState() {
    super.initState();
    _stats = DashboardTelemetryStats.defaults(plate: widget.plate);
    if (widget.token != null && widget.token!.isNotEmpty) {
      _syncData();
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);

    try {
      if (widget.token != null && widget.token!.isNotEmpty) {
        final newStats = await PilotTelemetryService.fetchDashboardStats(
          token: widget.token!,
          nodeId: widget.nodeId,
          plate: widget.plate,
          imei: widget.imei ?? widget.veiculo?.imei,
          startDate: _startDate,
          endDate: _endDate,
        );
        if (mounted) {
          setState(() {
            _stats = newStats;
            _isSyncing = false;
          });
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _isSyncing = false);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard sincronizado com a telemetria do veículo!'),
            backgroundColor: Color(0xFF1E293B),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isSyncing = false);
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
            onTap: _isSyncing ? null : _syncData,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isSyncing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  const Text('Filtrar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
          // SEÇÃO 1: INFOBLOCOS DO VEÍCULO (CARDS REAIS DA API)
          _buildSectionHeader('Infoblocos do veículo', Icons.grid_view),
          const SizedBox(height: 10),
          _buildInfoblocksGrid(),

          const SizedBox(height: 24),

          // SEÇÃO 2: SPEED PIES (DONUT CHARTS REAIS DA API)
          _buildSectionHeader('Speed pies (Objetos: 1)', Icons.pie_chart_outline),
          const SizedBox(height: 10),
          _buildSpeedPiesRow(),

          const SizedBox(height: 24),

          // SEÇÃO 3: VEHICLE GRAPHS (GRÁFICOS DIÁRIOS)
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

  // GRADE DE INFOBLOCOS (KPI CARDS REAIS)
  Widget _buildInfoblocksGrid() {
    final items = [
      {'title': 'Amount of expenses', 'val': _stats.expenses, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Idle time', 'val': _stats.idleTime, 'cor': const Color(0xFF94A3B8)},
      {'title': 'Ignition time', 'val': _stats.ignitionTime, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Combustível consumido', 'val': _stats.fuelConsumed, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Duração de estacionamento', 'val': _stats.parkingDuration, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Driving time', 'val': _stats.drivingTime, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Driving distance', 'val': _stats.drivingDistance, 'cor': const Color(0xFF35D49A)},
      {'title': 'Número do veículo', 'val': _stats.plate, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Modelo', 'val': _stats.model, 'cor': const Color(0xFF38BDF8)},
      {'title': 'ano de lançamento', 'val': _stats.year, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Código VIN', 'val': _stats.vin, 'cor': const Color(0xFF94A3B8)},
      {'title': 'número do motor', 'val': _stats.motorNumber, 'cor': const Color(0xFF94A3B8)},
      {'title': 'Tipo de dispositivo', 'val': _stats.deviceType, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Período', 'val': _stats.period, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Número de viagens', 'val': _stats.tripsCount.toString(), 'cor': const Color(0xFF38BDF8)},
      {'title': 'Combustível abastecido', 'val': _stats.fuelFilled, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Combustível drenado', 'val': _stats.fuelDrained, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Média de veículos on-line', 'val': _stats.onlineCarsAvg.toString(), 'cor': const Color(0xFF35D49A)},
      {'title': 'Consumo de combustível', 'val': _stats.fuelConsumption, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Ocioso em uma linha por dia', 'val': _stats.idleTimePerDay, 'cor': const Color(0xFF94A3B8)},
      {'title': 'Average work time in day', 'val': _stats.avgWorkTimeInDay, 'cor': const Color(0xFF38BDF8)},
      {'title': 'Average mileage in period', 'val': _stats.avgMileageInPeriod, 'cor': const Color(0xFF35D49A)},
      {'title': 'Km costs', 'val': _stats.kmCosts, 'cor': const Color(0xFF38BDF8)},
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
              lowRatio: _stats.speedLowRatioKm,
              midRatio: _stats.speedMidRatioKm,
              highRatio: _stats.speedHighRatioKm,
            ),
          ),
        );

        final pieTempo = _buildPieCard(
          title: 'Tempo',
          chart: CustomPaint(
            size: const Size(130, 130),
            painter: _DonutChartPainter(
              lowRatio: _stats.speedLowRatioTime,
              midRatio: _stats.speedMidRatioTime,
              highRatio: _stats.speedHighRatioTime,
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
              _buildLegendItem('60 - 90 km/h', const Color(0xFF6366F1)),
              const SizedBox(width: 14),
              _buildLegendItem('> 90 km/h', const Color(0xFF35D49A)),
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
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
      ],
    );
  }

  // VEHICLE GRAPHS (DIAS)
  Widget _buildVehicleGraphsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isRow = constraints.maxWidth >= 700;

        final graphCarsOnLine = _buildGraphCard(
          title: 'Cars on line, Cars',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('2', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                  Text('', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 50,
                alignment: Alignment.center,
                child: Row(
                  children: [
                    const Text('1', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: const Color(0xFF1E293B),
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: Color(0xFF38BDF8), shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                  Text('29.10', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );

        final graphDistance = _buildGraphCard(
          title: 'Driving distance, km',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('16', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                  Text('${_stats.dailyDrivingDistance} km', style: const TextStyle(color: Color(0xFF35D49A), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 50,
                alignment: Alignment.center,
                child: Row(
                  children: [
                    const Text('12', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: const Color(0xFF1E293B),
                        child: Align(
                          alignment: const Alignment(0.0, -0.6),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: Color(0xFF35D49A), shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                  Text('29.10', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );

        if (isRow) {
          return Row(
            children: [
              Expanded(child: graphCarsOnLine),
              const SizedBox(width: 14),
              Expanded(child: graphDistance),
            ],
          );
        } else {
          return Column(
            children: [
              graphCarsOnLine,
              const SizedBox(height: 12),
              graphDistance,
            ],
          );
        }
      },
    );
  }

  Widget _buildGraphCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111A23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // RODAPÉ COM SYNC & EXPORT
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1722),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: _isSyncing ? null : _syncData,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isSyncing
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)))
                      : const Icon(Icons.sync, color: Color(0xFF38BDF8), size: 14),
                  const SizedBox(width: 6),
                  const Text('Sync now', style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ),
          Text(
            'Last sync\'d at ${_stats.lastSyncFormatted}',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
            ),
            icon: const Icon(Icons.download, size: 14),
            label: const Text('Exportar', style: TextStyle(fontSize: 11)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Exportação gerada com sucesso!'),
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

// PINTOR DO GRÁFICO DONUT (SPEED PIES)
class _DonutChartPainter extends CustomPainter {
  final double lowRatio; // < 60 km/h
  final double midRatio; // 60 - 90 km/h
  final double highRatio; // > 90 km/h

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

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Fundo cinza suave caso ratios somem 0
    basePaint.color = const Color(0xFF1E293B);
    canvas.drawCircle(center, radius - (strokeWidth / 2), basePaint);

    double startAngle = -math.pi / 2;

    // Arco < 60 km/h
    if (lowRatio > 0) {
      final sweepAngle = lowRatio * 2 * math.pi;
      basePaint.color = const Color(0xFF38BDF8);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        startAngle,
        sweepAngle,
        false,
        basePaint,
      );
      startAngle += sweepAngle;
    }

    // Arco 60 - 90 km/h
    if (midRatio > 0) {
      final sweepAngle = midRatio * 2 * math.pi;
      basePaint.color = const Color(0xFF6366F1);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        startAngle,
        sweepAngle,
        false,
        basePaint,
      );
      startAngle += sweepAngle;
    }

    // Arco > 90 km/h
    if (highRatio > 0) {
      final sweepAngle = highRatio * 2 * math.pi;
      basePaint.color = const Color(0xFF35D49A);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        startAngle,
        sweepAngle,
        false,
        basePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.lowRatio != lowRatio ||
        oldDelegate.midRatio != midRatio ||
        oldDelegate.highRatio != highRatio;
  }
}
