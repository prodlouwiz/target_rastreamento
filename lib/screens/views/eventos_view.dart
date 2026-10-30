import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/pilot_telemetry_service.dart';

class EventLogModel {
  final String title;
  final String subtitle;
  final String category; // 'ignicao', 'energia', 'velocidade', 'cerca'
  final String timestamp;
  final String address;
  final String coords;
  final IconData icon;
  final Color color;
  final String status;

  EventLogModel({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.timestamp,
    required this.address,
    required this.coords,
    required this.icon,
    required this.color,
    required this.status,
  });
}

class EventosView extends StatefulWidget {
  final String? token;
  final int? nodeId;
  final String? imei;
  final String plate;
  final String model;
  final Function(String coords)? onVerNoMapa;

  const EventosView({
    super.key,
    this.token,
    this.nodeId,
    this.imei,
    this.plate = 'MQA6E92',
    this.model = 'Chevrolet Corsa 2020',
    this.onVerNoMapa,
  });

  @override
  State<EventosView> createState() => _EventosViewState();
}

class _EventosViewState extends State<EventosView> {
  String _selectedCategory = 'todos';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  late List<EventLogModel> _allEvents;

  @override
  void initState() {
    super.initState();
    _initDefaultEvents();
    if (widget.token != null && widget.token!.isNotEmpty) {
      _carregarEventosApi();
    }
  }

  void _initDefaultEvents() {
    _allEvents = [
      EventLogModel(
        title: 'Alimentação Externa Conectada',
        subtitle: 'Power: Connected · Rastreador alimentado pela bateria principal',
        category: 'energia',
        timestamp: '18:50:12 · 29/10/2026',
        address: 'Avenida dos Bandeirantes, 1420, Costazul, Rio das Ostras - RJ',
        coords: '-22.50563, -41.93202',
        icon: Icons.power,
        color: const Color(0xFF35D49A),
        status: 'Sucesso',
      ),
      EventLogModel(
        title: 'Ignição Ligada (ACC ON)',
        subtitle: 'Motor em funcionamento · Viagem iniciada',
        category: 'ignicao',
        timestamp: '18:49:05 · 29/10/2026',
        address: 'Av. Governador Roberto Silveira, Costazul, Rio das Ostras - RJ',
        coords: '-22.50850, -41.92980',
        icon: Icons.key,
        color: const Color(0xFF38BDF8),
        status: 'Ativo',
      ),
      EventLogModel(
        title: 'Entrada na Cerca Virtual "Costazul"',
        subtitle: 'Veículo ingressou no perímetro seguro autorizado',
        category: 'cerca',
        timestamp: '18:15:40 · 29/10/2026',
        address: 'Praça da Baleia / Orla de Costazul, Rio das Ostras - RJ',
        coords: '-22.51850, -41.92180',
        icon: Icons.fence,
        color: const Color(0xFF818CF8),
        status: 'Cerca',
      ),
      EventLogModel(
        title: 'Ignição Desligada (ACC OFF)',
        subtitle: 'Motor desligado · Início de estacionamento (6h 46min)',
        category: 'ignicao',
        timestamp: '12:02:19 · 29/10/2026',
        address: 'Rua Niterói, 320, Jardim Mariléa, Rio das Ostras - RJ',
        coords: '-22.49720, -41.94860',
        icon: Icons.key_off,
        color: const Color(0xFF94A3B8),
        status: 'Parado',
      ),
      EventLogModel(
        title: 'Ignição Ligada (ACC ON)',
        subtitle: 'Partida confirmada · Telemetria em tempo real',
        category: 'ignicao',
        timestamp: '11:14:48 · 29/10/2026',
        address: 'Reduto da Paz, Rio das Ostras - RJ',
        coords: '-22.51180, -41.92790',
        icon: Icons.key,
        color: const Color(0xFF38BDF8),
        status: 'Ativo',
      ),
      EventLogModel(
        title: 'Saída da Cerca Virtual "Garagem Mariléa"',
        subtitle: 'Veículo em rota externa em direção ao Centro',
        category: 'cerca',
        timestamp: '09:13:00 · 29/10/2026',
        address: 'Rodovia Amaral Peixoto (RJ-106), Km 144, Macaé / Rio das Ostras',
        coords: '-22.49050, -41.96100',
        icon: Icons.output,
        color: const Color(0xFFFFB300),
        status: 'Alerta',
      ),
      EventLogModel(
        title: 'Ignição Desligada (ACC OFF)',
        subtitle: 'Parada de 2h 01min registrada',
        category: 'ignicao',
        timestamp: '09:13:22 · 29/10/2026',
        address: 'Av. Rui Barbosa, Centro, Macaé - RJ',
        coords: '-22.37890, -41.78200',
        icon: Icons.key_off,
        color: const Color(0xFF94A3B8),
        status: 'Parado',
      ),
      EventLogModel(
        title: 'Velocidade Registrada (61 km/h)',
        subtitle: 'Pico de aceleração em via arterial expressa (limite 80)',
        category: 'velocidade',
        timestamp: '09:45:10 · 28/10/2026',
        address: 'Rodovia Amaral Peixoto (RJ-106), Rio das Ostras - RJ',
        coords: '-22.49980, -41.94310',
        icon: Icons.speed,
        color: const Color(0xFF35D49A),
        status: 'Normal',
      ),
      EventLogModel(
        title: 'Bateria do Rastreador em 98%',
        subtitle: 'Carregamento interno estável e sem oscilações',
        category: 'energia',
        timestamp: '08:00:00 · 28/10/2026',
        address: 'Costazul, Rio das Ostras - RJ',
        coords: '-22.50563, -41.93202',
        icon: Icons.battery_charging_full,
        color: const Color(0xFF35D49A),
        status: 'Normal',
      ),
    ];
  }

