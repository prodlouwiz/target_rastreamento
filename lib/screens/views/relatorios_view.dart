import 'dart:math' as math;
import 'package:flutter/material.dart';

class RelatoriosView extends StatefulWidget {
  final String plate;
  final String model;
  final String clientName;

  const RelatoriosView({
    super.key,
    this.plate = 'MQA6E92',
    this.model = 'Chevrolet Corsa 2020',
    this.clientName = 'Vidal Rastreamento',
  });

  @override
  State<RelatoriosView> createState() => _RelatoriosViewState();
}

class _RelatoriosViewState extends State<RelatoriosView> {
  String _divisao = 'por dias';
  DateTime _startDate = DateTime(2026, 10, 22, 0, 0);
  DateTime _endDate = DateTime(2026, 10, 30, 0, 0);
  String _agrupamento = 'por data';
  String _tipoRelatorio = 'Relatório sobre velocidade';
  bool _isGenerating = false;
  bool _reportGenerated = true;
  int _activeReportTab = 0; // 0: Gráficos, 1: Tabela Analítica

  final List<String> _tiposRelatorios = [
    'Relatório sobre velocidade',
    'Viagens e paradas',
    'Consumo de combustível',
    'Eventos e alarmes',
    'Quilometragem diária',
  ];

  Future<void> _buildReport() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _isGenerating = false;
        _reportGenerated = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_tipoRelatorio gerado com sucesso!'),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return Scaffold(
          backgroundColor: const Color(0xFF0B1117),
          body: isDesktop
              ? Row(
                  children: [
                    // Coluna de Configuração / Filtro
                    SizedBox(
                      width: 360,
                      child: _buildFilterSidebar(),
                    ),
                    const VerticalDivider(color: Color(0xFF1E293B), width: 1),
                    // Painel Principal do Relatório
                    Expanded(
                      child: _buildReportMainContent(),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFilterSidebar(),
                      const Divider(color: Color(0xFF1E293B), height: 1),
                      _buildReportMainContent(),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // SIDEBAR DE CONFIGURAÇÃO / FILTRO
  Widget _buildFilterSidebar() {
    return Container(
      color: const Color(0xFF0F1722),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Color(0xFFFF1E2D), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Gerador de Relatórios',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dividir
          _buildLabel('Dividir'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _divisao,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: ['por dias', 'por semanas', 'por meses'].map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _divisao = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Período (A partir da data - Até à data)
          _buildLabel('A partir da data'),
          _buildDateField(
            label: '${_startDate.day.toString().padLeft(2, '0')}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.year} 00:00',
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2025), lastDate: DateTime(2030));
              if (d != null) setState(() => _startDate = d);
            },
          ),
          const SizedBox(height: 10),
          _buildLabel('Até à data'),
          _buildDateField(
            label: '${_endDate.day.toString().padLeft(2, '0')}.${_endDate.month.toString().padLeft(2, '0')}.${_endDate.year} 00:00',
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2025), lastDate: DateTime(2030));
              if (d != null) setState(() => _endDate = d);
            },
          ),
          const SizedBox(height: 12),

          // Agrupamento
          _buildLabel('Agrupamento'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _agrupamento,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: ['por data', 'por veículo', 'por viagem'].map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _agrupamento = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tipo de Relatório
          _buildLabel('Tipo de relatório'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _tipoRelatorio,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: _tiposRelatorios.map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _tipoRelatorio = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botão Construir o Relatório
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: _isGenerating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow, size: 18),
              label: const Text(
                'Construir o relatório...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: _isGenerating ? null : _buildReport,
            ),
          ),
          const SizedBox(height: 16),

