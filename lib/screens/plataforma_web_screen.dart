import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/mercosul_plate.dart';
import '../widgets/target_logo.dart';

/// Modelo de Veículo da Plataforma Web
class VeiculoWeb {
  final int id;
  final String nome;
  final String placa;
  final String tipo;
  final IconData icone;
  final String status; // 'Em movimento', 'Parado', 'Atenção'
  final int velocidade;
  final String local;
  final String ultimaAtualizacao;
  final String bateria;
  final String motorista;
  final String unidade;

  const VeiculoWeb({
    required this.id,
    required this.nome,
    required this.placa,
    required this.tipo,
    required this.icone,
    required this.status,
    required this.velocidade,
    required this.local,
    required this.ultimaAtualizacao,
    required this.bateria,
    required this.motorista,
    required this.unidade,
  });
}

/// Modelo de Evento do Histórico
class EventoWeb {
  final IconData icone;
  final String titulo;
  final String desc;
  final String horario;
  final String tipo; // 'alert', 'info', 'warn'

  const EventoWeb({
    required this.icone,
    required this.titulo,
    required this.desc,
    required this.horario,
    required this.tipo,
  });
}

class PlataformaWebScreen extends StatefulWidget {
  const PlataformaWebScreen({super.key});

  @override
  State<PlataformaWebScreen> createState() => _PlataformaWebScreenState();
}

class _PlataformaWebScreenState extends State<PlataformaWebScreen> {
  static const String _whatsappNumero = '5522997694019';

  String _currentView = 'inicio';
  int _selectedVehicleId = 1;
  String _routePeriod = 'Hoje';
  String _searchVeiculos = '';

  // Regras de Alerta (Toggles)
  bool _alertaVelocidade = true;
  bool _alertaCerca = true;
  bool _alertaIgnicao = true;
  bool _alertaBateria = false;

  // Preferências
  bool _notifApp = true;
  bool _notifEmail = true;
  bool _notifWhatsapp = false;
  bool _notifResumo = true;

  // Veículo selecionado para bloqueio
  int _veiculoBloqueioId = 1;

  final List<VeiculoWeb> _veiculos = const [
    VeiculoWeb(
      id: 1,
      nome: 'Chevrolet Corsa Sedan',
      placa: 'MQA-6E92',
      tipo: 'Carro',
      icone: Icons.directions_car,
      status: 'Parado',
      velocidade: 0,
      local: 'Av. Brasília, Costazul · Rio das Ostras',
      ultimaAtualizacao: 'há 5 min',
      bateria: '12,6 V',
      motorista: 'Vidal Rastreamento',
      unidade: 'Rio das Ostras',
    ),
    VeiculoWeb(
      id: 2,
      nome: 'Honda CG 160 Fan',
      placa: 'MQF-7B84',
      tipo: 'Moto',
      icone: Icons.two_wheeler,
      status: 'Parado',
      velocidade: 0,
      local: 'Av. Brasil, Costazul · Rio das Ostras',
      ultimaAtualizacao: 'há 14 min',
      bateria: '12,4 V',
      motorista: 'Ana Costa',
      unidade: 'Rio das Ostras',
    ),
    VeiculoWeb(
      id: 3,
      nome: 'Ford Ranger XLT 4x4',
      placa: 'ABC-1023',
      tipo: 'Picape',
      icone: Icons.directions_car_filled,
      status: 'Em movimento',
      velocidade: 42,
      local: 'Rod. Amaral Peixoto, Km 140',
      ultimaAtualizacao: 'há 1 min',
      bateria: '12,8 V',
      motorista: 'Marcos Lima',
      unidade: 'Macaé',
    ),
    VeiculoWeb(
      id: 4,
      nome: 'Mercedes Sprinter Van',
      placa: 'RTY-4H66',
      tipo: 'Van',
      icone: Icons.airport_shuttle,
      status: 'Atenção',
      velocidade: 0,
      local: 'Pátio operacional · Rio das Ostras',
      ultimaAtualizacao: 'há 36 min',
      bateria: '11,9 V',
      motorista: 'Paula Souza',
      unidade: 'Rio das Ostras',
    ),
    VeiculoWeb(
      id: 5,
      nome: 'Volvo FH 540 Globetrotter',
      placa: 'QXZ-3876',
      tipo: 'Caminhão',
      icone: Icons.local_shipping,
      status: 'Em movimento',
      velocidade: 74,
      local: 'BR-101, Km 164 · Casimiro',
      ultimaAtualizacao: 'há 1 min',
      bateria: '13,1 V',
      motorista: 'Rafael Alves',
      unidade: 'Macaé',
    ),
  ];

  final List<EventoWeb> _eventos = const [
    EventoWeb(
      icone: Icons.warning_amber_rounded,
      titulo: 'Excesso de velocidade',
      desc: 'Toyota Corolla (FGH-3A21) · 88 km/h em via de 60 km/h · Centro',
      horario: '14:32',
      tipo: 'alert',
    ),
    EventoWeb(
      icone: Icons.navigation_outlined,
      titulo: 'Veículo entrou em movimento',
      desc: 'Honda CG 160 (MQF-7B84) · Av. Brasil, Costazul',
      horario: '14:20',
      tipo: 'info',
    ),
    EventoWeb(
      icone: Icons.power_settings_new,
      titulo: 'Ignição ligada',
      desc: 'Ford Ranger (ABC-1023) · Rod. Amaral Peixoto',
      horario: '13:45',
      tipo: 'info',
    ),
    EventoWeb(
      icone: Icons.fence_outlined,
      titulo: 'Entrada em área restrita',
      desc: 'Mercedes Sprinter (RTY-4H66) · Pátio Operacional Macaé',
      horario: '12:03',
      tipo: 'warn',
    ),
    EventoWeb(
      icone: Icons.local_parking,
      titulo: 'Veículo estacionado',
      desc: 'Toyota Corolla · Centro de Macaé · Estacionado há 4h',
      horario: '11:42',
      tipo: 'info',
    ),
  ];

