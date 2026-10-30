import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

class TripModel {
  final String date;
  final String start;
  final String end;
  final String duration;
  final double? distanceKm;
  final int? maxSpeed;
  final List<LatLng> route;

  TripModel({
    required this.date,
    required this.start,
    required this.end,
    required this.duration,
    this.distanceKm,
    this.maxSpeed,
    required this.route,
  });
}

class EventItem {
  final String vehicle;
  final String date;
  final String event;
  final String address;
  final IconData icon;
  final Color color;

  EventItem({
    required this.vehicle,
    required this.date,
    required this.event,
    required this.address,
    required this.icon,
    required this.color,
  });
}

class HistoricoView extends StatefulWidget {
  final String plate;
  final String model;
  final String deviceType;

  const HistoricoView({
    super.key,
    this.plate = 'MQA6E92',
    this.model = 'Chevrolet Corsa 2020',
    this.deviceType = 'GT06',
  });

  @override
  State<HistoricoView> createState() => _HistoricoViewState();
}

class _HistoricoViewState extends State<HistoricoView> {
  final MapController _mapController = MapController();

  late final List<TripModel> _trips;
  int _selectedTripIndex = 9; // Latest trip selected by default (29.10 18:49)

  bool _isPlaying = false;
  Timer? _playbackTimer;
  double _playbackProgress = 0.65; // 0.0 to 1.0
  int _playbackSpeedMultiplier = 100; // x1, x10, x50, x100
  final List<int> _speeds = [1, 10, 50, 100];

  int _selectedSubTab = 0; // 0: Eventos, 1: Mídia, 2: Rotas
  bool _showSensorGraph = true;

  late final List<EventItem> _events;

  // Route in Rio das Ostras
  static final List<LatLng> _rioDasOstrasRoute = [
    const LatLng(-22.51850, -41.92180), // Orla Costazul / Praça da Baleia
    const LatLng(-22.51520, -41.92460), // Av. Roberto Silveira
    const LatLng(-22.51180, -41.92790), // Reduto da Paz
    const LatLng(-22.50850, -41.93120), // Av. dos Bandeirantes
    const LatLng(-22.50563, -41.93202), // Av. Brasília / Costazul
    const LatLng(-22.50280, -41.93750), // Enseada das Gaivotas
    const LatLng(-22.49980, -41.94310), // Amaral Peixoto (RJ-106)
    const LatLng(-22.49720, -41.94860), // Jardim Mariléa
    const LatLng(-22.49390, -41.95450), // Village Rio das Ostras
    const LatLng(-22.49050, -41.96100), // Trevo Rodovia / Macaé
  ];