          // Lista de Objetos para o relatório
          const Text('Veículos Selecionados:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF111A23),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_box, color: Color(0xFFFF1E2D), size: 16),
                const SizedBox(width: 8),
                const Icon(Icons.directions_car, color: Color(0xFF38BDF8), size: 16),
                const SizedBox(width: 8),
                Text(widget.plate, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(widget.model, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
    );
  }

  Widget _buildDateField({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            const Icon(Icons.calendar_month, color: Color(0xFF38BDF8), size: 16),
          ],
        ),
      ),
    );
  }

  // PAINEL PRINCIPAL DO RELATÓRIO
  Widget _buildReportMainContent() {
    if (!_reportGenerated) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assessment_outlined, color: Color(0xFF334155), size: 48),
            const SizedBox(height: 12),
            const Text('Selecione os parâmetros e clique em "Construir o relatório"', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho do Relatório Gerado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF111A23),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$_tipoRelatorio de 22.10.2026 00:00 para 30.10.2026 00:00',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              // Abas Gráfico / Tabela
              _buildTabSelector('Gráfico de Velocidade', 0),
              const SizedBox(width: 6),
              _buildTabSelector('Tabela Analítica', 1),
            ],
          ),
        ),

        // Conteúdo: Gráficos de 24h diários ou Tabela
        Expanded(
          child: _activeReportTab == 0 ? _buildDailySpeedCharts() : _buildAnalyticalTable(),
        ),

        // Barra Inferior de Exportação
        _buildExportActions(),
      ],
    );
  }

  Widget _buildTabSelector(String label, int index) {
    final isSelected = _activeReportTab == index;
    return InkWell(
      onTap: () => setState(() => _activeReportTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // GRÁFICOS DIÁRIOS DE VELOCIDADE (24H POR DIA)
  Widget _buildDailySpeedCharts() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumo Executivo
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111A23),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Distância Total', '35,18 km', const Color(0xFF38BDF8)),
              _buildSummaryItem('Velocidade Máx.', '61 km/h', const Color(0xFF35D49A)),
              _buildSummaryItem('Velocidade Média', '28,4 km/h', Colors.white),
              _buildSummaryItem('Infrações (> 90 km/h)', '0', const Color(0xFF35D49A)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dia 1: 22.10.2026 (Sem movimento)
        _buildDailySpeedSection(
          dateLabel: 'Data: Thursday, 22.10.2026 00:00 - Friday, 23.10.2026 00:00',
          maxDaySpeed: 0,
        ),
        const SizedBox(height: 16),

        // Dia 2: 28.10.2026 (Pico de 61 km/h)
        _buildDailySpeedSection(
          dateLabel: 'Data: Wednesday, 28.10.2026 00:00 - Thursday, 29.10.2026 00:00',
          maxDaySpeed: 61,
        ),
        const SizedBox(height: 16),

        // Dia 3: 29.10.2026 (Pico de 47 km/h)
        _buildDailySpeedSection(
          dateLabel: 'Data: Thursday, 29.10.2026 00:00 - Friday, 30.10.2026 00:00',
          maxDaySpeed: 47,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color cor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: cor, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDailySpeedSection({required String dateLabel, required int maxDaySpeed}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111A23),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da Data
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF16202C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateLabel, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.bold)),
                Text('Objeto: ${widget.plate}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
              ],
            ),
          ),
          // Gráfico 24 Horas
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 110,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _DaySpeedPainter(maxDaySpeed: maxDaySpeed),
                  ),
                ),
                const SizedBox(height: 8),
                // Eixo X de Horas
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('02:00', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                    Text('04:00', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                    Text('06:00', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                    Text('08:00', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                    Text('10:00', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                    Text('12:00', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                    Text('14:00', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                    Text('16:00', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                    Text('18:00', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                    Text('20:00', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TABELA ANALÍTICA DETALHADA
  Widget _buildAnalyticalTable() {
    final rows = [
      {'data': '28.10.2026', 'inicio': '08:13', 'fim': '11:00', 'dur': '2:47', 'km': '14,77 km', 'med': '32 km/h', 'max': '61 km/h'},
      {'data': '28.10.2026', 'inicio': '13:03', 'fim': '13:41', 'dur': '00:38', 'km': '5,37 km', 'med': '24 km/h', 'max': '37 km/h'},
      {'data': '29.10.2026', 'inicio': '08:47', 'fim': '09:13', 'dur': '00:26', 'km': '2,76 km', 'med': '28 km/h', 'max': '47 km/h'},
      {'data': '29.10.2026', 'inicio': '11:14', 'fim': '12:02', 'dur': '00:47', 'km': '4,95 km', 'med': '26 km/h', 'max': '40 km/h'},
      {'data': '29.10.2026', 'inicio': '18:49', 'fim': '19:15', 'dur': '00:26', 'km': '4,09 km', 'med': '27 km/h', 'max': '39 km/h'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111A23),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF16202C)),
            dataRowColor: WidgetStateProperty.all(const Color(0xFF111A23)),
            columns: const [
              DataColumn(label: Text('Data', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Início', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Fim', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Duração', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Distância', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Vel. Média', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11))),
              DataColumn(label: Text('Vel. Máx.', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11))),
            ],
            rows: rows.map((r) {
              return DataRow(
                cells: [
                  DataCell(Text(r['data']!, style: const TextStyle(color: Colors.white, fontSize: 11))),
                  DataCell(Text(r['inicio']!, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11))),
                  DataCell(Text(r['fim']!, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11))),
                  DataCell(Text(r['dur']!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11))),
                  DataCell(Text(r['km']!, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold))),
                  DataCell(Text(r['med']!, style: const TextStyle(color: Colors.white, fontSize: 11))),
                  DataCell(Text(r['max']!, style: const TextStyle(color: Color(0xFF35D49A), fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // AÇÕES DE EXPORTAÇÃO
  Widget _buildExportActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF111A23),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Exportar PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exportando relatório em PDF...'), backgroundColor: Color(0xFF1E293B)),
              );
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.table_view, size: 16),
            label: const Text('Exportar Excel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exportando relatório em planilha XLSX...'), backgroundColor: Color(0xFF1E293B)),
              );
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF334155)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Imprimir', style: TextStyle(fontSize: 11)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enviando para fila de impressão...'), backgroundColor: Color(0xFF1E293B)),
              );
            },
          ),
        ],
      ),
    );
  }
}

// PINTOR DA CURVA DE VELOCIDADE DE 24 HORAS
class _DaySpeedPainter extends CustomPainter {
  final int maxDaySpeed;

  _DaySpeedPainter({required this.maxDaySpeed});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 4 Linhas de Grade Horizontais (0, 30, 60, 90 km/h)
    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (maxDaySpeed == 0) {
      // Linha plana em 0 km/h
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), linePaint);
      return;
    }

    // Traça curva com acelerações nos horários de viagem
    final path = Path();
    final points = 100;
    for (int i = 0; i <= points; i++) {
      final frac = i / points;
      final x = size.width * frac;

      // Horários com viagens: entre 08h-11h (frac 0.33 a 0.45) e 18h-19h (frac 0.75 a 0.80)
      double spd = 0.0;
      if (frac >= 0.32 && frac <= 0.46) {
        final t = (frac - 0.32) / (0.46 - 0.32);
        spd = math.sin(t * math.pi) * maxDaySpeed;
      } else if (frac >= 0.74 && frac <= 0.82) {
        final t = (frac - 0.74) / (0.82 - 0.74);
        spd = math.sin(t * math.pi) * (maxDaySpeed * 0.8);
      }

      final y = size.height - ((spd / 80.0) * size.height).clamp(0.0, size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _DaySpeedPainter oldDelegate) {
    return oldDelegate.maxDaySpeed != maxDaySpeed;
  }
}