  Future<void> _carregarEventosApi() async {
    if (widget.token == null || widget.token!.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final apiEvents = await PilotTelemetryService.fetchEvents(
        token: widget.token!,
        nodeId: widget.nodeId,
        plate: widget.plate,
        imei: widget.imei,
      );

      if (mounted && apiEvents.isNotEmpty) {
        setState(() {
          _allEvents = apiEvents.map((e) {
            String cat = 'ignicao';
            final evLow = e.event.toLowerCase();
            if (evLow.contains('power') || evLow.contains('bater') || evLow.contains('energia')) {
              cat = 'energia';
            } else if (evLow.contains('cerca') || evLow.contains('fence')) {
              cat = 'cerca';
            } else if (evLow.contains('veloc') || evLow.contains('speed')) {
              cat = 'velocidade';
            }

            return EventLogModel(
              title: e.event,
              subtitle: 'Evento registrado pela telemetria Pilot GPS',
              category: cat,
              timestamp: e.date,
              address: e.address,
              coords: e.coords,
              icon: e.icon,
              color: e.color,
              status: 'Oficial',
            );
          }).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<EventLogModel> get _filteredEvents {
    return _allEvents.where((e) {
      final matchesCategory = _selectedCategory == 'todos' || e.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      body: Column(
        children: [
          // 1. Barra Superior com Título, Busca e Filtro de Categoria
          _buildTopBar(),

          // 2. Chips de Filtro Rápido
          _buildFilterChips(),

          // 3. Lista de Eventos Cronológicos
          Expanded(
            child: _buildEventsList(),
          ),
        ],
      ),
    );
  }

  // BARRA SUPERIOR
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111A23),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: Color(0xFFFF1E2D), size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log de Eventos do Rastreador',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '${widget.plate} · ${widget.model}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          // Campo de Busca
          Container(
            width: 220,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Buscar evento ou rua...',
                hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)))
                : const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 20),
            tooltip: 'Sincronizar Eventos',
            onPressed: _carregarEventosApi,
          ),
        ],
      ),
    );
  }

  // CHIPS DE FILTRO RÁPIDO
  Widget _buildFilterChips() {
    final categories = [
      {'id': 'todos', 'label': 'Todos os Eventos'},
      {'id': 'ignicao', 'label': 'Ignição (ACC)'},
      {'id': 'cerca', 'label': 'Cercas Virtuais'},
      {'id': 'energia', 'label': 'Alimentação / Bateria'},
      {'id': 'velocidade', 'label': 'Velocidade'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1722),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  cat['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFFFF1E2D),
                backgroundColor: const Color(0xFF1E293B),
                side: BorderSide(color: isSelected ? const Color(0xFFFF1E2D) : const Color(0xFF334155)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onSelected: (_) => setState(() => _selectedCategory = cat['id']!),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // LISTA DE EVENTOS COM TIMELINE E BOTÕES DE AÇÃO
  Widget _buildEventsList() {
    final events = _filteredEvents;

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.event_busy, color: Color(0xFF64748B), size: 40),
            SizedBox(height: 10),
            Text('Nenhum evento encontrado para este filtro', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final ev = events[index];
        final isLast = index == events.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Linha Vertical da Linha do Tempo
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: ev.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: ev.color, width: 1.5),
                      ),
                      child: Icon(ev.icon, color: ev.color, size: 14),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Card do Evento
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111A23),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(ev.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(ev.timestamp, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(ev.subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFFF1E2D), size: 13),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ev.address,
                                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Copiar Coordenadas
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: ev.coords));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Coordenadas copiadas: ${ev.coords}'),
                                    backgroundColor: const Color(0xFF1E293B),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
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
                                    const Icon(Icons.copy, color: Color(0xFF94A3B8), size: 12),
                                    const SizedBox(width: 4),
                                    Text(ev.coords, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Botão Ver no Mapa
                            InkWell(
                              onTap: () {
                                if (widget.onVerNoMapa != null) {
                                  widget.onVerNoMapa!(ev.coords);
                                }
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF0284C7)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.map, color: Color(0xFF38BDF8), size: 12),
                                    SizedBox(width: 4),
                                    Text('Ver no mapa', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