  @override
  void initState() {
    super.initState();

    _trips = [
      TripModel(
        date: '27.10.2026',
        start: '18:25',
        end: '08:13',
        duration: '13:47',
        distanceKm: null,
        maxSpeed: null,
        route: _rioDasOstrasRoute.sublist(0, 3),
      ),
      TripModel(
        date: '28.10.2026',
        start: '08:13',
        end: '11:00',
        duration: '2:47',
        distanceKm: 14.77,
        maxSpeed: 61,
        route: _rioDasOstrasRoute,
      ),
      TripModel(
        date: '28.10.2026',
        start: '11:00',
        end: '13:03',
        duration: '2:03',
        distanceKm: null,
        maxSpeed: null,
        route: _rioDasOstrasRoute.sublist(2, 5),
      ),
      TripModel(
        date: '28.10.2026',
        start: '13:03',
        end: '13:41',
        duration: '00:38',
        distanceKm: 5.37,
        maxSpeed: 37,
        route: _rioDasOstrasRoute.sublist(1, 6),
      ),
      TripModel(
        date: '28.10.2026',
        start: '13:41',
        end: '08:47',
        duration: '19:05',
        distanceKm: null,
        maxSpeed: null,
        route: _rioDasOstrasRoute.sublist(4, 7),
      ),
      TripModel(
        date: '29.10.2026',
        start: '08:47',
        end: '09:13',
        duration: '00:26',
        distanceKm: 2.76,
        maxSpeed: 47,
        route: _rioDasOstrasRoute.sublist(3, 8),
      ),
      TripModel(
        date: '29.10.2026',
        start: '09:13',
        end: '11:14',
        duration: '2:01',
        distanceKm: null,
        maxSpeed: null,
        route: _rioDasOstrasRoute.sublist(2, 6),
      ),
      TripModel(
        date: '29.10.2026',
        start: '11:14',
        end: '12:02',
        duration: '00:47',
        distanceKm: 4.95,
        maxSpeed: 40,
        route: _rioDasOstrasRoute.sublist(0, 7),
      ),
      TripModel(
        date: '29.10.2026',
        start: '12:02',
        end: '18:49',
        duration: '6:46',
        distanceKm: null,
        maxSpeed: null,
        route: _rioDasOstrasRoute.sublist(3, 5),
      ),
      TripModel(
        date: '29.10.2026',
        start: '18:49',
        end: '19:15',
        duration: '00:26',
        distanceKm: 4.09,
        maxSpeed: 39,
        route: _rioDasOstrasRoute,
      ),
    ];

    _events = [
      EventItem(
        vehicle: widget.plate,
        date: '18:50 29.10.2026',
        event: 'Power: Connected',
        address: '28895-535, Av. dos Bandeirantes, Rio das Ostras - RJ',
        icon: Icons.power,
        color: const Color(0xFF35D49A),
      ),
      EventItem(
        vehicle: widget.plate,
        date: '18:49 29.10.2026',
        event: 'Ignição: Ligada (ACC ON)',
        address: 'Av. Governador Roberto Silveira, Costazul, Rio das Ostras',
        icon: Icons.key,
        color: const Color(0xFF38BDF8),
      ),
      EventItem(
        vehicle: widget.plate,
        date: '12:02 29.10.2026',
        event: 'Ignição: Desligada (ACC OFF)',
        address: 'Rua Niterói, Jardim Mariléa, Rio das Ostras - RJ',
        icon: Icons.key_off,
        color: const Color(0xFF94A3B8),
      ),
      EventItem(
        vehicle: widget.plate,
        date: '11:14 29.10.2026',
        event: 'Ignição: Ligada (ACC ON)',
        address: 'Reduto da Paz, Rio das Ostras - RJ',
        icon: Icons.key,
        color: const Color(0xFF38BDF8),
      ),
      EventItem(
        vehicle: widget.plate,
        date: '08:47 29.10.2026',
        event: 'Ignição: Ligada (ACC ON)',
        address: 'Av. Amaral Peixoto, Centro, Rio das Ostras - RJ',
        icon: Icons.key,
        color: const Color(0xFF38BDF8),
      ),
    ];
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

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

  LatLng _getCurrentInterpolatedPosition() {
    final route = _trips[_selectedTripIndex].route;
    if (route.isEmpty) return const LatLng(-22.50563, -41.93202);
    if (route.length == 1) return route.first;

    final totalSegments = route.length - 1;
    final progressScaled = _playbackProgress * totalSegments;
    final segmentIdx = progressScaled.floor().clamp(0, totalSegments - 1);
    final segmentFraction = (progressScaled - segmentIdx).clamp(0.0, 1.0);

    final p1 = route[segmentIdx];
    final p2 = route[segmentIdx + 1];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * segmentFraction;
    final lon = p1.longitude + (p2.longitude - p1.longitude) * segmentFraction;
    return LatLng(lat, lon);
  }

  double _getCurrentHeading() {
    final route = _trips[_selectedTripIndex].route;
    if (route.length < 2) return 0.0;
    final totalSegments = route.length - 1;
    final segmentIdx = (_playbackProgress * totalSegments).floor().clamp(0, totalSegments - 1);
    final p1 = route[segmentIdx];
    final p2 = route[segmentIdx + 1];
    final dLon = p2.longitude - p1.longitude;
    final dLat = p2.latitude - p1.latitude;
    return (math.atan2(dLon, dLat) * 180 / math.pi);
  }

  int _getCurrentSpeed() {
    final trip = _trips[_selectedTripIndex];
    final maxSpd = trip.maxSpeed ?? 40;
    final factor = math.sin(_playbackProgress * math.pi);
    return (factor * maxSpd).round().clamp(0, maxSpd);
  }

  String _getCurrentTimestamp() {
    final startMin = 49;
    final currentMin = (startMin + (_playbackProgress * 26)).round();
    final hour = 18 + (currentMin ~/ 60);
    final min = currentMin % 60;
    final sec = ((_playbackProgress * 1560) % 60).round();
    final sHour = hour.toString().padLeft(2, '0');
    final sMin = min.toString().padLeft(2, '0');
    final sSec = sec.toString().padLeft(2, '0');
    return '$sHour:$sMin:$sSec 29.10.2026';
  }

  @override
  Widget build(BuildContext context) {
    final currentPos = _getCurrentInterpolatedPosition();
    final currentHeading = _getCurrentHeading();
    final currentSpeed = _getCurrentSpeed();
    final currentTimestamp = _getCurrentTimestamp();
    final currentTrip = _trips[_selectedTripIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        if (isDesktop) {
          // Layout Split: Painel Esquerdo (Viagens + Eventos) | Painel Direito (Mapa + Player + Gráfico)
          return Row(
            children: [
              // PAINEL ESQUERDO
              SizedBox(
                width: 440,
                child: Container(
                  color: const Color(0xFF0F1722),
                  child: Column(
                    children: [
                      // Cabeçalho da Tabela
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
                    // Mapa Interativo
                    Positioned.fill(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: LatLng(-22.50563, -41.93202),
                          initialZoom: 14.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.target.rastreamento',
                            tileBuilder: darkModeTileBuilder,
                          ),
                          // Rota percorrida (linha verde destacada)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: currentTrip.route,
                                strokeWidth: 5.0,
                                color: const Color(0xFF00E676),
                              ),
                              Polyline(
                                points: currentTrip.route,
                                strokeWidth: 8.0,
                                color: const Color(0xFF00E676).withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                          // Marcador do Início (Verde) e Fim (Vermelho)
                          MarkerLayer(
                            markers: [
                              if (currentTrip.route.isNotEmpty)
                                Marker(
                                  point: currentTrip.route.first,
                                  width: 28,
                                  height: 28,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00C853),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
                                    ),
                                    child: const Center(
                                      child: Text('A', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              if (currentTrip.route.length > 1)
                                Marker(
                                  point: currentTrip.route.last,
                                  width: 28,
                                  height: 28,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF1E2D),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
                                    ),
                                    child: const Center(
                                      child: Text('B', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              // Marcador do Carro em Movimento
                              Marker(
                                point: currentPos,
                                width: 90,
                                height: 60,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFFF1E2D), width: 1.2),
                                      ),
                                      child: Text(
                                        widget.plate,
                                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
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
                      ),
                    ),

                    // Barra Superior de Controles do Mapa
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Row(
                        children: [
                          _buildMapActionButton(label: 'Street view', icon: Icons.streetview),
                          const SizedBox(width: 8),
                          _buildMapActionButton(label: 'GPS Jam', icon: Icons.signal_cellular_off),
                          const SizedBox(width: 8),
                          _buildMapActionButton(label: 'Trânsito', icon: Icons.traffic),
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
                      bottom: _showSensorGraph ? 180 : 16,
                      child: _buildPlaybackPlayer(currentTimestamp, currentSpeed),
                    ),

                    // GRÁFICO INFERIOR DE SENSORES (VELOCIDADE AO LONGO DO TEMPO)
                    if (_showSensorGraph)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 170,
                        child: _buildSensorGraphDrawer(),
                      ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Versão Mobile: Mapa com abas inferiores
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: const Color(0xFF0B1117),
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: const Color(0xFF111A23),
                  child: const TabBar(
                    indicatorColor: Color(0xFFFF1E2D),
                    labelColor: Colors.white,
                    unselectedLabelColor: Color(0xFF94A3B8),
                    tabs: [
                      Tab(icon: Icon(Icons.map, size: 18), text: 'Mapa & Rota'),
                      Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Viagens & Eventos'),
                    ],
                  ),
                ),
              ),
              body: TabBarView(
                children: [
                  // Tab 1: Mapa + Player
                  Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: LatLng(-22.50563, -41.93202),
                          initialZoom: 14.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.target.rastreamento',
                            tileBuilder: darkModeTileBuilder,
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: currentTrip.route,
                                strokeWidth: 5.0,
                                color: const Color(0xFF00E676),
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: currentPos,
                                width: 80,
                                height: 50,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFFF1E2D)),
                                      ),
                                      child: Text(
                                        widget.plate,
                                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const Icon(Icons.navigation, color: Color(0xFF00E676), size: 18),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                  // Tab 2: Lista de Viagens
                  Container(
                    color: const Color(0xFF0F1722),
                    child: Column(
                      children: [
                        _buildHeaderViagens(),
                        Expanded(child: _buildTabelaViagens()),
                        _buildSubTabsHeader(),
                        Expanded(child: _buildSubTabContent()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  // HEADER DE VIAGENS
  Widget _buildHeaderViagens() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111A23),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: Color(0xFFFF1E2D), size: 20),
          const SizedBox(width: 8),
          const Text(
            'Viagens Registradas',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Text(
              '27.10 - 29.10.2026',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // TABELA DE VIAGENS
  Widget _buildTabelaViagens() {
    return ListView.builder(
      itemCount: _trips.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Cabeçalho das colunas
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFF16202C),
            child: const Row(
              children: [
                SizedBox(width: 24, child: Icon(Icons.check_box_outline_blank, size: 14, color: Color(0xFF64748B))),
                SizedBox(width: 75, child: Text('Data', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 50, child: Text('Início', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 50, child: Text('Paragem', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 55, child: Text('Duração', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                SizedBox(width: 65, child: Text('Distância', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Máx km/h', textAlign: TextAlign.right, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
          );
        }

        final trip = _trips[index - 1];
        final isSelected = (_selectedTripIndex == index - 1);

        return InkWell(
          onTap: () {
            setState(() {
              _selectedTripIndex = index - 1;
              _playbackProgress = 0.0;
            });
            if (trip.route.isNotEmpty) {
              _mapController.move(trip.route.first, 14.5);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E293B) : (index % 2 == 0 ? const Color(0xFF0D141D) : const Color(0xFF0F1722)),
              border: Border(
                left: BorderSide(
                  color: isSelected ? const Color(0xFFFF1E2D) : Colors.transparent,
                  width: 3,
                ),
                bottom: const BorderSide(color: Color(0xFF16202C), width: 0.8),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 14,
                    color: isSelected ? const Color(0xFFFF1E2D) : const Color(0xFF64748B),
                  ),
                ),
                SizedBox(
                  width: 75,
                  child: Text(trip.date, style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
                SizedBox(
                  width: 50,
                  child: Text(trip.start, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                ),
                SizedBox(
                  width: 50,
                  child: Text(trip.end, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                ),
                SizedBox(
                  width: 55,
                  child: Text(trip.duration, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ),
                SizedBox(
                  width: 65,
                  child: Text(
                    trip.distanceKm != null ? '${trip.distanceKm!.toStringAsFixed(2)} km' : '-',
                    style: TextStyle(
                      color: trip.distanceKm != null ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: trip.distanceKm != null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    trip.maxSpeed != null ? '${trip.maxSpeed}' : '-',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: trip.maxSpeed != null ? const Color(0xFF35D49A) : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: trip.maxSpeed != null ? FontWeight.bold : FontWeight.normal,
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

  // SUB-TABS HEADER (Eventos / Mídia / Rotas)
  Widget _buildSubTabsHeader() {
    return Container(
      color: const Color(0xFF111A23),
      child: Row(
        children: [
          _buildSubTabButton('eventos', 0),
          _buildSubTabButton('Mídia', 1),
          _buildSubTabButton('Rotas', 2),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B), size: 16),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String label, int index) {
    final isSelected = _selectedSubTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedSubTab = index),
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
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // CONTEÚDO DA SUB-TAB (Eventos / Mídia / Rotas)
  Widget _buildSubTabContent() {
    if (_selectedSubTab == 0) {
      // Eventos
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _events.length,
        separatorBuilder: (context, index) => const Divider(color: Color(0xFF16202C), height: 1),
        itemBuilder: (context, index) {
          final ev = _events[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(ev.icon, size: 15, color: ev.color),
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
                      Text(ev.address, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, color: const Color(0xFF475569), size: 36),
            const SizedBox(height: 8),
            const Text('Nenhum registro de mídia para este período.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          ],
        ),
      );
    } else {
      // Rotas
      final trip = _trips[_selectedTripIndex];
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo da Rota Selecionada', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('• Distância percorrida: ${trip.distanceKm ?? 0.0} km', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            Text('• Velocidade máxima atingida: ${trip.maxSpeed ?? 0} km/h', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            Text('• Tempo em movimento: ${trip.duration}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            Text('• Período: ${trip.start} até ${trip.end}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
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

  // GAVETA INFERIOR DE SENSORES COM GRÁFICO DE VELOCIDADE
  Widget _buildSensorGraphDrawer() {
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
                  maxSpeed: _trips[_selectedTripIndex].maxSpeed ?? 40,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionButton({required String label, required IconData icon}) {
    return Container(
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
    );
  }
}

// PINTOR CUSTOMIZADO DO GRÁFICO DE VELOCIDADE
class _SpeedGraphPainter extends CustomPainter {
  final double playbackProgress;
  final int maxSpeed;

  _SpeedGraphPainter({
    required this.playbackProgress,
    required this.maxSpeed,
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

    // Linhas de Grade Horizontais
    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Gerador de curva de velocidade realista com variações de aceleração e frenagem
    final path = Path();
    final points = 80;
    for (int i = 0; i <= points; i++) {
      final frac = i / points;
      final x = size.width * frac;

      // Função ondulada simulando trânsito real em Rio das Ostras
      final wave1 = math.sin(frac * math.pi * 3);
      final wave2 = math.cos(frac * math.pi * 5) * 0.3;
      final wave3 = math.sin(frac * math.pi * 1.5) * 0.4;
      final speedFactor = ((wave1 + wave2 + wave3).abs()).clamp(0.0, 1.0);

      final y = size.height - (speedFactor * (size.height * 0.82));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    // Linha de Cursor Verde indicando o momento do Playback
    final cursorX = size.width * playbackProgress;
    canvas.drawLine(Offset(cursorX, 0), Offset(cursorX, size.height), cursorPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedGraphPainter oldDelegate) {
    return oldDelegate.playbackProgress != playbackProgress || oldDelegate.maxSpeed != maxSpeed;
  }
}
