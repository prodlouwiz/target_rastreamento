import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/mercosul_plate.dart';
import '../widgets/target_logo.dart';
import 'login_screen.dart';

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _planosKey = GlobalKey();
  final GlobalKey _recursosKey = GlobalKey();
  final GlobalKey _cercasKey = GlobalKey();
  final GlobalKey _relatoriosKey = GlobalKey();
  final GlobalKey _simuladorKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  // WhatsApp oficial da Target
  static const String _whatsappNumero = '5522997694019';

  // --- ANIMAÇÃO DO RADAR HOLOGRÁFICO ---
  late AnimationController _radarController;

  // --- ESTADO DO SIMULADOR INTERATIVO DO APP ---
  String _veiculoSelecionado = 'carro'; // 'carro', 'moto', 'frota'
  String _abaSimulador = 'mapa'; // 'mapa', 'cerca', 'relatorios'
  bool _ignicaoLigada = true;
  bool _motorBloqueado = false;
  bool _emMovimento = false;
  double _velocidade = 0;
  double _odometro = 25.61;
  bool _mostrarAlertaWhatsapp = false;
  String _tipoAlertaWhatsapp = 'ignicao'; // 'ignicao' ou 'cerca'
  Timer? _timerMovimento;

  // Coordenadas reais de Rio das Ostras e Macaé - RJ
  static const LatLng _coordRioDasOstras = LatLng(-22.504771, -41.920289);
  static const LatLng _coordMacae = LatLng(-22.3768, -41.7869);

  // --- PROVA SOCIAL DINÂMICA (TOASTS PROFISSIONAIS AO VIVO) ---
  final List<Map<String, String>> _notificacoesSociais = [
    {
      'icone': '🚗',
      'cidade': 'Rio das Ostras - RJ',
      'veiculo': 'Toyota Corolla 2024',
      'acao': 'Rastreador 4G ativado',
      'tempo': 'há 4 minutos',
    },
    {
      'icone': '🛡️',
      'cidade': 'Macaé - RJ',
      'veiculo': 'Honda Civic',
      'acao': 'Cerca virtual perimetral configurada',
      'tempo': 'há 11 minutos',
    },
    {
      'icone': '📊',
      'cidade': 'Rio das Ostras - RJ',
      'veiculo': 'Frota 04 Veículos',
      'acao': 'Relatório diário de rotas gerado',
      'tempo': 'há 21 minutos',
    },
    {
      'icone': '🏍️',
      'cidade': 'Macaé - RJ',
      'veiculo': 'Honda CB 650R',
      'acao': 'Bloqueio remoto testado com sucesso',
      'tempo': 'há 32 minutos',
    },
    {
      'icone': '🚚',
      'cidade': 'Campos dos Goytacazes - RJ',
      'veiculo': 'Caminhão Mercedes Accelo',
      'acao': 'Telemetria de horímetro conectada',
      'tempo': 'há 45 minutos',
    },
  ];

  int _indiceNotificacaoAtual = 0;
  bool _toastVisivel = false;
  Timer? _timerToast;

  // --- SELETOR DE QUANTIDADE DE VEÍCULOS ---
  int _quantidadeVeiculos = 1;

  @override
  void initState() {
    super.initState();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _iniciarCicloProvaSocial();
  }

  void _iniciarCicloProvaSocial() {
    _timerToast = Timer.periodic(const Duration(seconds: 14), (timer) {
      if (!mounted) return;
      setState(() {
        _toastVisivel = true;
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _toastVisivel = false;
            _indiceNotificacaoAtual =
                (_indiceNotificacaoAtual + 1) % _notificacoesSociais.length;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _timerMovimento?.cancel();
    _timerToast?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // --- AÇÕES DO SIMULADOR ---
  void _alternarMovimento() {
    setState(() {
      if (_emMovimento) {
        _emMovimento = false;
        _velocidade = 0;
        _timerMovimento?.cancel();
      } else {
        if (_motorBloqueado) {
          _mostrarMensagem(
              'Motor bloqueado! Desbloqueie para simular a aceleração.',
              isAlerta: true);
          return;
        }
        _emMovimento = true;
        _ignicaoLigada = true;
        _abaSimulador = 'mapa';
        _timerMovimento?.cancel();
        _timerMovimento =
            Timer.periodic(const Duration(milliseconds: 100), (t) {
          if (!mounted || !_emMovimento) {
            t.cancel();
            return;
          }
          setState(() {
            if (_velocidade < 62) {
              _velocidade += 2;
            }
            _odometro += 0.02;
          });
        });
      }
    });
  }

  void _testarBloqueioMotor() {
    setState(() {
      _motorBloqueado = !_motorBloqueado;
      if (_motorBloqueado) {
        _ignicaoLigada = false;
        _emMovimento = false;
        _velocidade = 0;
        _timerMovimento?.cancel();
        _tipoAlertaWhatsapp = 'bloqueio';
        _mostrarAlertaWhatsapp = true;
      }
    });
  }

  void _simularViolacaoCerca() {
    setState(() {
      _abaSimulador = 'cerca';
      _tipoAlertaWhatsapp = 'cerca';
      _mostrarAlertaWhatsapp = true;
    });
  }

  Future<void> _abrirWhatsApp(
      [String mensagem =
          'Olá! Gostaria de mais informações sobre o rastreamento veicular da Target.']) async {
    final uri = Uri.parse(
        'https://wa.me/$_whatsappNumero?text=${Uri.encodeComponent(mensagem)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível abrir o WhatsApp: $e'),
            backgroundColor: const Color(0xFF1E1E1E),
          ),
        );
      }
    }
  }

  void _mostrarMensagem(String texto, {bool isAlerta = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor:
            isAlerta ? const Color(0xFFFF5252) : const Color(0xFF00E676),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _rolarParaSecao(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _irParaLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;
    final isTablet = screenWidth >= 650 && screenWidth < 980;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0F13), // Preto Profundo Tecnológico
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF25D366), // Verde WhatsApp Oficial
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.chat, size: 22),
        label: const Text(
          'WhatsApp (22) 99769-4019',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        onPressed: () => _abrirWhatsApp(
            'Olá! Gostaria de falar com um especialista sobre o rastreamento da Target.'),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. NAVBAR RESPONSIVA
              SliverAppBar(
                backgroundColor: const Color(0xFF0C0F13).withValues(alpha: 0.95),
                floating: true,
                pinned: true,
                elevation: 2,
                toolbarHeight: 72,
                titleSpacing: isDesktop ? 40 : 16,
                title: Row(
                  children: [
                    const Icon(Icons.radar, color: Color(0xFFFF5252), size: 28),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TARGET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                          ),
                        ),
                        Text(
                          'RASTREAMENTO VEICULAR',
                          style: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 8.5,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Links Centrais
                    if (isDesktop) ...[
                      _buildNavLink(
                          'Início',
                          () => _scrollController.animateTo(0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut)),
                      _buildNavLink('Demonstração',
                          () => _rolarParaSecao(_simuladorKey)),
                      _buildNavLink(
                          'Cercas Virtuais', () => _rolarParaSecao(_cercasKey)),
                      _buildNavLink(
                          'Relatórios', () => _rolarParaSecao(_relatoriosKey)),
                      _buildNavLink('Recursos',
                          () => _rolarParaSecao(_recursosKey)),
                      _buildNavLink(
                          'Planos', () => _rolarParaSecao(_planosKey)),
                      _buildNavLink('FAQ', () => _rolarParaSecao(_faqKey)),
                      const SizedBox(width: 14),
                    ],

                    // Botão Login
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                            color: Color(0xFFFF5252), width: 1.2),
                        backgroundColor: const Color(0xFF1E1E1E),
                        padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 18 : 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.login,
                          size: 16, color: Color(0xFFFF5252)),
                      label: Text(
                        isDesktop ? 'Área do Cliente' : 'Login',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _irParaLogin,
                    ),

                    const SizedBox(width: 10),

                    // Botão WhatsApp
                    if (!isTablet && !isDesktop)
                      IconButton(
                        icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                        tooltip: 'WhatsApp',
                        onPressed: () => _abrirWhatsApp(),
                      )
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text(
                          'Falar no WhatsApp',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _abrirWhatsApp(
                            'Olá! Quero falar com um consultor da Target Rastreamento.'),
                      ),
                  ],
                ),
              ),

              // 2. CONTEÚDO PRINCIPAL
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // HERO SECTION COM RADAR HOLOGRÁFICO
                    _buildHeroSectionComRadar(isDesktop),

                    // BARRA DE CATEGORIAS PROFISSIONAIS
                    _buildCategoriasBar(isDesktop),

                    // TRUST BAR REALISTA
                    _buildTrustBar(isDesktop),

                    // SIMULADOR INTERATIVO COM MAPA REAL DE MACAÉ / RIO DAS OSTRAS
                    Container(
                      key: _simuladorKey,
                      child: _buildSecaoSimuladorInterativo(isDesktop),
                    ),

                    // SEÇÃO DE DESTAQUE: CERCAS VIRTUAIS
                    Container(
                      key: _cercasKey,
                      child: _buildSecaoCercasVirtuais(isDesktop),
                    ),

                    // SEÇÃO DE DESTAQUE: RELATÓRIOS E TELEMETRIA
                    Container(
                      key: _relatoriosKey,
                      child: _buildSecaoRelatorios(isDesktop),
                    ),

                    // SELOS DE TECNOLOGIA E HOMOLOGAÇÃO
                    _buildSelosAutoridade(isDesktop),

                    // SEÇÃO: PRINCIPAIS RECURSOS
                    Container(
                      key: _recursosKey,
                      child: _buildSecaoRecursos(isDesktop),
                    ),

                    // TABELA DE PLANOS COM SELETOR DE VEÍCULOS
                    Container(
                      key: _planosKey,
                      child: _buildSecaoPlanosComSeletor(isDesktop),
                    ),

                    // FAQ
                    Container(
                      key: _faqKey,
                      child: _buildSecaoFaq(isDesktop),
                    ),

                    // CTA FINAL
                    _buildSecaoCtaFinal(),

                    // FOOTER
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          ),

          // 3. TOAST FLUTUANTE DE PROVA SOCIAL AO VIVO
          if (isDesktop || isTablet)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              left: 24,
              bottom: _toastVisivel ? 24 : -120,
              child: _buildToastProvaSocial(),
            ),
        ],
      ),
    );
  }

  // --- 1. HERO SECTION COM RADAR ---
  Widget _buildHeroSectionComRadar(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: isDesktop ? 80 : 50,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0F13),
        gradient: RadialGradient(
          center: Alignment(0.4, -0.5),
          radius: 1.4,
          colors: [
            Color(0x33FF5252),
            Color(0xFF0C0F13),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.35,
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _RadarMilitarPainter(_radarController.value),
                      );
                    },
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2C3E50)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFB300),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Color(0xFFFFB300),
                                  blurRadius: 6,
                                  spreadRadius: 1),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tecnologia de Ponta em Rastreamento 4G',
                          style: TextStyle(
                            color: Color(0xFFB0BEC5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(text: 'Segurança e\nMonitoramento '),
                        TextSpan(
                          text: 'em\nTempo Real',
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            shadows: [
                              Shadow(color: Color(0x88FF5252), blurRadius: 26),
                            ],
                          ),
                        ),
                        TextSpan(text: ' para seu\nCarro, Moto ou Frota'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: const Text(
                      'Rastreamento veicular via satélite com cobertura 4G, cercas virtuais inteligentes, relatórios gerenciais e bloqueio de motor imediato na palma da sua mão.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Wrap(
                    spacing: 16,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5252),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 6,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 20),
                        label: const Text(
                          'Falar com um Especialista',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5),
                        ),
                        onPressed: () => _abrirWhatsApp(
                            'Olá! Gostaria de falar com um especialista sobre o rastreamento da Target.'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                              color: Color(0xFF333333), width: 1.5),
                          backgroundColor: const Color(0xFF161B22),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 26, vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.touch_app_outlined,
                            size: 20, color: Color(0xFFFF5252)),
                        label: const Text(
                          'Testar App ao Vivo',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _rolarParaSecao(_simuladorKey),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                              color: Color(0xFF2C2C2C), width: 1.2),
                          backgroundColor: const Color(0xFF1E1E1E),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.person_outline,
                            size: 20, color: Color(0xFF9E9E9E)),
                        label: const Text(
                          'Área do Cliente',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _irParaLogin,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. BARRA DE CATEGORIAS PROFISSIONAIS ---
  Widget _buildCategoriasBar(bool isDesktop) {
    final categorias = [
      {'icon': Icons.directions_car, 'nome': 'Carros Particulares'},
      {'icon': Icons.two_wheeler, 'nome': 'Motos'},
      {'icon': Icons.local_shipping, 'nome': 'Caminhões & Vans'},
      {'icon': Icons.apartment, 'nome': 'Frotas Corporativas'},
      {'icon': Icons.agriculture, 'nome': 'Máquinas & Maquinários'},
      {'icon': Icons.storefront, 'nome': 'Empresas & Logística'},
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF090B0E),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Wrap(
            spacing: isDesktop ? 36 : 18,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: categorias.map((c) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(c['icon'] as IconData,
                      color: const Color(0xFFFF5252), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    c['nome'] as String,
                    style: const TextStyle(
                      color: Color(0xFFB0BEC5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // --- 3. TRUST BAR (REALISTA E SÓLIDA) ---
  Widget _buildTrustBar(bool isDesktop) {
    final itens = [
      {
        'icon': Icons.cell_tower,
        'texto': 'Cobertura 4G em Macaé, Rio das Ostras e Região'
      },
      {'icon': Icons.fence_outlined, 'texto': 'Cercas Virtuais com Avisos no WhatsApp'},
      {'icon': Icons.description_outlined, 'texto': 'Relatórios de Km e Horímetro'},
      {'icon': Icons.lock_outline, 'texto': 'Bloqueio Remoto Antifurto'},
      {'icon': Icons.history, 'texto': 'Histórico Completo de Trajetos'},
      {
        'icon': Icons.support_agent,
        'texto': 'Suporte Humanizado (22) 99769-4019'
      },
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF11151C),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Wrap(
            spacing: isDesktop ? 32 : 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: itens.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item['icon'] as IconData,
                      color: const Color(0xFFFF5252), size: 17),
                  const SizedBox(width: 8),
                  Text(
                    item['texto'] as String,
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // --- 4. SIMULADOR INTERATIVO COM MAPA REAL DE MACAÉ / RIO DAS OSTRAS ---
  Widget _buildSecaoSimuladorInterativo(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: isDesktop ? 80 : 50,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1217),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0C0F13),
            Color(0xFF131922),
            Color(0xFF0C0F13),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              const Text(
                'EXPERIMENTE AO VIVO',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Simulador da Central Target',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Veja ruas reais de Rio das Ostras e Macaé no mapa, teste cercas virtuais, relatórios e bloqueio de motor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Seletor de Tipo de Veículo
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A212B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2C3B4E)),
                ),
                padding: const EdgeInsets.all(4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _buildBotaoTipoVeiculo(
                      tipo: 'carro',
                      icone: Icons.directions_car,
                      label: 'Carro (Toyota Corolla)',
                    ),
                    _buildBotaoTipoVeiculo(
                      tipo: 'moto',
                      icone: Icons.two_wheeler,
                      label: 'Moto (Honda CB 650R)',
                    ),
                    _buildBotaoTipoVeiculo(
                      tipo: 'frota',
                      icone: Icons.local_shipping,
                      label: 'Frota (Mercedes Accelo)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(flex: 5, child: _buildSmartphoneComMapaReal()),
                        const SizedBox(width: 48),
                        Expanded(flex: 5, child: _buildPainelControlesTeste()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildSmartphoneComMapaReal(),
                        const SizedBox(height: 36),
                        _buildPainelControlesTeste(),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoTipoVeiculo({
    required String tipo,
    required IconData icone,
    required String label,
  }) {
    final ativo = _veiculoSelecionado == tipo;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _veiculoSelecionado = tipo;
          _emMovimento = false;
          _velocidade = 0;
          _motorBloqueado = false;
          _ignicaoLigada = true;
          _timerMovimento?.cancel();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: ativo ? const Color(0xFFFF5252) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone,
                size: 18, color: ativo ? Colors.white : const Color(0xFF9E9E9E)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: ativo ? Colors.white : const Color(0xFF9E9E9E),
                fontSize: 13,
                fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SMARTPHONE INTERATIVO COM FLUTTERMAP REAL (RUAS DE RIO DAS OSTRAS & MACAÉ) ---
  Widget _buildSmartphoneComMapaReal() {
    final String nomeVeiculo;
    final String placaVeiculo;
    final String cidadeVeiculo;
    final LatLng pontoMapa;

    if (_veiculoSelecionado == 'carro') {
      nomeVeiculo = 'Toyota Corolla XEi';
      placaVeiculo = 'BRA2E19';
      cidadeVeiculo = 'Rio das Ostras - RJ';
      pontoMapa = _coordRioDasOstras;
    } else if (_veiculoSelecionado == 'moto') {
      nomeVeiculo = 'Honda CB 650R';
      placaVeiculo = 'RIO2G24';
      cidadeVeiculo = 'Macaé - RJ';
      pontoMapa = _coordMacae;
    } else {
      nomeVeiculo = 'Mercedes Accelo (Veículo 04)';
      placaVeiculo = 'TRG4F88';
      cidadeVeiculo = 'Pólo Offshore, Macaé - RJ';
      pontoMapa = _coordMacae;
    }

    final corStatus = _motorBloqueado
        ? const Color(0xFFFF5252)
        : (_emMovimento ? const Color(0xFF00E676) : const Color(0xFF1E88E5));

    final textoStatus = _motorBloqueado
        ? 'MOTOR BLOQUEADO'
        : (_emMovimento
            ? 'Em Movimento (${_velocidade.toInt()} km/h)'
            : 'Estacionado • Parking 5 d 10 h');

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _motorBloqueado
                ? const Color(0xFFFF5252)
                : const Color(0xFF334155),
            width: _motorBloqueado ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _motorBloqueado
                  ? const Color(0xFFFF5252).withValues(alpha: 0.35)
                  : Colors.black87,
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notch
            Center(
              child: Container(
                width: 90,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Topo da Central Target
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.radar, color: Color(0xFFFF5252), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'TARGET 4G LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _motorBloqueado
                        ? const Color(0xFFFF5252).withValues(alpha: 0.2)
                        : const Color(0xFF00E676).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle,
                          color: _motorBloqueado
                              ? const Color(0xFFFF5252)
                              : const Color(0xFF00E676),
                          size: 6),
                      const SizedBox(width: 4),
                      Text(
                        _motorBloqueado ? 'BLOQUEADO' : 'ONLINE',
                        style: TextStyle(
                          color: _motorBloqueado
                              ? const Color(0xFFFF5252)
                              : const Color(0xFF00E676),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ABAS INTERNAS NO SMARTPHONE (MAPA, CERCA VIRTUAL, RELATÓRIO)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF21262D)),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _buildSubAbaCelular('mapa', Icons.map_outlined, 'Mapa'),
                  _buildSubAbaCelular('cerca', Icons.fence_outlined, 'Cerca'),
                  _buildSubAbaCelular(
                      'relatorios', Icons.description_outlined, 'Relatórios'),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Card do Veículo com Placa Mercosul Genérica
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10141A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF263238)),
              ),
              child: Row(
                children: [
                  MercosulPlate(
                    plate: placaVeiculo,
                    width: 95,
                    height: 34,
                    fontSize: 13,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeVeiculo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _ignicaoLigada
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFFFF5252),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _ignicaoLigada
                                  ? 'IGNIÇÃO LIGADA'
                                  : 'IGNIÇÃO DESLIGADA',
                              style: TextStyle(
                                color: _ignicaoLigada
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFFFF5252),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          cidadeVeiculo,
                          style: const TextStyle(
                              color: Color(0xFF9E9E9E), fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: corStatus.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: corStatus, width: 0.8),
                    ),
                    child: Text(
                      _motorBloqueado
                          ? 'Corte Ativo'
                          : (_emMovimento ? 'Movimento' : 'Parking'),
                      style: TextStyle(
                        color: corStatus,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // CONTEÚDO DINÂMICO CONFORME A SUB-ABA SELECIONADA
            if (_abaSimulador == 'mapa' || _abaSimulador == 'cerca') ...[
              // MAPA REAL (OpenStreetMap CartoDB Dark Matter com ruas de Rio das Ostras e Macaé!)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    border: Border.all(color: const Color(0xFF21262D)),
                  ),
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: pontoMapa,
                          initialZoom: 15.5,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.pinchZoom |
                                InteractiveFlag.drag,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.target.rastreamento',
                            tileBuilder: darkModeTileBuilder,
                          ),

                          // SE ESTIVER NA ABA CERCA VIRTUAL: DESENHA O CÍRCULO DA CERCA SOBRE AS RUAS!
                          if (_abaSimulador == 'cerca')
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: pontoMapa,
                                  radius: 140, // raio em metros
                                  useRadiusInMeter: true,
                                  color: const Color(0xFFFF5252)
                                      .withValues(alpha: 0.22),
                                  borderColor: const Color(0xFFFF5252),
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),

                          // MARCADOR DO VEÍCULO COM ÍCONE E BADGE
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: pontoMapa,
                                width: 70,
                                height: 70,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: corStatus, width: 1),
                                      ),
                                      child: Text(
                                        placaVeiculo,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: corStatus,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: corStatus.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _veiculoSelecionado == 'moto'
                                            ? Icons.two_wheeler
                                            : Icons.directions_car,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Badge flutuante do mapa indicando rua e cidade
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2C3E50)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _abaSimulador == 'cerca'
                                    ? Icons.fence
                                    : Icons.location_on,
                                color: const Color(0xFFFF5252),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  _abaSimulador == 'cerca'
                                      ? 'Cerca Residencial: ATIVA (Raio 140m)'
                                      : 'Av. Brasília • Rio das Ostras - RJ',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // ABA RELATÓRIOS DO VEÍCULO (TELEMETRIA COMPLETA)
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF21262D)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('RESUMO DO DIA',
                              style: TextStyle(
                                  color: Color(0xFFFF5252),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                          Text('25/10/2026',
                              style: TextStyle(
                                  color: Color(0xFF9E9E9E), fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildLinhaRelatorio('Quilometragem Percorrida', '42,6 km',
                          Icons.route_outlined),
                      _buildLinhaRelatorio('Tempo em Trânsito', '1h 38 min',
                          Icons.timer_outlined),
                      _buildLinhaRelatorio('Tempo Estacionado', '6h 12 min',
                          Icons.local_parking_outlined),
                      _buildLinhaRelatorio('Velocidade Máxima', '68 km/h',
                          Icons.speed_outlined),
                      _buildLinhaRelatorio(
                          'Total de Paradas', '4 locais', Icons.pin_drop_outlined),
                      const Divider(color: Color(0xFF21262D), height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status da Cerca:',
                              style: TextStyle(
                                  color: Color(0xFF9E9E9E), fontSize: 10.5)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Sem violações',
                                style: TextStyle(
                                    color: Color(0xFF00E676),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Status Bar no Rodapé do Celular
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10141A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _motorBloqueado
                      ? const Color(0xFFFF5252)
                      : const Color(0xFF1E293B),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _motorBloqueado ? Icons.warning_amber : Icons.info_outline,
                    color: corStatus,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      textoStatus,
                      style: TextStyle(
                        color: corStatus,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Métricas Rápidas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniMetrica(Icons.speed, '${_velocidade.toInt()} km/h',
                    'Velocidade', _velocidade > 0 ? const Color(0xFF00E676) : Colors.white),
                _buildMiniMetrica(Icons.satellite_alt, '16 sats', 'Satélites',
                    const Color(0xFFFFB300)),
                _buildMiniMetrica(Icons.route,
                    '${_odometro.toStringAsFixed(2)} km', 'Odômetro', Colors.white),
                _buildMiniMetrica(Icons.battery_charging_full, '98%', 'Bateria',
                    const Color(0xFF00E676)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubAbaCelular(String chave, IconData icone, String label) {
    final ativo = _abaSimulador == chave;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _abaSimulador = chave),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: ativo ? const Color(0xFFFF5252) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone,
                  size: 13, color: ativo ? Colors.white : const Color(0xFF9E9E9E)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: ativo ? Colors.white : const Color(0xFF9E9E9E),
                  fontSize: 11,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinhaRelatorio(String rotulo, String valor, IconData icone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(icone, size: 13, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(rotulo,
                style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 11)),
          ),
          Text(valor,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- PAINEL DE CONTROLES DO SIMULADOR ---
  Widget _buildPainelControlesTeste() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COMANDOS E TELEMETRIA',
          style: TextStyle(
            color: Color(0xFFFF5252),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Controle total do seu veículo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Teste os comandos remotos abaixo e veja a resposta em tempo real no mapa e nos relatórios de telemetria:',
          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Botão 1: Bloqueio / Desbloqueio
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _motorBloqueado
                  ? const Color(0xFF00C853)
                  : const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            icon: Icon(
                _motorBloqueado ? Icons.lock_open : Icons.lock_outline,
                size: 20),
            label: Text(
              _motorBloqueado
                  ? 'DESBLOQUEAR MOTOR'
                  : 'TESTAR BLOQUEIO DE MOTOR',
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8),
            ),
            onPressed: _testarBloqueioMotor,
          ),
        ),
        const SizedBox(height: 10),

        // Botão 2: Movimento
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF334155), width: 1.5),
              backgroundColor: const Color(0xFF1E242E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(
              _emMovimento ? Icons.stop_circle_outlined : Icons.play_arrow,
              size: 20,
              color: _emMovimento
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF00E676),
            ),
            label: Text(
              _emMovimento ? 'PARAR VEÍCULO' : 'SIMULAR MOVIMENTO (ACELERAR)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            onPressed: _alternarMovimento,
          ),
        ),
        const SizedBox(height: 10),

        // Botão 3: Testar Violação de Cerca
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFFB300),
              side: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
              backgroundColor: const Color(0xFF1C1912),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.fence, size: 20),
            label: const Text(
              'TESTAR ALERTA DE CERCA VIRTUAL',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            onPressed: _simularViolacaoCerca,
          ),
        ),

        // MOCKUP DO ALERTA NO WHATSAPP
        if (_mostrarAlertaWhatsapp) ...[
          const SizedBox(height: 18),
          _buildMockupAlertaWhatsapp(),
        ],

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2C3E50)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF00E676), size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Instalação rápida em Rio das Ostras, Macaé e região. Fale com nossa central.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _abrirWhatsApp(
                    'Olá! Gostaria de agendar a instalação do rastreador Target no meu veículo.'),
                child: const Text('Agendar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- MOCKUP DO ALERTA NO WHATSAPP ---
  Widget _buildMockupAlertaWhatsapp() {
    final bool isCerca = _tipoAlertaWhatsapp == 'cerca';
    final titulo = isCerca
        ? '🚨 ALERTA: VEÍCULO SAIU DA CERCA!'
        : '🚨 ALERTA: BLOQUEIO TRANSMITIDO!';
    final detalhe = isCerca
        ? 'Veículo: Toyota Corolla (BRA2E19)\nPerímetro: Cerca Garagem\nLocal: Av. Brasília, Rio das Ostras - RJ\nHorário: Agora • Status: Fora do limite permitido'
        : 'Veículo: Toyota Corolla (BRA2E19)\nComando: Imobilização Remota de Motor\nLocal: Rio das Ostras - RJ\nStatus: Ignição Cortada com Sucesso';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B141A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF202C33)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF202C33),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Icon(Icons.chat, color: Color(0xFF25D366), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'WhatsApp • Central de Alertas Target',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text('Agora',
                    style: TextStyle(color: Color(0xFF8696A0), fontSize: 10)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF005C4B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isCerca ? Icons.fence : Icons.lock,
                          color: const Color(0xFFFFD600), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detalhe,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5252),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.lock, size: 13),
                        label: const Text('Bloquear Agora',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _testarBloqueioMotor();
                          _mostrarMensagem('Comando de Bloqueio executado!');
                        },
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.map, size: 13),
                        label: const Text('Ver no Mapa',
                            style: TextStyle(fontSize: 11)),
                        onPressed: _irParaLogin,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SEÇÃO DE DESTAQUE: CERCAS VIRTUAIS ---
  Widget _buildSecaoCercasVirtuais(bool isDesktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF10141A),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 60 : 20, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ZONAS SEGURAS & GEOFENCING',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cercas Virtuais Inteligentes',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Delimite áreas seguras no mapa (sua casa, trabalho, condomínio ou cidade) e seja avisado instantaneamente caso o veículo saia do perímetro.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 36),

              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildCardCerca(
                    titulo: 'Cerca Residencial / Garagem',
                    desc:
                        'Saiba se o veículo foi movido da sua garagem durante a noite ou fins de semana.',
                    icone: Icons.home_outlined,
                    raio: 'Raio de 100m a 300m',
                    isDesktop: isDesktop,
                  ),
                  _buildCardCerca(
                    titulo: 'Cerca de Trabalho / Galpão',
                    desc:
                        'Acompanhe a chegada e saída de funcionários ou motoristas no pátio da empresa.',
                    icone: Icons.business_outlined,
                    raio: 'Perímetro Comercial',
                    isDesktop: isDesktop,
                  ),
                  _buildCardCerca(
                    titulo: 'Cerca Municipal (Macaé & Rio das Ostras)',
                    desc:
                        'Defina limites municipais ou interestaduais para receber alerta caso o veículo saia da região.',
                    icone: Icons.map_outlined,
                    raio: 'Limite da Cidade',
                    isDesktop: isDesktop,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardCerca({
    required String titulo,
    required String desc,
    required IconData icone,
    required String raio,
    required bool isDesktop,
  }) {
    return Container(
      width: isDesktop ? 370 : double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2C3E50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: const Color(0xFFFF5252), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(desc,
              style: const TextStyle(
                  color: Color(0xFF9E9E9E), fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F141A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF263238)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.radar, size: 12, color: Color(0xFFFF5252)),
                const SizedBox(width: 6),
                Text(raio,
                    style: const TextStyle(
                        color: Color(0xFFB0BEC5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SEÇÃO DE DESTAQUE: RELATÓRIOS E TELEMETRIA ---
  Widget _buildSecaoRelatorios(bool isDesktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0C0F13),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 60 : 20, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GESTÃO, CONTROLE & HISTÓRICO',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Relatórios Detalhados de Telemetria',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tenha em mãos relatórios completos de trajetos, velocidades, paradas e horímetro. Exporte em PDF ou Excel a qualquer momento.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 36),

              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildCardRelatorio(
                    titulo: 'Histórico de Trajetos e Rotas',
                    desc:
                        'Consulte por onde o veículo passou nos últimos 90 dias, com reprodução do percurso no mapa e paradas.',
                    icone: Icons.timeline,
                    isDesktop: isDesktop,
                  ),
                  _buildCardRelatorio(
                    titulo: 'Relatório de Paradas e Endereços',
                    desc:
                        'Endereço exato de cada local onde o carro parou, horário de chegada, saída e tempo de permanência.',
                    icone: Icons.pin_drop_outlined,
                    isDesktop: isDesktop,
                  ),
                  _buildCardRelatorio(
                    titulo: 'Horímetro & Manutenção Preventiva',
                    desc:
                        'Tempo exato de motor ligado para controlar manutenções, trocas de óleo e consumo de combustível.',
                    icone: Icons.timer_outlined,
                    isDesktop: isDesktop,
                  ),
                  _buildCardRelatorio(
                    titulo: 'Controle de Velocidade',
                    desc:
                        'Avisos e gráficos de velocidade máxima e média por trecho. Ideal para disciplina de motoristas em frotas.',
                    icone: Icons.speed,
                    isDesktop: isDesktop,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardRelatorio({
    required String titulo,
    required String desc,
    required IconData icone,
    required bool isDesktop,
  }) {
    return Container(
      width: isDesktop ? 275 : double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C3E50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: const Color(0xFFFF5252), size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(desc,
              style: const TextStyle(
                  color: Color(0xFF9E9E9E), fontSize: 12.5, height: 1.35)),
        ],
      ),
    );
  }

  // --- SELOS DE AUTORIDADE & HOMOLOGAÇÃO ---
  Widget _buildSelosAutoridade(bool isDesktop) {
    final selos = [
      {
        'icone': Icons.verified,
        'titulo': 'Homologado ANATEL',
        'desc': 'Rastreadores 100% certificados pelos órgãos reguladores.',
      },
      {
        'icone': Icons.sim_card,
        'titulo': '4G Multi-Operadora',
        'desc': 'Conexão automática na melhor torre (Claro, Vivo e TIM).',
      },
      {
        'icone': Icons.shield,
        'titulo': 'Bloqueio Progressivo',
        'desc': 'Corte de ignição seguro sem risco de acidentes na via.',
      },
      {
        'icone': Icons.battery_charging_full,
        'titulo': 'Anti-Dreno de Bateria',
        'desc': 'Modo repouso inteligente: zero risco de descarregar a bateria.',
      },
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF10141A),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 60 : 20, vertical: 50),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: selos.map((s) {
              return Container(
                width: isDesktop ? 270 : double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2C3E50)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(s['icone'] as IconData,
                          color: const Color(0xFFFF5252), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['titulo'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            s['desc'] as String,
                            style: const TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 11.5,
                                height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // --- SEÇÃO: PRINCIPAIS RECURSOS ---
  Widget _buildSecaoRecursos(bool isDesktop) {
    final recursos = [
      {
        'icon': Icons.location_on_outlined,
        'titulo': 'Localização em tempo real',
        'desc': 'Precisão métrica com atualização a cada segundo.'
      },
      {
        'icon': Icons.history,
        'titulo': 'Histórico de rotas',
        'desc': 'Consulte trajetos, paradas e velocidades percorridas.'
      },
      {
        'icon': Icons.lock_outline,
        'titulo': 'Bloqueio remoto',
        'desc': 'Corte da ignição pelo celular em caso de furto ou roubo.'
      },
      {
        'icon': Icons.notifications_active_outlined,
        'titulo': 'Alertas no app e WhatsApp',
        'desc': 'Avisos imediatos de ignição ligada e cerca violada.'
      },
      {
        'icon': Icons.fence_outlined,
        'titulo': 'Cerca virtual inteligente',
        'desc': 'Defina áreas seguras e saiba se o veículo sair do local.'
      },
      {
        'icon': Icons.description_outlined,
        'titulo': 'Relatórios completos',
        'desc': 'Quilometragem percorrida, horímetro e telemetria.'
      },
      {
        'icon': Icons.phone_android,
        'titulo': 'App Android, iOS e Web',
        'desc': 'Acesse de qualquer smartphone ou computador 24h.'
      },
      {
        'icon': Icons.headset_mic_outlined,
        'titulo': 'Suporte técnico humanizado',
        'desc': 'Atendimento rápido e direto no WhatsApp (22) 99769-4019.'
      },
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF0C0F13),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 60 : 20, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TECNOLOGIA PILOT GPS',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Principais recursos',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tudo o que você precisa para acompanhar e proteger seu patrimônio.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 36),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colunas =
                      isDesktop ? 4 : (constraints.maxWidth > 650 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colunas,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: isDesktop ? 2.1 : 2.5,
                    ),
                    itemCount: recursos.length,
                    itemBuilder: (context, index) {
                      final item = recursos[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF263238)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5252)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(item['icon'] as IconData,
                                  color: const Color(0xFFFF5252), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item['titulo'] as String,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item['desc'] as String,
                                    style: const TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 11.5,
                                        height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SEÇÃO DE PLANOS COM SELETOR DE QUANTIDADE DE VEÍCULOS ---
  Widget _buildSecaoPlanosComSeletor(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 60 : 20, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PLANOS & ASSINATURAS',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Escolha como quer monitorar seu veículo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Opções para uso pessoal e frotas corporativas em Macaé e Rio das Ostras. WhatsApp (22) 99769-4019.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2C3E50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune, color: Color(0xFFFF5252), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Quantos veículos você quer proteger?',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildBotaoQtd(1, '1 Veículo (Individual)'),
                        _buildBotaoQtd(2, '2 Veículos (Casal/Família)'),
                        _buildBotaoQtd(4, '3 a 5 Veículos (Pequena Frota)'),
                        _buildBotaoQtd(10, 'Frotas Corporativas (+10 Veículos)'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colunas =
                      isDesktop ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: colunas,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 20,
                    childAspectRatio: isDesktop ? 0.65 : 0.85,
                    children: [
                      _buildCardPlano(
                        categoria: 'PARA USO PESSOAL',
                        titulo: 'Essencial',
                        preco: 'A partir de R\$ 37/mês',
                        subpreco: 'Controle prático pelo celular',
                        destaque: false,
                        beneficios: [
                          'Rastreamento em tempo real',
                          'Histórico de rotas',
                          'Cerca virtual residencial',
                          'Alertas de ignição no celular',
                          'App Android, iOS e Web',
                        ],
                        textoBotao: 'Consultar mensalidade',
                        onTap: () => _abrirWhatsApp(
                            'Olá! Gostaria de consultar o Plano Essencial da Target para $_quantidadeVeiculos veículo(s).'),
                      ),
                      _buildCardPlano(
                        categoria: 'MAIS POPULAR',
                        titulo: 'Pro',
                        preco: 'A partir de R\$ 42,00/mês',
                        subpreco: 'Mais recursos para controle total',
                        destaque: true,
                        badgeDestaque: 'MAIS POPULAR',
                        beneficios: [
                          'Tudo do Plano Essencial',
                          'Cercas virtuais ilimitadas',
                          'Relatórios avançados (PDF/Excel)',
                          'Alertas de ignição no WhatsApp',
                          'Gestão de múltiplos veículos',
                        ],
                        textoBotao: 'Contratar plano Pro',
                        onTap: () => _abrirWhatsApp(
                            'Olá! Gostaria de contratar o Plano Pro da Target para $_quantidadeVeiculos veículo(s).'),
                      ),
                      _buildCardPlano(
                        categoria: 'PARCELADO',
                        titulo: 'Flex',
                        preco: 'R\$ 59,90/mês no cartão',
                        subpreco: 'Sem taxa de adesão — rastreador incluso',
                        destaque: false,
                        beneficios: [
                          'Rastreador 4G incluso',
                          'Aplicativo Android, iOS e Web',
                          'Bloqueador remoto incluso',
                          'Instalação com suporte técnico',
                          'Contrato mínimo de 12 meses',
                        ],
                        textoBotao: 'Contratar plano Flex',
                        onTap: () => _abrirWhatsApp(
                            'Olá! Gostaria de contratar o Plano Flex com rastreador incluso para $_quantidadeVeiculos veículo(s).'),
                      ),
                      _buildCardPlano(
                        categoria: 'EMPRESARIAL & LOGÍSTICA',
                        titulo: 'Frotas',
                        preco: 'Condições especiais',
                        subpreco: 'Solução sob medida para empresas',
                        destaque: false,
                        beneficios: [
                          'Gestão unificada em 1 painel',
                          'Relatórios de paradas e horímetro',
                          'Controle de velocidade de motoristas',
                          'Atendimento comercial exclusivo',
                        ],
                        textoBotao: 'Solicitar proposta para frota',
                        onTap: () => _abrirWhatsApp(
                            'Olá! Gostaria de uma proposta corporativa para frota ($_quantidadeVeiculos veículos).'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoQtd(int qtd, String label) {
    final ativo = _quantidadeVeiculos == qtd;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _quantidadeVeiculos = qtd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ativo ? const Color(0xFFFF5252) : const Color(0xFF0F141A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: ativo ? const Color(0xFFFF5252) : const Color(0xFF263238)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ativo ? Colors.white : const Color(0xFFB0BEC5),
            fontSize: 12.5,
            fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCardPlano({
    required String categoria,
    required String titulo,
    required String preco,
    required String subpreco,
    required bool destaque,
    String? badgeDestaque,
    required List<String> beneficios,
    required String textoBotao,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: destaque ? const Color(0xFFFF5252) : const Color(0xFF263238),
          width: destaque ? 2 : 1,
        ),
        boxShadow: destaque
            ? [
                BoxShadow(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (badgeDestaque != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFFF5252),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Center(
                child: Text(
                  badgeDestaque,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoria,
                  style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(titulo,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  preco,
                  style: TextStyle(
                      color: destaque ? const Color(0xFFFF5252) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(subpreco,
                    style: const TextStyle(
                        color: Color(0xFF757575), fontSize: 11)),
                const Divider(color: Color(0xFF263238), height: 28),
                ...beneficios.map((b) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check,
                            color: Color(0xFFFF5252), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(b,
                                style: const TextStyle(
                                    color: Color(0xFFCCCCCC), fontSize: 12.5))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: destaque
                      ? const Color(0xFFFF5252)
                      : const Color(0xFF0F141A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  side: destaque
                      ? null
                      : const BorderSide(color: Color(0xFF2C3E50)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onTap,
                child: Text(textoBotao,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SEÇÃO: FAQ ---
  Widget _buildSecaoFaq(bool isDesktop) {
    final perguntas = [
      {
        'p': 'Como funciona a contratação do serviço?',
        'r':
            'Basta clicar no botão do WhatsApp e falar diretamente com nossa equipe pelo (22) 99769-4019. Agendamos a instalação rápida em Rio das Ostras, Macaé ou enviamos o rastreador configurado para você.',
      },
      {
        'p': 'O que é e como funciona a Cerca Virtual?',
        'r':
            'Você delimita perímetros no mapa (sua casa, trabalho, cidade). Se o veículo cruzar o limite delimitado fora do horário habitual, seu WhatsApp apita na hora com o aviso!',
      },
      {
        'p': 'Quais relatórios o sistema gera?',
        'r':
            'Relatórios de quilometragem percorrida, horímetro com tempo de motor ligado, histórico de trajetos com reprodução no mapa, paradas realizadas e controle de velocidade. Podem ser exportados em PDF ou Excel.',
      },
      {
        'p': 'O rastreador descarrega a bateria da moto ou carro?',
        'r':
            'Não! Nossos equipamentos possuem tecnologia inteligente de baixo consumo e bateria interna de backup, entrando em modo repouso quando a ignição está desligada.',
      },
      {
        'p': 'Como funciona o bloqueio remoto em caso de roubo?',
        'r':
            'O comando de corte pode ser acionado direto pelo aplicativo com 1 toque ou solicitando à nossa central. O corte ocorre de forma segura e progressiva.',
      },
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF11151C),
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 60 : 20, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DÚVIDAS FREQUENTES',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Perguntas Frequentes (FAQ)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 28),
              ...perguntas.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF263238)),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    iconColor: const Color(0xFFFF5252),
                    collapsedIconColor: const Color(0xFF9E9E9E),
                    title: Text(
                      item['p']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          item['r']!,
                          style: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 13,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // --- SEÇÃO: CTA FINAL ---
  Widget _buildSecaoCtaFinal() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0C0F13),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Icon(Icons.shield_outlined,
                  color: Color(0xFFFF5252), size: 44),
              const SizedBox(height: 16),
              const Text(
                'Proteja seu veículo com tecnologia de verdade',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Fale com nossos especialistas agora pelo WhatsApp (22) 99769-4019 e ative o rastreamento 4G com cercas virtuais e relatórios.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.chat, size: 20),
                    label: const Text('Falar no WhatsApp: (22) 99769-4019',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _abrirWhatsApp(
                        'Olá! Gostaria de contratar a proteção veicular da Target.'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFF5252)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.login,
                        size: 20, color: Color(0xFFFF5252)),
                    label: const Text('Área do Cliente (Login)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _irParaLogin,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FOOTER INSTITUCIONAL ---
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF07090C),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              const TargetLogo(iconSize: 40),
              const SizedBox(height: 14),
              const Text(
                'Target Rastreamento Veicular • Macaé & Rio das Ostras - RJ • WhatsApp: (22) 99769-4019',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                '© 2026 Target Rastreamento. Todos os direitos reservados.',
                style: TextStyle(color: Color(0xFF555555), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToastProvaSocial() {
    final notif = _notificacoesSociais[_indiceNotificacaoAtual];
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E242E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(notif['icone']!, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notif['cidade']!,
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      notif['tempo']!,
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  notif['veiculo']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  notif['acao']!,
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetrica(
      IconData icon, String valor, String rotulo, Color cor) {
    return Column(
      children: [
        Icon(icon, size: 16, color: cor),
        const SizedBox(height: 2),
        Text(valor,
            style: TextStyle(
                color: cor, fontSize: 11, fontWeight: FontWeight.bold)),
        Text(rotulo,
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 9.5)),
      ],
    );
  }

  Widget _buildNavLink(String texto, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          texto,
          style: const TextStyle(
            color: Color(0xFFCCCCCC),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// PAINTER DO RADAR MILITAR HOLOGRÁFICO
class _RadarMilitarPainter extends CustomPainter {
  final double progress;

  _RadarMilitarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.45;

    final circlePaint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), circlePaint);
    }

    final crossPaint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy),
        Offset(center.dx + maxRadius, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius),
        Offset(center.dx, center.dy + maxRadius), crossPaint);

    final sweepAngle = progress * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          Colors.transparent,
          const Color(0xFFFF5252).withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: maxRadius),
      0,
      math.pi / 2,
      true,
      sweepPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarMilitarPainter oldDelegate) => true;
}
