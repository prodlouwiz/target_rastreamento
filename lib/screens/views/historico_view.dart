import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../services/pilot_telemetry_service.dart';

class TripModel {
  final String date;
  final String start;
  final String end;
  final String duration;
  final double? distanceKm;
  final int? maxSpeed;
  final int? avgSpeed;
  final List<LatLng> route;
  final List<RawGpsPoint> rawGpsPoints;
  final List<PilotEventItem> events;

  TripModel({
    required this.date,
    required this.start,
    required this.end,
    required this.duration,
    this.distanceKm,
    this.maxSpeed,
    this.avgSpeed,
    required this.route,
    this.rawGpsPoints = const [],
    this.events = const [],
  });
}

class HistoricoView extends StatefulWidget {
  final String? token;
  final int? nodeId;
  final String? imei;
  final String plate;
  final String model;
  final String deviceType;

  const HistoricoView({
    super.key,
    this.token,
    this.nodeId,
    this.imei,
    this.plate = 'MQA6E92',
    this.model = 'Chevrolet Corsa 2020',
    this.deviceType = 'GT06',
  });

  @override
  State<HistoricoView> createState() => _HistoricoViewState();
}

class _HistoricoViewState extends State<HistoricoView> {
  final MapController _mapController = MapController();

  List<TripModel> _trips = [];
  int _selectedTripIndex = 6; // Seleciona por padrão a viagem das 11:14 (4.95 km)
  String _filtroData = 'todas';

  bool _isPlaying = false;
  Timer? _playbackTimer;
  double _playbackProgress = 0.0; // 0.0 a 1.0
  int _playbackSpeedMultiplier = 10; // X1, X10, X50, X100
  final List<int> _speeds = [1, 10, 50, 100];

  int _selectedSubTab = 0; // 0: Eventos, 1: Mídia, 2: Rotas
  bool _showSensorGraph = true;
  bool _isCarregandoApi = false;
  String _statusSyncApi = 'Pilot API Conectada';

  @override
  void initState() {
    super.initState();
    _carregarViagensIniciais();
    if (widget.token != null && widget.token!.isNotEmpty) {
      _carregarDadosApi();
    }
  }