  VeiculoWeb get _veiculoAtual =>
      _veiculos.firstWhere((v) => v.id == _selectedVehicleId, orElse: () => _veiculos[0]);

  void _toast(String mensagem, {bool isGood = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isGood ? Icons.check_circle : Icons.warning_amber_rounded,
                color: isGood ? TargetColors.green : TargetColors.red, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: TargetColors.panelAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: TargetColors.line),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarDialogoConfirmacao({
    required String titulo,
    required String mensagem,
    required String botaoConfirmar,
    required VoidCallback onConfirmar,
    bool isPerigo = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TargetColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: TargetColors.line),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            color: TargetColors.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          mensagem,
          style: const TextStyle(color: TargetColors.textMuted, fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: TargetColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPerigo ? TargetColors.red : TargetColors.panelAlt,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirmar();
            },
            child: Text(botaoConfirmar, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirWhatsApp([String mensagem = 'Olá! Preciso de suporte na plataforma Target.']) async {
    final uri = Uri.parse('https://wa.me/$_whatsappNumero?text=${Uri.encodeComponent(mensagem)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1050;

    return Scaffold(
      backgroundColor: TargetColors.darkBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SIDEBAR (DESKTOP)
          if (isDesktop) _buildSidebarDesktop(),

          // ÁREA PRINCIPAL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TOPBAR
                _buildTopbar(isDesktop),

                // CONTEÚDO DINÂMICO CONFORME A VIEW ATIVA
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 36 : 16,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: _buildCurrentViewContent(isDesktop),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // BOTTOM NAV PARA MOBILE
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(),
    );
  }

  // --- 1. SIDEBAR DESKTOP OFICIAL ---
  Widget _buildSidebarDesktop() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF080D12),
        border: Border(right: BorderSide(color: TargetColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const TargetLogoHorizontal(iconSize: 28),
            ),
          ),
          const Divider(color: TargetColors.line, height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                _buildSecaoLabel('MONITORAMENTO'),
                _buildNavItem('inicio', 'Visão geral', Icons.home_filled),
                _buildNavItem('veiculos', 'Meus veículos', Icons.directions_car_outlined),
                _buildNavItem('rotas', 'Rotas e trajetos', Icons.timeline),
                _buildNavItem('historico', 'Histórico', Icons.history),
                _buildNavItem('alertas', 'Alertas', Icons.notifications_none, badge: '3'),
                _buildNavItem('bloqueio', 'Bloqueio remoto', Icons.lock_outline),

                const SizedBox(height: 16),
                _buildSecaoLabel('GESTÃO'),
                _buildNavItem('frota', 'Gestão de frota', Icons.apartment_outlined),
                _buildNavItem('relatorios', 'Relatórios', Icons.bar_chart_outlined),

                const SizedBox(height: 16),
                _buildSecaoLabel('CONTA'),
                _buildNavItem('notificacoes', 'Notificações', Icons.mark_email_unread_outlined),
                _buildNavItem('configuracoes', 'Configurações', Icons.settings_outlined),
                _buildNavItem('suporte', 'Suporte', Icons.headset_mic_outlined),
              ],
            ),
          ),

          // Banner de demonstração no rodapé da sidebar
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TargetColors.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TargetColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: TargetColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Central Online',
                      style: TextStyle(
                        color: TargetColors.textWhite,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Macaé & Rio das Ostras • 4G Live',
                  style: TextStyle(color: TargetColors.textMuted, fontSize: 10.5),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: TargetColors.red, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Voltar ao site',
                        style: TextStyle(
                          color: TargetColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildSecaoLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Text(
        texto,
        style: const TextStyle(
          color: Color(0xFF647180),
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNavItem(String viewKey, String label, IconData icone, {String? badge}) {
    final ativo = _currentView == viewKey;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _currentView = viewKey),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ativo ? TargetColors.red.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: ativo
              ? const Border(left: BorderSide(color: TargetColors.red, width: 3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icone,
                color: ativo ? TargetColors.red : TargetColors.textMuted, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: ativo ? TargetColors.textWhite : const Color(0xFFAAB4C0),
                  fontSize: 12.5,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: TargetColors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- 2. TOPBAR RESPONSIVA ---
  Widget _buildTopbar(bool isDesktop) {
    final titulos = {
      'inicio': 'Visão geral',
      'veiculos': 'Meus veículos',
      'veiculo': 'Detalhes do veículo',
      'rotas': 'Rotas e trajetos',
      'historico': 'Histórico',
      'alertas': 'Alertas',
      'bloqueio': 'Bloqueio remoto',
      'frota': 'Gestão de frota',
      'relatorios': 'Relatórios',
      'notificacoes': 'Notificações',
      'configuracoes': 'Configurações',
      'suporte': 'Central de suporte',
    };

    return Container(
      height: 68,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 36 : 16),
      decoration: const BoxDecoration(
        color: TargetColors.darkBg,
        border: Border(bottom: BorderSide(color: TargetColors.line)),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: TargetColors.textWhite),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            'TARGET / ',
            style: TextStyle(
              color: TargetColors.textMuted.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            titulos[_currentView] ?? 'Visão geral',
            style: const TextStyle(
              color: TargetColors.textWhite,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          // Status Operacional Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: TargetColors.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TargetColors.line),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: TargetColors.green, size: 7),
                SizedBox(width: 6),
                Text(
                  'Sistema operacional',
                  style: TextStyle(color: Color(0xFFD8E0E8), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Botão WhatsApp Rápido
          IconButton(
            tooltip: 'Falar no WhatsApp',
            icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
            onPressed: () => _abrirWhatsApp(),
          ),

          // Avatar de Perfil
          InkWell(
            onTap: () => setState(() => _currentView = 'configuracoes'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: TargetColors.line,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3B4A58)),
              ),
              child: const Center(
                child: Text(
                  'VR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. CONTEÚDO PRINCIPAL (MULTI-VIEW) ---
  Widget _buildCurrentViewContent(bool isDesktop) {
    switch (_currentView) {
      case 'inicio':
        return _buildViewInicio(isDesktop);
      case 'veiculos':
        return _buildViewVeiculos(isDesktop);
      case 'veiculo':
        return _buildViewDetalheVeiculo(isDesktop);
      case 'rotas':
        return _buildViewRotas(isDesktop);
      case 'historico':
        return _buildViewHistorico(isDesktop);
      case 'alertas':
        return _buildViewAlertas(isDesktop);
      case 'bloqueio':
        return _buildViewBloqueio(isDesktop);
      case 'frota':
        return _buildViewFrota(isDesktop);
      case 'relatorios':
        return _buildViewRelatorios(isDesktop);
      case 'notificacoes':
        return _buildViewNotificacoes(isDesktop);
      case 'configuracoes':
        return _buildViewConfiguracoes(isDesktop);
      case 'suporte':
        return _buildViewSuporte(isDesktop);
      default:
        return _buildViewInicio(isDesktop);
    }
  }

  // --- VIEW: INÍCIO (VISÃO GERAL) ---
  Widget _buildViewInicio(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHead(
          eyebrow: 'PAINEL DE CONTROLE',
          titulo: 'Olá, Vidal Rastreamento 👋',
          desc: 'Aqui está um resumo da sua operação e dos veículos monitorados na região.',
          acaoLabel: '＋ Adicionar veículo',
          onAcao: () => _mostrarDialogoConfirmacao(
            titulo: 'Adicionar Veículo',
            mensagem:
                'No sistema em produção, este fluxo abre o cadastro completo de dispositivo homologado, placa e motorista. Deseja simular?',
            botaoConfirmar: 'Simular Cadastro',
            onConfirmar: () => _toast('Fluxo de cadastro demonstrativo concluído.'),
          ),
        ),
        const SizedBox(height: 20),

        // 4 Stat Cards Responsivos (1 linha no Desktop, Grid 2x2 no Celular)
        if (isDesktop)
          Row(
            children: [
              Expanded(child: _buildStatCard('Veículos cadastrados', '01', '1 ativo no período', Icons.directions_car)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Em movimento', '00', '● 0 em rota agora', Icons.timeline, corDestaque: TargetColors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Parados', '01', 'Estacionado em segurança', Icons.local_parking, corDestaque: TargetColors.amber)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Alertas pendentes', '00', 'Sistema operacional', Icons.notifications_active, corDestaque: TargetColors.green)),
            ],
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('Veículos', '01', '1 cadastrado', Icons.directions_car)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('Em movimento', '00', '0 em rota', Icons.timeline, corDestaque: TargetColors.green)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Parados', '01', 'Estacionado', Icons.local_parking, corDestaque: TargetColors.amber)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('Alertas', '00', 'Operacional', Icons.notifications_active, corDestaque: TargetColors.green)),
                ],
              ),
            ],
          ),
        const SizedBox(height: 24),

        // Grid com Mapa Ilustrativo + Lista de Veículos
        isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildCardMapaMonitoramento(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _buildCardListaResumoVeiculos(),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildCardMapaMonitoramento(),
                  const SizedBox(height: 16),
                  _buildCardListaResumoVeiculos(),
                ],
              ),

        const SizedBox(height: 28),
        _buildSectionTitle('Acesso rápido', 'Atalhos para tarefas frequentes'),
        const SizedBox(height: 14),

        // Acesso Rápido Responsivo (1 linha no Desktop, Coluna no Celular)
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  icone: Icons.timeline,
                  titulo: 'Consultar trajetos',
                  desc: 'Revise percursos e paradas do veículo.',
                  botao: 'Abrir rotas →',
                  onTap: () => setState(() => _currentView = 'rotas'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildFeatureCard(
                  icone: Icons.notifications_none,
                  titulo: 'Central de alertas',
                  desc: 'Veja eventos e notificações recentes.',
                  botao: 'Ver alertas →',
                  onTap: () => setState(() => _currentView = 'alertas'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildFeatureCard(
                  icone: Icons.bar_chart,
                  titulo: 'Relatórios operacionais',
                  desc: 'Acompanhe dados resumidos da frota.',
                  botao: 'Abrir relatórios →',
                  onTap: () => setState(() => _currentView = 'relatorios'),
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildFeatureCard(
                icone: Icons.timeline,
                titulo: 'Consultar trajetos',
                desc: 'Revise percursos e paradas do veículo.',
                botao: 'Abrir rotas →',
                onTap: () => setState(() => _currentView = 'rotas'),
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                icone: Icons.notifications_none,
                titulo: 'Central de alertas',
                desc: 'Veja eventos e notificações recentes.',
                botao: 'Ver alertas →',
                onTap: () => setState(() => _currentView = 'alertas'),
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                icone: Icons.bar_chart,
                titulo: 'Relatórios operacionais',
                desc: 'Acompanhe dados resumidos da frota.',
                botao: 'Abrir relatórios →',
                onTap: () => setState(() => _currentView = 'relatorios'),
              ),
            ],
          ),
      ],
    );
  }

  // --- MAPA MONITORAMENTO ILUSTRATIVO VETORIAL FLUIDO (ZERO TRAVAMENTO) ---
  Widget _buildCardMapaMonitoramento() {
    return Container(
      decoration: BoxDecoration(
        color: TargetColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TargetColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mapa de monitoramento',
                      style: TextStyle(
                        color: TargetColors.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Macaé, Casimiro & Rio das Ostras · Atualização em tempo real',
                      style: TextStyle(color: TargetColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _currentView = 'rotas'),
                  child: const Text('Ver rotas ↗', style: TextStyle(color: TargetColors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(color: TargetColors.line, height: 1),

          // Canvas do Mapa Vetorial Escuro
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
            child: SizedBox(
              height: 340,
              child: Stack(
                children: [
                  // Fundo estilizado do mapa noturno
                  Container(
                    color: const Color(0xFF111C27),
                    width: double.infinity,
                    height: double.infinity,
                    child: CustomPaint(
                      painter: _VectorGridMapPainter(),
                    ),
                  ),

                  // Tag informativa
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF080E14).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF3A4B5C)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.radar, color: TargetColors.red, size: 12),
                          SizedBox(width: 6),
                          Text(
                            'RODOVIA AMARAL PEIXOTO & BR-101 · MACAÉ/RJ',
                            style: TextStyle(
                              color: Color(0xFFC6D0DA),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Marcador do Veículo Ativo
                  Positioned(
                    left: 280,
                    top: 140,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 10)],
                          ),
                          child: const Text(
                            '🚘 MQA-6E92 · Chevrolet Corsa',
                            style: TextStyle(
                              color: Color(0xFF101820),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: TargetColors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: TargetColors.red.withValues(alpha: 0.45),
                                blurRadius: 14,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.navigation, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),

                  // Marcador Secundário (Moto Rio das Ostras)
                  Positioned(
                    left: 120,
                    top: 220,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: TargetColors.panelAlt,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: TargetColors.line),
                          ),
                          child: const Text(
                            '🏍️ MQF-7B84 · Parado',
                            style: TextStyle(color: TargetColors.textMuted, fontSize: 9),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: TargetColors.amber,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.two_wheeler, color: Colors.black, size: 13),
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
                        _buildLegendChip(TargetColors.green, 'Origem (Costazul)'),
                        _buildLegendChip(TargetColors.red, 'Destino (Centro Macaé)'),
                        _buildLegendChip(TargetColors.blue, 'Rota Monitorada 4G'),
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

  Widget _buildLegendChip(Color cor, String rotulo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF080E14).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF344352)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(rotulo, style: const TextStyle(color: Color(0xFFC6D0DA), fontSize: 10)),
        ],
      ),
    );
  }

  // --- CARD LISTA RESUMO DOS VEÍCULOS ---
  Widget _buildCardListaResumoVeiculos() {
    return Container(
      decoration: BoxDecoration(
        color: TargetColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TargetColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seus veículos',
                      style: TextStyle(
                        color: TargetColors.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Status e última atualização',
                      style: TextStyle(color: TargetColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _currentView = 'veiculos'),
                  child: const Text('Ver todos ↗', style: TextStyle(color: TargetColors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(color: TargetColors.line, height: 1),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _veiculos.length.clamp(0, 4),
            separatorBuilder: (context, index) => const Divider(color: TargetColors.line, height: 1),
            itemBuilder: (context, index) {
              final v = _veiculos[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedVehicleId = v.id;
                    _currentView = 'veiculo';
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: TargetColors.panelAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: TargetColors.line),
                        ),
                        child: Icon(v.icone, color: TargetColors.red, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.nome,
                              style: const TextStyle(
                                color: TargetColors.textWhite,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${v.placa} · ${v.velocidade} km/h · ${v.ultimaAtualizacao}',
                              style: const TextStyle(color: TargetColors.textMuted, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(v.status),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, color: TargetColors.line, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- VIEW: MEUS VEÍCULOS (TABELA & BUSCA) ---
  Widget _buildViewVeiculos(bool isDesktop) {
    final filtrados = _veiculos.where((v) {
      final matchesSearch = v.nome.toLowerCase().contains(_searchVeiculos.toLowerCase()) ||
          v.placa.toLowerCase().contains(_searchVeiculos.toLowerCase());
      return matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHead(
          eyebrow: 'MONITORAMENTO',
          titulo: 'Meus veículos',
          desc: 'Consulte seus veículos, status, velocidade e telemetria resumida.',
          acaoLabel: '＋ Adicionar veículo',
          onAcao: () => _toast('Fluxo de cadastro demonstrativo.'),
        ),
        const SizedBox(height: 20),

        // Toolbar de Busca
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TargetColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TargetColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por veículo ou placa...',
                    hintStyle: TextStyle(color: TargetColors.textMuted, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: TargetColors.textMuted, size: 18),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchVeiculos = val),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tabela de Veículos
        Container(
          decoration: BoxDecoration(
            color: TargetColors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TargetColors.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF080D12)),
                columns: const [
                  DataColumn(label: Text('VEÍCULO', style: TextStyle(color: Color(0xFF8391A0), fontSize: 10, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('PLACA', style: TextStyle(color: Color(0xFF8391A0), fontSize: 10, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('STATUS', style: TextStyle(color: Color(0xFF8391A0), fontSize: 10, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('VELOCIDADE', style: TextStyle(color: Color(0xFF8391A0), fontSize: 10, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('LOCALIZAÇÃO', style: TextStyle(color: Color(0xFF8391A0), fontSize: 10, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('AÇÕES', style: TextStyle(color: Color(0xFF8391A0), fontSize: 10, fontWeight: FontWeight.bold))),
                ],
                rows: filtrados.map((v) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Icon(v.icone, color: TargetColors.red, size: 18),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(v.nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                Text(v.tipo, style: const TextStyle(color: TargetColors.textMuted, fontSize: 10.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(MercosulPlate(plate: v.placa, height: 20)),
                      DataCell(_buildStatusBadge(v.status)),
                      DataCell(Text('${v.velocidade} km/h', style: const TextStyle(color: Colors.white, fontSize: 12))),
                      DataCell(Text(v.local, style: const TextStyle(color: TargetColors.textMuted, fontSize: 11.5))),
                      DataCell(
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedVehicleId = v.id;
                              _currentView = 'veiculo';
                            });
                          },
                          child: const Text('Detalhes ↗', style: TextStyle(color: TargetColors.red, fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- VIEW: DETALHES DO VEÍCULO SELECIONADO ---
  Widget _buildViewDetalheVeiculo(bool isDesktop) {
    final v = _veiculoAtual;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHead(
          eyebrow: 'VEÍCULO SELECIONADO',
          titulo: v.nome,
          desc: '${v.placa} · ${v.tipo} · ${v.unidade}',
          acaoLabel: 'Ver histórico',
          onAcao: () => setState(() => _currentView = 'historico'),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: _buildCardMapaMonitoramento(),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TargetColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TargetColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Resumo do veículo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        _buildStatusBadge(v.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Velocidade atual', '${v.velocidade} km/h'),
                    _buildInfoRow('Tensão da bateria', v.bateria),
                    _buildInfoRow('Última atualização', v.ultimaAtualizacao),
                    _buildInfoRow('Condutor responsável', v.motorista),
                    _buildInfoRow('Unidade base', v.unidade),
                    _buildInfoRow('Endereço', v.local),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: TargetColors.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.timeline, size: 16),
                            label: const Text('Ver rotas'),
                            onPressed: () => setState(() => _currentView = 'rotas'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TargetColors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.lock, size: 16),
                            label: const Text('Bloqueio'),
                            onPressed: () {
                              setState(() {
                                _veiculoBloqueioId = v.id;
                                _currentView = 'bloqueio';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- VIEW: ROTAS E TRAJETOS ---
  Widget _buildViewRotas(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHead(
          eyebrow: 'TRAJETOS',
          titulo: 'Rotas e trajetos',
          desc: 'Consulte percursos por período e veículo.',
          acaoLabel: '⇩ Exportar trajeto',
          onAcao: () => _toast('Exportação demonstrativa de trajeto.'),
        ),
        const SizedBox(height: 20),

        // Seletor de Período
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TargetColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TargetColors.line),
          ),
          child: Row(
            children: [
              Wrap(
                spacing: 8,
                children: ['Hoje', 'Últimos 7 dias', 'Últimos 30 dias'].map((p) {
                  final ativo = _routePeriod == p;
                  return InkWell(
                    onTap: () => setState(() => _routePeriod = p),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: ativo ? TargetColors.red : TargetColors.panelAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          color: ativo ? Colors.white : TargetColors.textMuted,
                          fontSize: 12,
                          fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: _buildCardMapaMonitoramento()),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TargetColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TargetColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumo do percurso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildMetricBox('Distância estimada', '48,7 km')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMetricBox('Duração', '1h 12min')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildMetricBox('Paradas', '03 locais')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMetricBox('Velocidade média', '42 km/h')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Pontos do trajeto', style: TextStyle(color: TargetColors.textWhite, fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildWaypointItem('Início do trajeto', 'Av. Brasil, Costazul · 08:12', TargetColors.green),
                    _buildWaypointItem('Parada identificada', 'Centro Macaé · 08:43–08:51 (8 min)', TargetColors.blue),
                    _buildWaypointItem('Fim do trajeto', 'Rod. Amaral Peixoto · 09:24', TargetColors.red),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricBox(String label, String valor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D151D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TargetColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: TargetColors.textMuted, fontSize: 10.5)),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildWaypointItem(String titulo, String detalhe, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(detalhe, style: const TextStyle(color: TargetColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- VIEW: HISTÓRICO ---
  Widget _buildViewHistorico(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHead(
          eyebrow: 'EVENTOS',
          titulo: 'Histórico',
          desc: 'Linha do tempo com eventos recentes do sistema e da frota.',
          acaoLabel: '⇩ Exportar histórico',
          onAcao: () => _toast('Exportação do histórico simulada.'),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TargetColors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TargetColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('27 de outubro · Eventos recentes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _eventos.length,
                separatorBuilder: (context, index) => const Divider(color: TargetColors.line, height: 16),
                itemBuilder: (context, index) {
                  final e = _eventos[index];
                  final cor = e.tipo == 'alert' ? TargetColors.red : (e.tipo == 'warn' ? TargetColors.amber : TargetColors.blue);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: TargetColors.panelAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(e.icone, color: cor, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(e.desc, style: const TextStyle(color: TargetColors.textMuted, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      Text(e.horario, style: const TextStyle(color: Color(0xFF82909F), fontSize: 11)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- VIEW: CENTRAL DE ALERTAS ---
  Widget _buildViewAlertas(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHead(
          eyebrow: 'CENTRAL DE ALERTAS',
          titulo: 'Alertas inteligentes',
          desc: 'Acompanhe eventos importantes e personalize suas regras de notificação.',
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(child: _buildStatCard('Não lidos', '03', 'Precisam de atenção', Icons.notifications_none, corDestaque: TargetColors.red)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Alta prioridade', '01', 'Verifique o evento', Icons.warning_amber, corDestaque: TargetColors.amber)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Hoje', '08', 'Eventos registrados', Icons.calendar_today, corDestaque: TargetColors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Regras ativas', '04', 'Configurações ativas', Icons.tune, corDestaque: TargetColors.green)),
          ],
        ),
        const SizedBox(height: 24),

        // Regras de Alerta
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TargetColors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TargetColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Regras ativas de monitoramento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 16),
              _buildSwitchRow('Excesso de velocidade', 'Avisar imediatamente ao ultrapassar o limite configurado na via.', _alertaVelocidade, (v) => setState(() => _alertaVelocidade = v)),
              _buildSwitchRow('Entrada/saída de cerca virtual', 'Notificar saídas de áreas seguras (garagem, pátio ou cidade).', _alertaCerca, (v) => setState(() => _alertaCerca = v)),
              _buildSwitchRow('Ignição ligada', 'Avisar quando a ignição for acionada fora do horário programado.', _alertaIgnicao, (v) => setState(() => _alertaIgnicao = v)),
              _buildSwitchRow('Bateria baixa do veículo', 'Alertar sobre tensão elétrica abaixo de 11,8 V.', _alertaBateria, (v) => setState(() => _alertaBateria = v)),
            ],
          ),
        ),
      ],
    );
  }

  // --- VIEW: BLOQUEIO REMOTO SENSÍVEL ---
  Widget _buildViewBloqueio(bool isDesktop) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: TargetColors.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TargetColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: TargetColors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: TargetColors.red.withValues(alpha: 0.45)),
                ),
                child: const Center(
                  child: Icon(Icons.lock_outline, color: TargetColors.red, size: 36),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Bloqueio do Veículo',
                style: TextStyle(
                  color: TargetColors.textWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta ação imobiliza a ignição do veículo com corte progressivo de segurança.',
                textAlign: TextAlign.center,
                style: TextStyle(color: TargetColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Aviso de Segurança
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TargetColors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TargetColors.amber.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: TargetColors.amber, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Atenção: Por normas de trânsito e segurança, o corte de motor só é executado com o veículo parado ou em velocidade segura.',
                        style: TextStyle(color: Color(0xFFF5C77C), fontSize: 11.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Seletor de Veículo
              DropdownButtonFormField<int>(
                initialValue: _veiculoBloqueioId,
                dropdownColor: TargetColors.panel,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Selecione o veículo',
                  labelStyle: const TextStyle(color: TargetColors.textMuted),
                  filled: true,
                  fillColor: TargetColors.panelAlt,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TargetColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: TargetColors.line)),
                ),
                items: _veiculos.map((v) {
                  return DropdownMenuItem<int>(
                    value: v.id,
                    child: Text('${v.nome} (${v.placa}) · ${v.status}'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _veiculoBloqueioId = val);
                },
              ),
              const SizedBox(height: 24),

              // Botões de Ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TargetColors.textWhite,
                        side: const BorderSide(color: TargetColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => setState(() => _currentView = 'inicio'),
                      child: const Text('Voltar ao painel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TargetColors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final v = _veiculos.firstWhere((x) => x.id == _veiculoBloqueioId);
                        _mostrarDialogoConfirmacao(
                          titulo: 'Confirmar Bloqueio Remoto',
                          mensagem:
                              'Você confirma o comando de bloqueio para ${v.nome} (${v.placa})? Em produção, o status do dispositivo será monitorado até a confirmação.',
                          botaoConfirmar: 'Simular Bloqueio',
                          isPerigo: true,
                          onConfirmar: () => _toast('Comando de bloqueio simulado para ${v.placa}.'),
                        );
                      },
                      child: const Text('Bloquear Motor', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- VIEW: GESTÃO DE FROTA ---
  Widget _buildViewFrota(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHead(
          eyebrow: 'GESTÃO OPERACIONAL',
          titulo: 'Gestão de frota',
          desc: 'Visão consolidada de veículos, unidades operacionais e condutores.',
          acaoLabel: '⇩ Exportar lista',
          onAcao: () => _toast('Exportação da lista de frota.'),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(child: _buildStatCard('Total de veículos', '12', 'Frota cadastrada', Icons.apartment)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Ativos em rota', '10', '83% da frota ativa', Icons.navigation, corDestaque: TargetColors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Parados', '02', 'No momento', Icons.local_parking, corDestaque: TargetColors.amber)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Motoristas', '08', 'Condutores cadastrados', Icons.badge_outlined, corDestaque: TargetColors.blue)),
          ],
        ),
        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            color: TargetColors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TargetColors.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF080D12)),
                columns: const [
                  DataColumn(label: Text('VEÍCULO', style: TextStyle(color: Color(0xFF8391A0), fontSize: 10, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('PLACA', style: TextStyle(color: Color(0xFF8391A0), fontSize: 10, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('CONDUTOR', style: TextStyle(color: Color(0xFF8391A0), fontSize: 10, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('UNIDADE', style: TextStyle(color: Color(0xFF8391A0), fontSize: 10, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('STATUS', style: TextStyle(color: Color(0xFF8391A0), fontSize: 10, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('AÇÕES', style: TextStyle(color: Color(0xFF8391A0), fontSize: 10, fontWeight: FontWeight.bold))),
                ],
                rows: _veiculos.map((v) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Icon(v.icone, color: TargetColors.red, size: 18),
                            const SizedBox(width: 8),
                            Text(v.nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      DataCell(MercosulPlate(plate: v.placa, height: 20)),
                      DataCell(Text(v.motorista, style: const TextStyle(color: Colors.white, fontSize: 12))),
                      DataCell(Text(v.unidade, style: const TextStyle(color: TargetColors.textMuted, fontSize: 12))),
                      DataCell(_buildStatusBadge(v.status)),
                      DataCell(
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedVehicleId = v.id;
                              _currentView = 'veiculo';
                            });
                          },
                          child: const Text('Abrir ↗', style: TextStyle(color: TargetColors.red, fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- VIEW: RELATÓRIOS ---
  Widget _buildViewRelatorios(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHead(
          eyebrow: 'ANÁLISE OPERACIONAL',
          titulo: 'Relatórios e telemetria',
          desc: 'Indicadores estratégicos de quilometragem percorrida, tempo em movimento e paradas.',
          acaoLabel: '⇩ Gerar relatório',
          onAcao: () => _toast('Relatório exportado com sucesso.'),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Km Percorridos
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TargetColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TargetColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quilômetros percorridos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    const Text('Distância total estimada da frota', style: TextStyle(color: TargetColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 12),
                    const Text('12.480 km', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)),
                    const SizedBox(height: 16),
                    _buildBarChartSimulado([38, 58, 46, 72, 62, 85, 66, 92, 70, 80, 60, 97], TargetColors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Card 2: Tempo em Movimento
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TargetColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TargetColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tempo em movimento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    const Text('Distribuição operacional', style: TextStyle(color: TargetColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 12),
                    const Text('68,4 h', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)),
                    const SizedBox(height: 16),
                    _buildBarChartSimulado([50, 44, 65, 73, 55, 86, 78, 62, 91, 72, 59, 80], TargetColors.blue),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Card 3: Eventos Registrados
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TargetColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TargetColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Eventos registrados', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    const Text('Distribuição por tipo de evento', style: TextStyle(color: TargetColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 12),
                    const Text('146 eventos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)),
                    const SizedBox(height: 20),
                    _buildProgressBarItem('Movimentação em rota', 70, 146, TargetColors.blue),
                    const SizedBox(height: 10),
                    _buildProgressBarItem('Alertas e infrações', 45, 146, TargetColors.red),
                    const SizedBox(height: 10),
                    _buildProgressBarItem('Paradas identificadas', 31, 146, TargetColors.amber),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChartSimulado(List<double> valores, Color cor) {
    return Column(
      children: [
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: valores.map((h) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: h,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(color: TargetColors.line, height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Seg', style: TextStyle(color: TargetColors.textMuted, fontSize: 9.5)),
            Text('Ter', style: TextStyle(color: TargetColors.textMuted, fontSize: 9.5)),
            Text('Qua', style: TextStyle(color: TargetColors.textMuted, fontSize: 9.5)),
            Text('Qui', style: TextStyle(color: TargetColors.textMuted, fontSize: 9.5)),
            Text('Sex', style: TextStyle(color: TargetColors.textMuted, fontSize: 9.5)),
            Text('Sáb', style: TextStyle(color: TargetColors.textMuted, fontSize: 9.5)),
            Text('Dom', style: TextStyle(color: TargetColors.textMuted, fontSize: 9.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBarItem(String label, int valor, int total, Color cor) {
    final pct = (valor / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: TargetColors.textWhite, fontSize: 11)),
            Text('$valor', style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: TargetColors.line,
            valueColor: AlwaysStoppedAnimation(cor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // --- VIEW: NOTIFICAÇÕES ---
  Widget _buildViewNotificacoes(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHead(
          eyebrow: 'CENTRAL DE AVISOS',
          titulo: 'Notificações',
          desc: 'Preferências e avisos recentes da sua conta.',
          acaoLabel: 'Marcar todas como lidas',
          onAcao: () => _toast('Notificações marcadas como lidas.'),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TargetColors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TargetColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Canais de notificação', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 16),
              _buildSwitchRow('Notificações no aplicativo', 'Avisos em push e na central web.', _notifApp, (v) => setState(() => _notifApp = v)),
              _buildSwitchRow('E-mail semanal', 'Resumo de trajetos e horas rodadas.', _notifEmail, (v) => setState(() => _notifEmail = v)),
              _buildSwitchRow('WhatsApp de Alertas', 'Alertas imediatos direto no WhatsApp.', _notifWhatsapp, (v) => setState(() => _notifWhatsapp = v)),
              _buildSwitchRow('Relatório consolidado', 'Boletim diário ao fim do expediente.', _notifResumo, (v) => setState(() => _notifResumo = v)),
            ],
          ),
        ),
      ],
    );
  }

  // --- VIEW: CONFIGURAÇÕES ---
  Widget _buildViewConfiguracoes(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHead(
          eyebrow: 'SUA CONTA',
          titulo: 'Configurações',
          desc: 'Gerencie seu perfil de acesso, preferências e segurança.',
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TargetColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TargetColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dados do titular', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 16),
                    _buildTextFieldDemonstrativo('Nome completo', 'João Silva'),
                    const SizedBox(height: 12),
                    _buildTextFieldDemonstrativo('E-mail cadastrado', 'joao@email.com.br'),
                    const SizedBox(height: 12),
                    _buildTextFieldDemonstrativo('Telefone / WhatsApp', '(22) 99769-4019'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TargetColors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _toast('Alterações salvas com sucesso.'),
                      child: const Text('Salvar alterações', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TargetColors.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TargetColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Segurança e Acesso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 16),
                    _buildInfoRow('Tipo de plano', 'Plano Pro (Comodato)'),
                    _buildInfoRow('Região de atuação', 'Rio das Ostras & Macaé'),
                    _buildInfoRow('Tema da interface', 'Target Dark Noturno (#0B1117)'),
                    _buildInfoRow('Status do contrato', 'Ativo • Renovação automática'),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TargetColors.red,
                        side: const BorderSide(color: TargetColors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _mostrarDialogoConfirmacao(
                        titulo: 'Alterar Senha',
                        mensagem: 'Um link de redefinição de segurança será enviado para joao@email.com.br.',
                        botaoConfirmar: 'Enviar Link',
                        onConfirmar: () => _toast('Link de segurança enviado.'),
                      ),
                      child: const Text('Alterar senha de acesso'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- VIEW: CENTRAL DE SUPORTE ---
  Widget _buildViewSuporte(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHead(
          eyebrow: 'PRECISA DE AJUDA?',
          titulo: 'Central de suporte',
          desc: 'Escolha o canal que funciona melhor para você. Nossa equipe atende diretamente em Macaé e Rio das Ostras.',
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildSupportCard(
                icone: Icons.chat,
                titulo: 'WhatsApp Oficial',
                desc: 'Fale direto com nossa equipe pelo número (22) 99769-4019.',
                botao: 'Abrir WhatsApp ↗',
                onTap: () => _abrirWhatsApp('Olá! Preciso de ajuda na plataforma Target.'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildSupportCard(
                icone: Icons.email_outlined,
                titulo: 'E-mail Técnico',
                desc: 'Envie uma solicitação detalhada com anexos para nosso suporte.',
                botao: 'Enviar e-mail',
                onTap: () => _toast('Abrindo cliente de e-mail...'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildSupportCard(
                icone: Icons.live_help_outlined,
                titulo: 'Perguntas Frequentes',
                desc: 'Tire dúvidas sobre cobertura, sinal 4G, faturas e bloqueio.',
                botao: 'Ver dúvidas',
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- COMPONENTES AUXILIARES ---
  Widget _buildPageHead({
    required String eyebrow,
    required String titulo,
    required String desc,
    String? acaoLabel,
    VoidCallback? onAcao,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: TargetColors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                titulo,
                style: const TextStyle(
                  color: TargetColors.textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: TargetColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
        if (acaoLabel != null && onAcao != null)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TargetColors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onAcao,
            child: Text(acaoLabel, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String numero, String footer, IconData icone, {Color corDestaque = TargetColors.red}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TargetColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TargetColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: TargetColors.textMuted, fontSize: 11.5)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: corDestaque.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: corDestaque, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(numero, style: const TextStyle(color: TargetColors.textWhite, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(footer, style: TextStyle(color: corDestaque, fontSize: 10.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icone,
    required String titulo,
    required String desc,
    required String botao,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TargetColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TargetColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TargetColors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: TargetColors.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(color: TargetColors.textMuted, fontSize: 11)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onTap,
                  child: Text(botao, style: const TextStyle(color: TargetColors.red, fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard({
    required IconData icone,
    required String titulo,
    required String desc,
    required String botao,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TargetColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TargetColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: TargetColors.red, size: 28),
          const SizedBox(height: 12),
          Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: TargetColors.textMuted, fontSize: 12, height: 1.4)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TargetColors.panelAlt,
              foregroundColor: Colors.white,
              side: const BorderSide(color: TargetColors.line),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onTap,
            child: Text(botao, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color cor = TargetColors.green;
    if (status == 'Parado') cor = TargetColors.amber;
    if (status == 'Atenção' || status == 'Bloqueado') cor = TargetColors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 5, height: 5, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rotulo, style: const TextStyle(color: TargetColors.textMuted, fontSize: 12)),
          Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String titulo, String desc, bool valor, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                Text(desc, style: const TextStyle(color: TargetColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: valor,
            activeTrackColor: TargetColors.red,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldDemonstrativo(String label, String valorInicial) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: TargetColors.textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: TargetColors.panelAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TargetColors.line),
          ),
          child: Text(valorInicial, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String titulo, String subtitulo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(subtitulo, style: const TextStyle(color: TargetColors.textMuted, fontSize: 11.5)),
      ],
    );
  }

  // --- MOBILE BOTTOM NAV ---
  Widget _buildMobileBottomNav() {
    final itens = [
      {'key': 'inicio', 'label': 'Início', 'icon': Icons.home_filled},
      {'key': 'veiculos', 'label': 'Veículos', 'icon': Icons.directions_car_outlined},
      {'key': 'rotas', 'label': 'Rotas', 'icon': Icons.timeline},
      {'key': 'alertas', 'label': 'Alertas', 'icon': Icons.notifications_none},
      {'key': 'frota', 'label': 'Mais', 'icon': Icons.menu},
    ];

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF080D12),
        border: Border(top: BorderSide(color: TargetColors.line)),
      ),
      child: Row(
        children: itens.map((item) {
          final ativo = _currentView == item['key'];
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentView = item['key'] as String),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: ativo ? TargetColors.red : TargetColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: ativo ? Colors.white : TargetColors.textMuted,
                      fontSize: 10,
                      fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// CustomPainter para renderizar malha e rota urbana escura vetorial com ZERO latência
class _VectorGridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF1E2D3D).withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    // Grid de ruas secundárias
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Avenidas principais (Rodovia)
    final mainRoadPaint = Paint()
      ..color = const Color(0xFF263A4D)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    final roadPath = Path()
      ..moveTo(-20, size.height * 0.75)
      ..cubicTo(size.width * 0.25, size.height * 0.7, size.width * 0.45, size.height * 0.4, size.width * 0.7, size.height * 0.45)
      ..lineTo(size.width + 20, size.height * 0.25);

    canvas.drawPath(roadPath, mainRoadPaint);

    // Linha de Trajeto Monitorado Target (#FF1E2D)
    final targetRoutePaint = Paint()
      ..color = TargetColors.red
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final targetPath = Path()
      ..moveTo(60, size.height * 0.72)
      ..cubicTo(size.width * 0.25, size.height * 0.68, size.width * 0.45, size.height * 0.42, 296, 172);

    canvas.drawPath(targetPath, targetRoutePaint);

    // Ponto de Origem Verde
    final originPaint = Paint()..color = TargetColors.green;
    canvas.drawCircle(Offset(60, size.height * 0.72), 6, originPaint);

    // Círculo de Cerca Virtual Suave
    final fencePaint = Paint()
      ..color = TargetColors.red.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final fenceStroke = Paint()
      ..color = TargetColors.red.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(60, size.height * 0.72), 35, fencePaint);
    canvas.drawCircle(Offset(60, size.height * 0.72), 35, fenceStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
