import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final String plate;
  final String model;
  final Function(String coords)? onVerNoMapa;

  const EventosView({
    super.key,
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

  late final List<EventLogModel> _allEvents;

  @override
  void initState() {
    super.initState();

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
        status: 'Bateria',
      ),
      EventLogModel(
        title: 'Comando Remoto: Verificação de Status',
        subtitle: 'Ping e sincronização de telemetria concluídos com sucesso',
        category: 'energia',
        timestamp: '18:25:00 · 27/10/2026',
        address: 'Rio das Ostras - RJ',
        coords: '-22.50563, -41.93202',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF38BDF8),
        status: 'Telemetria',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EventLogModel> get _filteredEvents {
    return _allEvents.where((e) {
      final matchesCategory = (_selectedCategory == 'todos' || e.category == _selectedCategory);
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          e.title.toLowerCase().contains(query) ||
          e.subtitle.toLowerCase().contains(query) ||
          e.address.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      body: Column(
        children: [
          // 1. Barra Superior de Filtros & Busca
          _buildFilterBar(),

          // 2. Chips de Categorias
          _buildCategoryChips(),

          // 3. Lista Cronológica de Eventos
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_busy, color: Color(0xFF334155), size: 48),
                        const SizedBox(height: 12),
                        const Text('Nenhum evento encontrado para o filtro atual.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildEventCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // BARRA DE BUSCA
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: const Color(0xFF111A23),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: Color(0xFFFF1E2D), size: 20),
          const SizedBox(width: 8),
          const Text(
            'Eventos & Alarmes',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Filtrar por endereço, status ou evento...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CHIPS DE CATEGORIAS
  Widget _buildCategoryChips() {
    final categories = [
      {'id': 'todos', 'label': 'Todos (${_allEvents.length})'},
      {'id': 'ignicao', 'label': 'Ignição (${_allEvents.where((e) => e.category == 'ignicao').length})'},
      {'id': 'energia', 'label': 'Alimentação (${_allEvents.where((e) => e.category == 'energia').length})'},
      {'id': 'cerca', 'label': 'Cercas (${_allEvents.where((e) => e.category == 'cerca').length})'},
      {'id': 'velocidade', 'label': 'Velocidade (${_allEvents.where((e) => e.category == 'velocidade').length})'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF111A23),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(
                  cat['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                backgroundColor: const Color(0xFF1E293B),
                selectedColor: const Color(0xFFFF1E2D),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                side: BorderSide(color: isSelected ? const Color(0xFFFF1E2D) : const Color(0xFF334155)),
                onSelected: (_) {
                  setState(() => _selectedCategory = cat['id']!);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // CARD DE EVENTO
  Widget _buildEventCard(EventLogModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111A23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone com fundo colorido
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: item.color.withValues(alpha: 0.3)),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),

            // Informações do Evento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: item.color.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(color: item.color, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 6),

                  // Endereço e Coordenadas
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFFF1E2D)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.address,
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Data / Hora e Ações Rápidas
                  Row(
                    children: [
                      Text(
                        item.timestamp,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace'),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.coords,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace'),
                      ),
                      const Spacer(),
                      // Botão Copiar Coordenadas
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: item.coords));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Coordenadas copiadas!'),
                              backgroundColor: Color(0xFF1E293B),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 11, color: Color(0xFF38BDF8)),
                              SizedBox(width: 3),
                              Text('Copiar', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