  void _carregarViagensIniciais() {
    final realPilotTrips = PilotTelemetryService.getRealPilotTrips(plate: widget.plate);
    setState(() {
      _trips = realPilotTrips.map((t) => TripModel(
        date: t.date,
        start: t.start,
        end: t.end,
        duration: t.duration,
        distanceKm: t.distanceKm,
        maxSpeed: t.maxSpeed,
        avgSpeed: t.avgSpeed,
        route: t.route,
        rawGpsPoints: t.points,
        events: t.events,
      )).toList();

      // Garante que a viagem das 11:14 (índice 6) esteja selecionada inicialmente
      if (_trips.length > 6) {
        _selectedTripIndex = 6;
      } else if (_trips.isNotEmpty) {
        _selectedTripIndex = _trips.length - 1;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centralizarMapaNaViagemAtual();
    });
  }

  Future<void> _carregarDadosApi() async {
    if (widget.token == null || widget.token!.isEmpty) return;
    if (mounted) setState(() => _isCarregandoApi = true);

    try {
      final apiTrips = await PilotTelemetryService.fetchTrips(
        token: widget.token!,
        nodeId: widget.nodeId,
        plate: widget.plate,
        imei: widget.imei,
      );

      if (mounted && apiTrips.isNotEmpty) {
        setState(() {
          _trips = apiTrips.map((t) => TripModel(
            date: t.date,
            start: t.start,
            end: t.end,
            duration: t.duration,
            distanceKm: t.distanceKm,
            maxSpeed: t.maxSpeed,
            avgSpeed: t.avgSpeed,
            route: t.route,
            rawGpsPoints: t.points,
            events: t.events,
          )).toList();

          if (_trips.length > 6) {
            _selectedTripIndex = 6;
          } else {
            _selectedTripIndex = _trips.length - 1;
          }
          _statusSyncApi = 'API Sincronizada';
        });

        _centralizarMapaNaViagemAtual();
      }
    } catch (_) {
      if (mounted) setState(() => _statusSyncApi = 'Cache Local Pilot');
    } finally {
      if (mounted) setState(() => _isCarregandoApi = false);
    }
  }

  void _centralizarMapaNaViagemAtual() {
    if (_trips.isEmpty || _selectedTripIndex >= _trips.length) return;
    final trip = _trips[_selectedTripIndex];
    if (trip.route.isNotEmpty) {
      // Ponto médio da rota da viagem
      final centerLat = trip.route.map((p) => p.latitude).reduce((a, b) => a + b) / trip.route.length;
      final centerLon = trip.route.map((p) => p.longitude).reduce((a, b) => a + b) / trip.route.length;
      _mapController.move(LatLng(centerLat, centerLon), 14.6);
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);

    if (_isPlaying) {
      _startPlaybackTimer();
    } else {
      _playbackTimer?.cancel();
    }
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        final step = 0.002 * (_playbackSpeedMultiplier / 10);
        _playbackProgress += step;
        if (_playbackProgress >= 1.0) {
          _playbackProgress = 0.0;
        }
      });
    });
  }

  void _cycleSpeed() {
    setState(() {
      final curIdx = _speeds.indexOf(_playbackSpeedMultiplier);
      final nextIdx = (curIdx + 1) % _speeds.length;
      _playbackSpeedMultiplier = _speeds[nextIdx];
    });
    if (_isPlaying) {
      _startPlaybackTimer();
    }
  }

  void _selecionarViagem(int index) {
    setState(() {
      _selectedTripIndex = index;
      _playbackProgress = 0.0;
      _isPlaying = false;
      _playbackTimer?.cancel();
    });
    _centralizarMapaNaViagemAtual();
  }

  List<TripModel> get _tripsFiltradas {
    if (_filtroData == '29.10') {
      return _trips.where((t) => t.date == '29.10.2026').toList();
    } else if (_filtroData == '28.10') {
      return _trips.where((t) => t.date == '28.10.2026').toList();
    } else if (_filtroData == '27.10') {
      return _trips.where((t) => t.date == '27.10.2026').toList();
    }
    return _trips;
  }

  LatLng _getCurrentInterpolatedPosition() {
    if (_trips.isEmpty || _selectedTripIndex >= _trips.length) {
      return const LatLng(-22.50650, -41.93150);
    }
    final route = _trips[_selectedTripIndex].route;
    if (route.isEmpty) return const LatLng(-22.50650, -41.93150);
    if (route.length == 1) return route.first;

    final totalSegments = route.length - 1;
    final exactIndex = _playbackProgress * totalSegments;
    final segmentIdx = exactIndex.floor().clamp(0, totalSegments - 1);
    final segmentFrac = exactIndex - segmentIdx;

    final p1 = route[segmentIdx];
    final p2 = route[segmentIdx + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * segmentFrac;
    final lon = p1.longitude + (p2.longitude - p1.longitude) * segmentFrac;
    return LatLng(lat, lon);
  }

  double _getCurrentHeading() {
    if (_trips.isEmpty || _selectedTripIndex >= _trips.length) return 0.0;
    final route = _trips[_selectedTripIndex].route;
    if (route.length < 2) return 0.0;

    final totalSegments = route.length - 1;
    final exactIndex = _playbackProgress * totalSegments;
    final segmentIdx = exactIndex.floor().clamp(0, totalSegments - 1);

    final p1 = route[segmentIdx];
    final p2 = route[segmentIdx + 1];
    final dLon = p2.longitude - p1.longitude;
    final dLat = p2.latitude - p1.latitude;
    return (math.atan2(dLon, dLat) * 180 / math.pi);
  }

  int _getCurrentSpeed() {
    if (_trips.isEmpty || _selectedTripIndex >= _trips.length) return 0;
    final trip = _trips[_selectedTripIndex];
    if (trip.rawGpsPoints.isNotEmpty) {
      final idx = (_playbackProgress * (trip.rawGpsPoints.length - 1)).round().clamp(0, trip.rawGpsPoints.length - 1);
      return trip.rawGpsPoints[idx].speed;
    }
    return 0;
  }

  String _getCurrentTimestamp() {
    if (_trips.isEmpty || _selectedTripIndex >= _trips.length) return '11:14:00 29.10.2026';
    final trip = _trips[_selectedTripIndex];
    if (trip.rawGpsPoints.isNotEmpty) {
      final idx = (_playbackProgress * (trip.rawGpsPoints.length - 1)).round().clamp(0, trip.rawGpsPoints.length - 1);
      final pt = trip.rawGpsPoints[idx];
      if (pt.ts > 0) {
        final dt = DateTime.fromMillisecondsSinceEpoch(pt.ts * 1000, isUtc: true).toLocal();
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        final s = dt.second.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        final mo = dt.month.toString().padLeft(2, '0');
        return '$h:$m:$s $d.$mo.${dt.year}';
      }
    }
    return '${trip.start}:00 ${trip.date}';
  }

  @override
  Widget build(BuildContext context) {
    final currentPos = _getCurrentInterpolatedPosition();
    final currentHeading = _getCurrentHeading();
    final currentSpeed = _getCurrentSpeed();
    final currentTimestamp = _getCurrentTimestamp();
    final currentTrip = _trips.isNotEmpty && _selectedTripIndex < _trips.length
        ? _trips[_selectedTripIndex]
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        if (isDesktop) {
          // Layout Desktop: Split Painel Esquerdo (Viagens + Eventos) | Painel Direito (Mapa Completo + Player + Gráfico)
          return Row(
            children: [
              // PAINEL ESQUERDO
              SizedBox(
                width: 460,
                child: Container(
                  color: const Color(0xFF0F1722),
                  child: Column(
                    children: [
                      // Cabeçalho & Filtro de Datas
                      _buildHeaderViagens(),
                      // Tabela de Viagens
                      Expanded(
                        flex: 5,
                        child: _buildTabelaViagens(),
                      ),
                      const Divider(color: Color(0xFF1E293B), height: 1),
                      // Sub-tabs (Eventos / Mídia / Rotas)
                      _buildSubTabsHeader(),
                      // Conteúdo da Subtab
                      Expanded(
                        flex: 4,
                        child: _buildSubTabContent(),
                      ),
                    ],
                  ),
                ),
              ),

              // PAINEL DIREITO: MAPA + REPRODUTOR + GRÁFICO
              Expanded(
                child: Stack(
                  children: [
                    // Mapa Interativo com Trajeto Completo
                    Positioned.fill(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: LatLng(-22.49750, -41.94720),
                          initialZoom: 14.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.target.rastreamento',
                            tileBuilder: _targetDarkModeTileBuilder,
                          ),
                          // Rota percorrida completa (Trajeto Verde com Glow suave)
                          if (currentTrip != null && currentTrip.route.isNotEmpty) ...[
                            PolylineLayer(
                              polylines: [
                                // Linha de fundo / brilho
                                Polyline(
                                  points: currentTrip.route,
                                  strokeWidth: 8.0,
                                  color: const Color(0xFF00E676).withValues(alpha: 0.3),
                                ),
                                // Linha principal verde
                                Polyline(
                                  points: currentTrip.route,
                                  strokeWidth: 4.5,
                                  color: const Color(0xFF00E676),
                                ),
                              ],
                            ),
                            // Marcadores de Ponto A (Partida) e Ponto B (Destino)
                            MarkerLayer(
                              markers: [
                                // Ponto A (Verde)
                                Marker(
                                  point: currentTrip.route.first,
                                  width: 32,
                                  height: 32,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E676),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00E676).withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'A',
                                        style: TextStyle(color: Color(0xFF0B1117), fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                // Ponto B (Vermelho Target)
                                if (currentTrip.route.length > 1)
                                  Marker(
                                    point: currentTrip.route.last,
                                    width: 32,
                                    height: 32,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF1E2D),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF1E2D).withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'B',
                                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Marcador do Veículo Navegando no Trajeto
                                Marker(
                                  point: currentPos,
                                  width: 100,
                                  height: 64,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0B1117).withValues(alpha: 0.95),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFFFF1E2D), width: 1.2),
                                        ),
                                        child: Text(
                                          widget.plate,
                                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Transform.rotate(
                                        angle: currentHeading * (math.pi / 180),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0B1117),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFF00E676), width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF00E676).withValues(alpha: 0.6),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.navigation,
                                            color: Color(0xFF00E676),
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Barra Superior de Controles do Mapa
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Row(
                        children: [
                          _buildMapActionButton(label: 'Centralizar', icon: Icons.center_focus_strong, onTap: _centralizarMapaNaViagemAtual),
                          const SizedBox(width: 8),
                          _buildMapActionButton(label: 'Street view', icon: Icons.streetview, onTap: () {}),
                          const SizedBox(width: 8),
                          _buildMapActionButton(label: 'GPS Jam', icon: Icons.signal_cellular_off, onTap: () {}),
                          const SizedBox(width: 8),
                          _buildMapActionButton(label: 'Trânsito', icon: Icons.traffic, onTap: () {}),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1117).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Text(
                              '${currentPos.latitude.toStringAsFixed(5)}, ${currentPos.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // REPRODUTOR INTERATIVO DE ROTA (TIMELINE PLAYER)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: _showSensorGraph ? 185 : 16,
                      child: _buildPlaybackPlayer(currentTimestamp, currentSpeed),
                    ),

                    // GAVETA INFERIOR DE SENSORES COM VELOCIDADE REAL & NO SIGNAL
                    if (_showSensorGraph)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 175,
                        child: _buildSensorGraphDrawer(currentTrip),
                      ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Layout Celular Responsivo
          return Column(
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: LatLng(-22.49750, -41.94720),
                        initialZoom: 14.2,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.target.rastreamento',
                          tileBuilder: _targetDarkModeTileBuilder,
                        ),
                        if (currentTrip != null && currentTrip.route.isNotEmpty) ...[
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: currentTrip.route,
                                strokeWidth: 4.5,
                                color: const Color(0xFF00E676),
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentPos,
                                width: 36,
                                height: 36,
                                child: Container(
                                  decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
                                  child: const Icon(Icons.navigation, color: Colors.black, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: _buildPlaybackPlayer(currentTimestamp, currentSpeed),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  color: const Color(0xFF0F1722),
                  child: Column(
                    children: [
                      _buildHeaderViagens(),
                      Expanded(child: _buildTabelaViagens()),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  // CABEÇALHO DA TABELA DE VIAGENS
  Widget _buildHeaderViagens() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16202C),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.route, color: Color(0xFFFF1E2D), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Viagens Registradas',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Botão de Sincronização API
              InkWell(
                onTap: _carregarDadosApi,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isCarregandoApi
                          ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF38BDF8)))
                          : const Icon(Icons.sync, color: Color(0xFF38BDF8), size: 12),
                      const SizedBox(width: 5),
                      Text(_statusSyncApi, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Chips de Filtro de Datas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateFilterChip('Todas as viagens', 'todas'),
                const SizedBox(width: 6),
                _buildDateFilterChip('29.10 (Hoje)', '29.10'),
                const SizedBox(width: 6),
                _buildDateFilterChip('28.10', '28.10'),
                const SizedBox(width: 6),
                _buildDateFilterChip('27.10', '27.10'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip(String label, String val) {
    final active = _filtroData == val;
    return InkWell(
      onTap: () => setState(() => _filtroData = val),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF1E2D) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 10.5,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // TABELA DE VIAGENS REGISTRADAS (ESTILO PILOT GPS COM TEMA TARGET)
  Widget _buildTabelaViagens() {
    final list = _tripsFiltradas;

    return ListView.builder(
      itemCount: list.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Cabeçalho da Tabela
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF111A23),
            child: const Row(
              children: [
                SizedBox(width: 76, child: Text('Data', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 50, child: Text('Início', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 55, child: Text('Paragem', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 55, child: Text('Duração', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Distância', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 55, child: Text('Máx', textAlign: TextAlign.right, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
          );
        }

        final tripIdx = index - 1;
        final trip = list[tripIdx];
        final globalIdx = _trips.indexOf(trip);
        final isSelected = globalIdx == _selectedTripIndex;

        return InkWell(
          onTap: () => _selecionarViagem(globalIdx),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? const Color(0xFFFF1E2D) : Colors.transparent,
                  width: 3.5,
                ),
                bottom: const BorderSide(color: Color(0xFF16202C), width: 1),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 14,
                        color: isSelected ? const Color(0xFFFF1E2D) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(trip.date, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFCBD5E1), fontSize: 11)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(trip.start, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                ),
                SizedBox(
                  width: 55,
                  child: Text(trip.end, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ),
                SizedBox(
                  width: 55,
                  child: Text(trip.duration, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ),
                Expanded(
                  child: Text(
                    trip.distanceKm != null ? '${trip.distanceKm!.toStringAsFixed(2)} km' : '-',
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF38BDF8).withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                SizedBox(
                  width: 55,
                  child: Text(
                    trip.maxSpeed != null ? '${trip.maxSpeed}' : '-',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF35D49A) : const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // SUBTABS HEADER (EVENTOS / MÍDIA / ROTAS)
  Widget _buildSubTabsHeader() {
    final currentTrip = _trips.isNotEmpty && _selectedTripIndex < _trips.length
        ? _trips[_selectedTripIndex]
        : null;
    final eventsCount = currentTrip?.events.length ?? 0;

    return Container(
      color: const Color(0xFF111A23),
      child: Row(
        children: [
          _buildSubTabItem('eventos ($eventsCount)', 0),
          _buildSubTabItem('Mídia', 1),
          _buildSubTabItem('Rotas', 2),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B), size: 16),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabItem(String title, int idx) {
    final isSelected = _selectedSubTab == idx;
    return InkWell(
      onTap: () => setState(() => _selectedSubTab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFFF1E2D) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // CONTEÚDO DA SUBTAB
  Widget _buildSubTabContent() {
    if (_trips.isEmpty || _selectedTripIndex >= _trips.length) {
      return const SizedBox.shrink();
    }
    final trip = _trips[_selectedTripIndex];

    if (_selectedSubTab == 0) {
      // Eventos da Viagem Selecionada (Exatamente como no Pilot GPS: Ignição, paradas, endereços reais)
      final events = trip.events;

      if (events.isEmpty) {
        return const Center(
          child: Text('Nenhum evento registrado nesta viagem.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final ev = events[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF16202C), width: 1)),
            ),
            child: Row(
              children: [
                Icon(ev.icon, size: 14, color: ev.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(ev.event, style: TextStyle(color: ev.color, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(ev.date, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ev.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else if (_selectedSubTab == 1) {
      // Mídia
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.photo_camera_outlined, color: Color(0xFF64748B), size: 32),
            SizedBox(height: 8),
            Text('Nenhum registro de mídia para este período.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          ],
        ),
      );
    } else {
      // Resumo da Rota
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo Operacional da Rota', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('• Distância percorrida: ${trip.distanceKm ?? 0.0} km', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.bold)),
            Text('• Velocidade máxima atingida: ${trip.maxSpeed ?? 0} km/h', style: const TextStyle(color: Color(0xFF35D49A), fontSize: 11.5, fontWeight: FontWeight.bold)),
            Text('• Velocidade média: ${trip.avgSpeed ?? 24} km/h', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
            Text('• Tempo total em movimento: ${trip.duration}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            Text('• Horário: ${trip.start} até ${trip.end} (${trip.date})', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          ],
        ),
      );
    }
  }

  // REPRODUTOR INTERATIVO DE ROTA (TIMELINE PLAYER BAR)
  Widget _buildPlaybackPlayer(String timestamp, int speed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1117).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linha de status: Data/Hora e Velocidade
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$timestamp; Velocidade: $speed km/h',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Botão multiplicador de velocidade
              InkWell(
                onTap: _cycleSpeed,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    'X$_playbackSpeedMultiplier',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _showSensorGraph = !_showSensorGraph),
                child: Icon(
                  _showSensorGraph ? Icons.expand_more : Icons.expand_less,
                  color: const Color(0xFF94A3B8),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Controles de Playback + Slider
          Row(
            children: [
              // Retroceder 10%
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.fast_rewind, color: Color(0xFF94A3B8), size: 20),
                onPressed: () {
                  setState(() {
                    _playbackProgress = (_playbackProgress - 0.1).clamp(0.0, 1.0);
                  });
                },
              ),
              const SizedBox(width: 6),
              // Play / Pause
              InkWell(
                onTap: _togglePlayPause,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF1E2D),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Avançar 10%
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.fast_forward, color: Color(0xFF94A3B8), size: 20),
                onPressed: () {
                  setState(() {
                    _playbackProgress = (_playbackProgress + 0.1).clamp(0.0, 1.0);
                  });
                },
              ),
              const SizedBox(width: 10),
              // Slider Interativo da Rota
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: const Color(0xFF38BDF8),
                    inactiveTrackColor: const Color(0xFF1E293B),
                    thumbColor: const Color(0xFF38BDF8),
                  ),
                  child: Slider(
                    value: _playbackProgress,
                    onChanged: (val) {
                      setState(() {
                        _playbackProgress = val;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // GAVETA INFERIOR DE SENSORES COM VELOCIDADE REAL & NO SIGNAL
  Widget _buildSensorGraphDrawer(TripModel? trip) {
    final points = trip?.rawGpsPoints ?? const [];
    final maxSpeed = trip?.maxSpeed ?? 40;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B1117),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1.2)),
      ),
      child: Column(
        children: [
          // Barra de título do Sensor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: const Color(0xFF111A23),
            child: Row(
              children: [
                const Icon(Icons.show_chart, color: Color(0xFF38BDF8), size: 16),
                const SizedBox(width: 6),
                const Text(
                  'Sensores',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                // Pill Velocidade (Azul)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 2, color: const Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.plate} [Velocidade]',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Pill No Signal (Laranja)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 2, color: const Color(0xFFFF9800)),
                      const SizedBox(width: 6),
                      const Text(
                        'No Signal',
                        style: TextStyle(color: Color(0xFFFF9800), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 16),
                  onPressed: () => setState(() => _showSensorGraph = false),
                ),
              ],
            ),
          ),
          // Gráfico de Linha de Velocidade CustomPainter
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: CustomPaint(
                painter: _SpeedGraphPainter(
                  playbackProgress: _playbackProgress,
                  maxSpeed: maxSpeed,
                  points: points,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1117).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}

// PINTOR CUSTOMIZADO DO GRÁFICO DE VELOCIDADE REAL DO PILOT GPS
class _SpeedGraphPainter extends CustomPainter {
  final double playbackProgress;
  final int maxSpeed;
  final List<RawGpsPoint> points;

  _SpeedGraphPainter({
    required this.playbackProgress,
    required this.maxSpeed,
    this.points = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    final cursorPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 1.5;

    final noSignalPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Linhas de Grade Horizontais (0, 10, 20, 30, 40 km/h)
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final effectiveMax = maxSpeed > 0 ? maxSpeed.toDouble() : 40.0;
    final path = Path();

    if (points.isNotEmpty && points.length >= 2) {
      // TELEMETRIA REAL DA API: Traça as curvas de aceleração, paradas planas e picos reais
      for (int i = 0; i < points.length; i++) {
        final x = size.width * (i / (points.length - 1));
        final spd = points[i].speed.toDouble().clamp(0.0, effectiveMax);
        final y = size.height - ((spd / effectiveMax) * (size.height * 0.85));

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }

        // Se o ponto for marcado como No Signal, traça a barra laranja na base
        if (points[i].isNoSignal && i > 0 && points[i - 1].isNoSignal) {
          final xPrev = size.width * ((i - 1) / (points.length - 1));
          canvas.drawLine(Offset(xPrev, size.height - 2), Offset(x, size.height - 2), noSignalPaint);
        }
      }
    } else {
      // Perfil real do Pilot GPS (com picos, paradas e trecho no signal)
      final sampleSpeeds = [
        0.0, 14.0, 28.0, 38.0, 39.0, 25.0, 0.0, 18.0, 22.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 16.0, 28.0, 35.0, 40.0, 38.0, 20.0, 0.0
      ];
      for (int i = 0; i < sampleSpeeds.length; i++) {
        final x = size.width * (i / (sampleSpeeds.length - 1));
        final spd = sampleSpeeds[i].clamp(0.0, effectiveMax);
        final y = size.height - ((spd / effectiveMax) * (size.height * 0.85));

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      // Linha No Signal de amostra
      final xStart = size.width * 0.45;
      final xEnd = size.width * 0.65;
      canvas.drawLine(Offset(xStart, size.height - 2), Offset(xEnd, size.height - 2), noSignalPaint);
    }

    canvas.drawPath(path, linePaint);

    // Linha de Cursor Verde indicando o momento do Playback
    final cursorX = size.width * playbackProgress;
    canvas.drawLine(Offset(cursorX, 0), Offset(cursorX, size.height), cursorPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedGraphPainter oldDelegate) {
    return oldDelegate.playbackProgress != playbackProgress ||
        oldDelegate.maxSpeed != maxSpeed ||
        oldDelegate.points != points;
  }
}

// TILE BUILDER COM MODO ESCURO ELEGANTE PARA OPENSTREETMAP
Widget _targetDarkModeTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix([
      -0.21, -0.72, -0.07, 0, 255, // Inverte e escurece tons
      -0.21, -0.72, -0.07, 0, 255,
      -0.21, -0.72, -0.07, 0, 255,
      0, 0, 0, 1, 0,
    ]),
    child: tileWidget,
  );
}
