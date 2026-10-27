import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/mercosul_plate.dart';

enum MapTileStyle { dark, satellite, streets }

class VeiculoDemo {
  final String id;
  final String nome;
  final String placa;
  final String categoria;
  final IconData icone;
  final LatLng posicaoInicial;
  final List<LatLng> rota;
  final String endereco;
  final double bateria;
  final int satelites;
  final String motorista;
  final double kmTotal;
  final String horimetro;
  bool ignicaoLigada;
  bool bloqueado;
  double velocidadeAtual;

  VeiculoDemo({
    required this.id,
    required this.nome,
    required this.placa,
    required this.categoria,
    required this.icone,
    required this.posicaoInicial,
    required this.rota,
    required this.endereco,
    required this.bateria,
    required this.satelites,
    required this.motorista,
    required this.kmTotal,
    required this.horimetro,
    required this.ignicaoLigada,
    this.bloqueado = false,
    required this.velocidadeAtual,
  });
}

class PlataformaWebScreen extends StatefulWidget {
  const PlataformaWebScreen({super.key});

  @override
  State<PlataformaWebScreen> createState() => _PlataformaWebScreenState();
}

class _PlataformaWebScreenState extends State<PlataformaWebScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  // WhatsApp oficial da Target
  static const String _whatsappNumero = '5522997694019';

  MapTileStyle _estiloMapa = MapTileStyle.dark;
  String _filtroStatus = 'todos'; // todos, movimento, estacionado
  String _buscaTexto = '';
  bool _mostrarCercaVirtual = true;
  final bool _mostrarTrilha = true;

  // Estado da Simulação de Rota (Replay)
  bool _emReproducao = false;
  double _progressoRota = 0.0;
  double _velocidadeMultiplicador = 1.0;
  Timer? _timerRota;
  int _indicePontoAtual = 0;

  // Veículos da Demonstração
  late List<VeiculoDemo> _veiculos;
  late VeiculoDemo _veiculoSelecionado;
  LatLng _posicaoAtualVeiculo = const LatLng(-22.3950, -41.7900);

  @override
  void initState() {
    super.initState();
    _inicializarVeiculos();
  }

  void _inicializarVeiculos() {
    // Rota real em Macaé (Cavaleiros até Imbetiba / Centro via Rodovia Amaral Peixoto)
    final rotaMacae = [
      const LatLng(-22.4150, -41.8120), // Cavaleiros Sul
      const LatLng(-22.4080, -41.8020), // Praia dos Cavaleiros
      const LatLng(-22.4010, -41.7950), // Av. Atlântica
      const LatLng(-22.3950, -41.7900), // Rod. Amaral Peixoto
      const LatLng(-22.3890, -41.7850), // Trevo Imbetiba
      const LatLng(-22.3840, -41.7820), // Av. Agenor Caldas
      const LatLng(-22.3780, -41.7840), // Rua da Praia
      const LatLng(-22.3730, -41.7870), // Centro Macaé
    ];

    // Rota Rio das Ostras (Costazul até Rodovia Amaral Peixoto)
    final rotaRioDasOstras = [
      const LatLng(-22.5180, -41.9120), // Orla de Costazul
      const LatLng(-22.5120, -41.9160), // Av. Roberto Silveira
      const LatLng(-22.5080, -41.9190), // Praça da Baleia
      const LatLng(-22.504771, -41.920289), // Av. Brasília / Costazul
      const LatLng(-22.4980, -41.9250), // R. Bangu
      const LatLng(-22.4920, -41.9300), // Centro / Feirinha
    ];

    // Rota BR-101 (Caminhão Logística)
    final rotaBR101 = [
      const LatLng(-22.4850, -41.9950), // BR-101 Trevo Casimiro
      const LatLng(-22.4600, -41.9700), // BR-101 Km 162
      const LatLng(-22.4350, -41.9450), // BR-101 Posto Shell
      const LatLng(-22.4100, -41.9200), // BR-101 Acesso Macaé
    ];

    _veiculos = [
      VeiculoDemo(
        id: '1',
        nome: 'Toyota Corolla XEi 2.0',
        placa: 'BRA2E19',
        categoria: 'Carro Particular',
        icone: Icons.directions_car,
        posicaoInicial: rotaMacae[3],
        rota: rotaMacae,
        endereco: 'Rodovia Amaral Peixoto, 450 - Imbetiba, Macaé/RJ',
        bateria: 14.2,
        satelites: 18,
        motorista: 'Carlos Eduardo M.',
        kmTotal: 34280.5,
        horimetro: '2h 15m',
        ignicaoLigada: true,
        velocidadeAtual: 58.0,
      ),
      VeiculoDemo(
        id: '2',
        nome: 'Honda CB 650R Neo Sports',
        placa: 'RIO2G24',
        categoria: 'Motocicleta',
        icone: Icons.two_wheeler,
        posicaoInicial: rotaRioDasOstras[3],
        rota: rotaRioDasOstras,
        endereco: 'Av. Brasília, 89 - Costazul, Rio das Ostras/RJ',
        bateria: 12.8,
        satelites: 16,
        motorista: 'Mariana Lima',
        kmTotal: 12450.2,
        horimetro: '0h 42m',
        ignicaoLigada: false,
        velocidadeAtual: 0.0,
      ),
      VeiculoDemo(
        id: '3',
        nome: 'Mercedes Accelo 1016 Delivery',
        placa: 'TRG4F88',
        categoria: 'Caminhão Logística',
        icone: Icons.local_shipping,
        posicaoInicial: rotaBR101[1],
        rota: rotaBR101,
        endereco: 'Rodovia BR-101, Km 162 - Zona Norte, Macaé/RJ',
        bateria: 28.2,
        satelites: 19,
        motorista: 'Marcos Vinicius (Frota 04)',
        kmTotal: 98450.8,
        horimetro: '5h 30m',
        ignicaoLigada: true,
        velocidadeAtual: 72.0,
      ),
    ];

    _veiculoSelecionado = _veiculos[0];
    _posicaoAtualVeiculo = _veiculoSelecionado.posicaoInicial;
  }

  @override
  void dispose() {
    _timerRota?.cancel();
    super.dispose();
  }

  // --- CONTROLE DE REPLAY DE ROTA ---
  void _alternarReproducaoRota() {
    if (_emReproducao) {
      _pausarRota();
    } else {
      _iniciarRota();
    }
  }

  void _iniciarRota() {
    _timerRota?.cancel();
    setState(() => _emReproducao = true);

    final rota = _veiculoSelecionado.rota;
    final intervaloMs = (800 / _velocidadeMultiplicador).round();

    _timerRota = Timer.periodic(Duration(milliseconds: intervaloMs), (timer) {
      if (!mounted) return;

      setState(() {
        if (_indicePontoAtual < rota.length - 1) {
          _indicePontoAtual++;
          _posicaoAtualVeiculo = rota[_indicePontoAtual];
          _progressoRota = _indicePontoAtual / (rota.length - 1);
          _veiculoSelecionado.ignicaoLigada = true;
          _veiculoSelecionado.velocidadeAtual = 45.0 + (_indicePontoAtual * 4.5);
        } else {
          // Chegou ao fim da rota
          _indicePontoAtual = 0;
          _posicaoAtualVeiculo = rota[0];
          _progressoRota = 0.0;
          _veiculoSelecionado.velocidadeAtual = 0.0;
          _emReproducao = false;
          _timerRota?.cancel();
        }
      });

      _mapController.move(_posicaoAtualVeiculo, _mapController.camera.zoom);
    });
  }

  void _pausarRota() {
    _timerRota?.cancel();
    setState(() {
      _emReproducao = false;
      _veiculoSelecionado.velocidadeAtual = 0.0;
    });
  }

  void _selecionarVeiculo(VeiculoDemo veiculo) {
    _pausarRota();
    setState(() {
      _veiculoSelecionado = veiculo;
      _posicaoAtualVeiculo = veiculo.posicaoInicial;
      _indicePontoAtual = 0;
      _progressoRota = 0.0;
    });
    _mapController.move(veiculo.posicaoInicial, 15.5);
  }

  // --- BLOQUEIO DE MOTOR COM CONFIRMAÇÃO ---
  void _confirmarBloqueioMotor() {
    final bloqueado = _veiculoSelecionado.bloqueado;
    final acao = bloqueado ? 'DESBLOQUEAR' : 'BLOQUEAR';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111A23),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFF1E2D), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF1E2D).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.security, color: Color(0xFFFF1E2D), size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirmação de $acao',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Veículo: ${_veiculoSelecionado.nome}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Placa: ${_veiculoSelecionado.placa}',
              style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 13),
            ),
            const SizedBox(height: 14),
            Text(
              bloqueado
                  ? 'O comando de reativação será enviado ao rastreador via satélite 4G. A ignição será liberada imediatamente.'
                  : 'ATENÇÃO: O comando de corte de combustível progressivo será enviado ao rastreador. O motor será desligado com segurança sem causar acidentes.',
              style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bloqueado ? const Color(0xFF35D49A) : const Color(0xFFFF1E2D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executarComandoBloqueio(!bloqueado);
            },
            child: Text(
              bloqueado ? 'Reativar Ignição' : 'Executar Bloqueio',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _executarComandoBloqueio(bool novoEstado) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: novoEstado ? const Color(0xFFFF1E2D) : const Color(0xFF35D49A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(
              novoEstado ? Icons.lock : Icons.lock_open,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                novoEstado
                    ? 'Comando enviado! O veículo foi BLOQUEADO com sucesso.'
                    : 'Comando enviado! Ignição DESBLOQUEADA com sucesso.',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    setState(() {
      _veiculoSelecionado.bloqueado = novoEstado;
      if (novoEstado) {
        _veiculoSelecionado.ignicaoLigada = false;
        _veiculoSelecionado.velocidadeAtual = 0.0;
        _pausarRota();
      }
    });
  }

  Future<void> _abrirWhatsApp(String mensagem) async {
    final url = Uri.parse(
        'https://wa.me/$_whatsappNumero?text=${Uri.encodeComponent(mensagem)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String get _tileUrl {
    switch (_estiloMapa) {
      case MapTileStyle.dark:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapTileStyle.streets:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapTileStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D12),
      body: Column(
        children: [
          // 1. TOP BAR DA PLATAFORMA PRO WEB
          _buildTopBarWeb(isDesktop),

          // 2. CORPO PRINCIPAL (SIDEBAR DE VEÍCULOS + MAPA CENTRAL)
          Expanded(
            child: isDesktop
                ? Row(
                    children: [
                      // Sidebar de Veículos da Frota
                      SizedBox(
                        width: 380,
                        child: _buildSidebarFrota(),
                      ),
                      // Mapa e Controles
                      Expanded(
                        child: _buildMapaCentral(),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      _buildMapaCentral(),
                      // Drawer / Painel deslizante no mobile
                      Positioned(
                        top: 12,
                        left: 12,
                        child: FloatingActionButton.small(
                          backgroundColor: const Color(0xFF111A23),
                          foregroundColor: const Color(0xFFFF1E2D),
                          onPressed: () => _abrirDrawerVeiculosMobile(),
                          child: const Icon(Icons.menu),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- 1. TOP BAR DA PLATAFORMA ---
  Widget _buildTopBarWeb(bool isDesktop) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F141A),
        border: Border(bottom: BorderSide(color: Color(0xFF263238), width: 1.2)),
      ),
      child: Row(
        children: [
          // Logo & Nome do Sistema
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1E2D),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66FF5252), blurRadius: 10),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.gps_fixed, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'TARGET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1E2D),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRO WEB',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Central de Monitoramento & Telemetria',
                      style: TextStyle(color: Color(0xFF78909C), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isDesktop) ...[
            const SizedBox(width: 28),
            const VerticalDivider(color: Color(0xFF263238), width: 1, indent: 14, endIndent: 14),
            const SizedBox(width: 20),

            // Indicador de Conexão ao Vivo
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF35D49A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0xFF35D49A), blurRadius: 6, spreadRadius: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '3 Veículos Online • 4G Multi-Operadora • Uptime 99.9%',
                  style: TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          const Spacer(),

          // Seletor de Camadas de Mapa
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF111A23),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF263238)),
            ),
            child: Row(
              children: [
                _buildBotaoEstiloMapa(
                  label: 'Dark',
                  estilo: MapTileStyle.dark,
                  icone: Icons.dark_mode,
                ),
                _buildBotaoEstiloMapa(
                  label: 'Satélite',
                  estilo: MapTileStyle.satellite,
                  icone: Icons.satellite_alt,
                ),
                _buildBotaoEstiloMapa(
                  label: 'Ruas',
                  estilo: MapTileStyle.streets,
                  icone: Icons.map,
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Botão WhatsApp Comercial
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 10, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.chat, size: 16),
            label: Text(
              isDesktop ? 'Contratar Plataforma' : 'WhatsApp',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _abrirWhatsApp(
                'Olá! Gostei da Plataforma Web da Target e gostaria de contratar para o meu veículo.'),
          ),

          const SizedBox(width: 10),

          // Botão Sair / Voltar
          IconButton(
            tooltip: 'Voltar à Landing Page',
            icon: const Icon(Icons.close, color: Color(0xFF9E9E9E), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoEstiloMapa({
    required String label,
    required MapTileStyle estilo,
    required IconData icone,
  }) {
    final ativo = _estiloMapa == estilo;
    return InkWell(
      onTap: () => setState(() => _estiloMapa = estilo),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ativo ? const Color(0xFFFF1E2D) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 14, color: ativo ? Colors.white : const Color(0xFF9E9E9E)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: ativo ? Colors.white : const Color(0xFF9E9E9E),
                fontSize: 11.5,
                fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. SIDEBAR DE VEÍCULOS & GESTÃO DE FROTA ---
  Widget _buildSidebarFrota() {
    final veiculosFiltrados = _veiculos.where((v) {
      final matchesBusca = v.nome.toLowerCase().contains(_buscaTexto.toLowerCase()) ||
          v.placa.toLowerCase().contains(_buscaTexto.toLowerCase());
      if (!matchesBusca) return false;

      if (_filtroStatus == 'movimento') return v.ignicaoLigada && v.velocidadeAtual > 0;
      if (_filtroStatus == 'estacionado') return !v.ignicaoLigada || v.velocidadeAtual == 0;
      return true;
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F141A),
        border: Border(right: BorderSide(color: Color(0xFF263238), width: 1.2)),
      ),
      child: Column(
        children: [
          // Cabeçalho da Sidebar com Busca e Filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo de Busca
                TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar por placa ou veículo...',
                    hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF757575), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF111A23),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF263238)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF263238)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFF1E2D)),
                    ),
                  ),
                  onChanged: (val) => setState(() => _buscaTexto = val),
                ),
                const SizedBox(height: 12),

                // Filtros de Status (Pills)
                Row(
                  children: [
                    _buildPillFiltro('todos', 'Todos (${_veiculos.length})'),
                    const SizedBox(width: 6),
                    _buildPillFiltro('movimento', 'Em Movimento (2)'),
                    const SizedBox(width: 6),
                    _buildPillFiltro('estacionado', 'Parados (1)'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF263238), height: 1),

          // Lista de Veículos
          Expanded(
            child: ListView.builder(
              itemCount: veiculosFiltrados.length,
              itemBuilder: (context, index) {
                final v = veiculosFiltrados[index];
                final isSelected = v.id == _veiculoSelecionado.id;

                return InkWell(
                  onTap: () => _selecionarVeiculo(v),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF1E2D).withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? const Color(0xFFFF1E2D) : Colors.transparent,
                          width: 4,
                        ),
                        bottom: const BorderSide(color: Color(0xFF1A222D), width: 1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFF1E2D)
                                    : const Color(0xFF1E2633),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(v.icone,
                                  color: isSelected ? Colors.white : const Color(0xFFFF1E2D),
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.nome,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    v.categoria,
                                    style: const TextStyle(
                                        color: Color(0xFF90A4AE), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            MercosulPlate(
                              plate: v.placa,
                              height: 26,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Status de Ignição e Velocidade
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: v.bloqueado
                                        ? const Color(0xFFFF1E2D)
                                        : (v.ignicaoLigada
                                            ? const Color(0xFF35D49A)
                                            : const Color(0xFF9E9E9E)),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  v.bloqueado
                                      ? 'BLOQUEADO'
                                      : (v.ignicaoLigada ? 'IGNIÇÃO LIGADA' : 'DESLIGADO'),
                                  style: TextStyle(
                                    color: v.bloqueado
                                        ? const Color(0xFFFF1E2D)
                                        : (v.ignicaoLigada
                                            ? const Color(0xFF35D49A)
                                            : const Color(0xFF9E9E9E)),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              v.bloqueado
                                  ? 'Motor Cortado'
                                  : '${v.velocidadeAtual.toStringAsFixed(0)} km/h',
                              style: TextStyle(
                                color: v.velocidadeAtual > 0
                                    ? const Color(0xFFFFB300)
                                    : const Color(0xFF90A4AE),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Endereço Resumido
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF78909C), size: 13),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                v.endereco,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF78909C),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Rodapé da Sidebar com Estatísticas Gerais
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0D12),
              border: Border(top: BorderSide(color: Color(0xFF263238))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniIndicadorFrota('3', 'Total Frota', Icons.directions_car),
                _buildMiniIndicadorFrota('2', 'Em Rota', Icons.navigation, cor: const Color(0xFF35D49A)),
                _buildMiniIndicadorFrota('1', 'Parado', Icons.local_parking, cor: const Color(0xFF90A4AE)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillFiltro(String chave, String label) {
    final ativo = _filtroStatus == chave;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filtroStatus = chave),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: ativo ? const Color(0xFFFF1E2D) : const Color(0xFF111A23),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: ativo ? const Color(0xFFFF1E2D) : const Color(0xFF263238),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: ativo ? Colors.white : const Color(0xFF90A4AE),
                fontSize: 10.5,
                fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniIndicadorFrota(String valor, String label, IconData icone,
      {Color cor = Colors.white}) {
    return Row(
      children: [
        Icon(icone, color: cor, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valor,
              style: TextStyle(color: cor, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF78909C), fontSize: 9.5),
            ),
          ],
        ),
      ],
    );
  }

  // --- 3. MAPA CENTRAL COM LAYERS E PLAYER DE ROTA ---
  Widget _buildMapaCentral() {
    final pontoAtual = _posicaoAtualVeiculo;

    return Stack(
      children: [
        // Mapa FlutterMap
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: pontoAtual,
            initialZoom: 15.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // Camada de Tiles com Dark Mode Nativo sem watermark
            TileLayer(
              urlTemplate: _tileUrl,
              userAgentPackageName: 'com.target.rastreamento',
              tileBuilder: _estiloMapa == MapTileStyle.dark ? darkModeTileBuilder : null,
            ),

            // Trajeto Percorrido (Linha Polyline)
            if (_mostrarTrilha)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _veiculoSelecionado.rota.sublist(
                      0,
                      (_indicePontoAtual + 1).clamp(1, _veiculoSelecionado.rota.length),
                    ),
                    color: const Color(0xFFFF1E2D),
                    strokeWidth: 4.5,
                  ),
                  Polyline(
                    points: _veiculoSelecionado.rota,
                    color: const Color(0xFF37474F).withValues(alpha: 0.5),
                    strokeWidth: 3.0,
                    pattern: const StrokePattern.dotted(),
                  ),
                ],
              ),

            // Perímetro de Cerca Virtual
            if (_mostrarCercaVirtual)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _veiculoSelecionado.posicaoInicial,
                    radius: 200, // metros
                    useRadiusInMeter: true,
                    color: const Color(0xFFFF1E2D).withValues(alpha: 0.18),
                    borderColor: const Color(0xFFFF1E2D),
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),

            // Marcadores de Todos os Veículos
            MarkerLayer(
              markers: _veiculos.map((v) {
                final isCurrent = v.id == _veiculoSelecionado.id;
                final pos = isCurrent ? pontoAtual : v.posicaoInicial;

                return Marker(
                  point: pos,
                  width: 90,
                  height: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge da Placa
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFFF1E2D)
                              : const Color(0xFF0F141A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isCurrent ? Colors.white : const Color(0xFF37474F),
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          v.placa,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Marcador Circular com Ícone do Veículo
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFFF1E2D)
                              : const Color(0xFF1E2633),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: isCurrent
                                  ? const Color(0xFFFF1E2D).withValues(alpha: 0.5)
                                  : Colors.black45,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(v.icone, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // 4. CARD FLUTUANTE DE TELEMETRIA AO VIVO (SUPERIOR DIREITO)
        Positioned(
          top: 16,
          right: 16,
          child: _buildCardTelemetriaFlutuante(),
        ),

        // 5. PLAYER DE REPRODUÇÃO DE ROTA (RODAPÉ CENTRAL)
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: _buildPlayerReplayRota(),
        ),
      ],
    );
  }

  // --- 4. CARD DE TELEMETRIA DETALHADA DO VEÍCULO SELECIONADO ---
  Widget _buildCardTelemetriaFlutuante() {
    final v = _veiculoSelecionado;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141A).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF263238), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                v.nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _mostrarCercaVirtual ? Icons.fence : Icons.fence_outlined,
                  color: _mostrarCercaVirtual
                      ? const Color(0xFFFF1E2D)
                      : const Color(0xFF78909C),
                  size: 20,
                ),
                tooltip: 'Alternar Visualização da Cerca',
                onPressed: () =>
                    setState(() => _mostrarCercaVirtual = !_mostrarCercaVirtual),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Motorista: ${v.motorista}',
            style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 12),
          ),
          const Divider(color: Color(0xFF263238), height: 20),

          // Métricas em Grade (Velocidade, Bateria, Satélites, Horímetro)
          Row(
            children: [
              _buildMiniBoxTelemetria(
                '${v.velocidadeAtual.toStringAsFixed(0)} km/h',
                'Velocidade',
                Icons.speed,
                const Color(0xFFFFB300),
              ),
              const SizedBox(width: 8),
              _buildMiniBoxTelemetria(
                '${v.bateria}V',
                'Bateria 4G',
                Icons.battery_charging_full,
                const Color(0xFF35D49A),
              ),
              const SizedBox(width: 8),
              _buildMiniBoxTelemetria(
                '${v.satelites}',
                'Satélites',
                Icons.satellite_alt,
                const Color(0xFF00E5FF),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Botões de Ação Imediata (Bloqueio / Cerca)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: v.bloqueado
                        ? const Color(0xFF35D49A)
                        : const Color(0xFFFF1E2D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    v.bloqueado ? Icons.lock_open : Icons.lock,
                    size: 16,
                  ),
                  label: Text(
                    v.bloqueado ? 'Desbloquear' : 'Bloquear Motor',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _confirmarBloqueioMotor,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF37474F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onPressed: () {
                  _mapController.move(_posicaoAtualVeiculo, 17.0);
                },
                child: const Icon(Icons.my_location, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBoxTelemetria(
      String valor, String label, IconData icone, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF111A23),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF263238)),
        ),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 16),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF78909C), fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. PLAYER DE REPRODUÇÃO DE ROTA (TIMELINE PLAYER) ---
  Widget _buildPlayerReplayRota() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF263238), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          // Botão Play / Pause
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFF1E2D),
              foregroundColor: Colors.white,
            ),
            icon: Icon(_emReproducao ? Icons.pause : Icons.play_arrow),
            onPressed: _alternarReproducaoRota,
          ),
          const SizedBox(width: 14),

          // Informações do Player
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SIMULAÇÃO DE TRAJETO EM TEMPO REAL',
                style: TextStyle(
                  color: Color(0xFFFF1E2D),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${_veiculoSelecionado.placa} • Ponto ${_indicePontoAtual + 1} de ${_veiculoSelecionado.rota.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Slider de Progresso
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFFF1E2D),
                inactiveTrackColor: const Color(0xFF263238),
                thumbColor: Colors.white,
                trackHeight: 4,
              ),
              child: Slider(
                value: _progressoRota,
                onChanged: (novoValor) {
                  _pausarRota();
                  final rota = _veiculoSelecionado.rota;
                  final novoIndice = (novoValor * (rota.length - 1)).round();
                  setState(() {
                    _progressoRota = novoValor;
                    _indicePontoAtual = novoIndice;
                    _posicaoAtualVeiculo = rota[novoIndice];
                  });
                  _mapController.move(_posicaoAtualVeiculo, _mapController.camera.zoom);
                },
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Multiplicador de Velocidade
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF111A23),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF263238)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: _velocidadeMultiplicador,
                dropdownColor: const Color(0xFF111A23),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                items: const [
                  DropdownMenuItem(value: 1.0, child: Text('1x')),
                  DropdownMenuItem(value: 2.0, child: Text('2x')),
                  DropdownMenuItem(value: 4.0, child: Text('4x')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _velocidadeMultiplicador = v);
                    if (_emReproducao) {
                      _pausarRota();
                      _iniciarRota();
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DRAWER MOBILE PARA SELEÇÃO DE VEÍCULOS ---
  void _abrirDrawerVeiculosMobile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F141A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: _buildSidebarFrota(),
      ),
    );
  }
}
