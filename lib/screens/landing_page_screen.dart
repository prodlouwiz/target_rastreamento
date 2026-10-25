import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
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
  final GlobalKey _simuladorKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  // WhatsApp oficial da Target
  static const String _whatsappNumero = '5522997694019';

  // --- ANIMAÇÃO DO RADAR HOLOGRÁFICO ---
  late AnimationController _radarController;

  // --- ESTADO DO SIMULADOR INTERATIVO DO APP ---
  String _veiculoSelecionado = 'carro'; // 'carro', 'moto', 'lancha'
  bool _ignicaoLigada = true;
  bool _motorBloqueado = false;
  bool _emMovimento = false;
  double _velocidade = 0;
  double _odometro = 25.61;
  bool _mostrarAlertaWhatsapp = false;
  Timer? _timerMovimento;

  // --- PROVA SOCIAL DINÂMICA (TOASTS AO VIVO) ---
  final List<Map<String, String>> _notificacoesSociais = [
    {
      'icone': '🚗',
      'cidade': 'Rio das Ostras - RJ',
      'veiculo': 'Toyota Corolla 2024',
      'acao': 'Rastreador 4G ativado',
      'tempo': 'há 3 minutos',
    },
    {
      'icone': '🏍️',
      'cidade': 'Macaé - RJ',
      'veiculo': 'Honda CB 650R',
      'acao': 'Bloqueio remoto testado com sucesso',
      'tempo': 'há 9 minutos',
    },
    {
      'icone': '🚤',
      'cidade': 'Búzios - RJ',
      'veiculo': 'Lancha Real 32',
      'acao': 'Embarcação conectada via satélite',
      'tempo': 'há 18 minutos',
    },
    {
      'icone': '🚙',
      'cidade': 'Cabo Frio - RJ',
      'veiculo': 'Jeep Compass',
      'acao': 'Cerca virtual ativada',
      'tempo': 'há 24 minutos',
    },
    {
      'icone': '🚚',
      'cidade': 'Campos dos Goytacazes - RJ',
      'veiculo': 'Caminhão Mercedes Accelo',
      'acao': 'Frota corporativa conectada',
      'tempo': 'há 32 minutos',
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

    // Inicia radar rotativo contínuo
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Inicia ciclo de prova social dinâmica (toasts)
    _iniciarCicloProvaSocial();
  }

  void _iniciarCicloProvaSocial() {
    _timerToast = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (!mounted) return;
      setState(() {
        _toastVisivel = true;
      });

      // Esconde após 5 segundos
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
              'Não é possível acelerar com o motor bloqueado! Desbloqueie primeiro.',
              isAlerta: true);
          return;
        }
        _emMovimento = true;
        _ignicaoLigada = true;
        _timerMovimento?.cancel();
        _timerMovimento =
            Timer.periodic(const Duration(milliseconds: 100), (t) {
          if (!mounted || !_emMovimento) {
            t.cancel();
            return;
          }
          setState(() {
            if (_velocidade < 64) {
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
        _mostrarAlertaWhatsapp = true;
      }
    });
  }

  void _simularAlertaWhatsapp() {
    setState(() {
      _mostrarAlertaWhatsapp = !_mostrarAlertaWhatsapp;
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
      // Botão Flutuante do WhatsApp
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
          // CONTEÚDO SCROLLÁVEL DO SITE
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. NAVBAR RESPONSIVA COM EFEITO BLUR E DESIGN PREMIUM
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

                    // Links Centrais de Navegação (Desktop)
                    if (isDesktop) ...[
                      _buildNavLink(
                          'Início',
                          () => _scrollController.animateTo(0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut)),
                      _buildNavLink('Demonstração',
                          () => _rolarParaSecao(_simuladorKey)),
                      _buildNavLink('Recursos',
                          () => _rolarParaSecao(_recursosKey)),
                      _buildNavLink(
                          'Planos', () => _rolarParaSecao(_planosKey)),
                      _buildNavLink('FAQ', () => _rolarParaSecao(_faqKey)),
                      const SizedBox(width: 16),
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
                    // HERO SECTION COM RADAR HOLOGRÁFICO ANIMADO
                    _buildHeroSectionComRadar(isDesktop),

                    // BARRA DE CATEGORIAS RÁPIDAS
                    _buildCategoriasBar(isDesktop),

                    // TRUST BAR
                    _buildTrustBar(isDesktop),

                    // SIMULADOR INTERATIVO DO APP (SUPER FRUFRU & ATRAÇÃO)
                    Container(
                      key: _simuladorKey,
                      child: _buildSecaoSimuladorInterativo(isDesktop),
                    ),

                    // SELOS DE AUTORIDADE & HOMOLOGAÇÃO
                    _buildSelosAutoridade(isDesktop),

                    // SEÇÃO: PRINCIPAIS RECURSOS
                    Container(
                      key: _recursosKey,
                      child: _buildSecaoRecursos(isDesktop),
                    ),

                    // SIMULADOR DE VEÍCULOS / FROTAS + TABELA DE PLANOS
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

          // 3. TOAST FLUTUANTE DE PROVA SOCIAL DINÂMICA (CANTO INFERIOR ESQUERDO)
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

  // --- 1. HERO SECTION COM RADAR HOLOGRÁFICO ANIMADO ---
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
            Color(0x33FF5252), // Vermelho Target
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
              // Fundo: Radar Militar Animado
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

              // Conteúdo em Primeiro Plano
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Badge Superior (Tecnologia de Ponta)
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

                  // Headline
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
                        TextSpan(text: ' para seu\nVeículo ou Embarcação'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Subtítulo
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: const Text(
                      'Rastreamento veicular e náutico via satélite, com acesso 24h pelo celular ou computador. Alertas de ignição no WhatsApp e bloqueio remoto instantâneo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Botões de Ação
                  Wrap(
                    spacing: 16,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: [
                      // Botão Falar no WhatsApp
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

                      // Botão Testar Simulador
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

                      // Botão Login
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

  // --- 2. BARRA DE CATEGORIAS RÁPIDAS ---
  Widget _buildCategoriasBar(bool isDesktop) {
    final categorias = [
      {'icon': Icons.directions_car, 'nome': 'Carros'},
      {'icon': Icons.two_wheeler, 'nome': 'Motos'},
      {'icon': Icons.agriculture, 'nome': 'Quadriciclos'},
      {'icon': Icons.directions_boat, 'nome': 'Lanchas'},
      {'icon': Icons.waves, 'nome': 'Jet Skis'},
      {'icon': Icons.local_shipping, 'nome': 'Caminhões e Frotas'},
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF090B0E),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Wrap(
            spacing: isDesktop ? 40 : 20,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: categorias.map((c) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(c['icon'] as IconData,
                      color: const Color(0xFFFF5252), size: 19),
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

  // --- 3. TRUST BAR (MÉTRICAS) ---
  Widget _buildTrustBar(bool isDesktop) {
    final itens = [
      {
        'icon': Icons.verified_user_outlined,
        'texto': '+5.000 veículos monitorados'
      },
      {'icon': Icons.cell_tower, 'texto': 'Tecnologia 4G Multi-Operadora'},
      {'icon': Icons.devices, 'texto': 'Acesso Web, Android e iPhone'},
      {'icon': Icons.lock_outline, 'texto': 'Bloqueio remoto antifurto'},
      {'icon': Icons.history, 'texto': 'Histórico de rotas 24/7'},
      {
        'icon': Icons.support_agent,
        'texto': 'Suporte via WhatsApp (22) 99769-4019'
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

  // --- 4. SIMULADOR INTERATIVO DO APP (SUPER DESTAQUE!) ---
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
              // Cabeçalho da Seção
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
                'Clique nos botões abaixo para testar o bloqueio de motor, aceleração e alertas no WhatsApp em tempo real.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 36),

              // Seletor de Tipo de Veículo (Carro, Moto, Lancha)
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
                      label: 'Carro (MQA-6E92)',
                    ),
                    _buildBotaoTipoVeiculo(
                      tipo: 'moto',
                      icone: Icons.two_wheeler,
                      label: 'Moto (CB 650R)',
                    ),
                    _buildBotaoTipoVeiculo(
                      tipo: 'lancha',
                      icone: Icons.directions_boat,
                      label: 'Lancha (Real 32)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Layout Principal: Smartphone Interativo + Controles
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Smartphone Interativo
                        Expanded(flex: 5, child: _buildSmartphoneInterativo()),
                        const SizedBox(width: 48),
                        // Painel de Testes & Botões Interativos
                        Expanded(flex: 5, child: _buildPainelControlesTeste()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildSmartphoneInterativo(),
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
            Icon(icone, size: 18, color: ativo ? Colors.white : const Color(0xFF9E9E9E)),
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

  // --- SMARTPHONE INTERATIVO COM SIMULAÇÃO AO VIVO ---
  Widget _buildSmartphoneInterativo() {
    final String nomeVeiculo;
    final String placaVeiculo;
    final String cidadeVeiculo;

    if (_veiculoSelecionado == 'carro') {
      nomeVeiculo = 'Carro de Mamãe';
      placaVeiculo = 'MQA6E92';
      cidadeVeiculo = 'Rio das Ostras - RJ';
    } else if (_veiculoSelecionado == 'moto') {
      nomeVeiculo = 'Honda CB 650R';
      placaVeiculo = 'RIO2G24';
      cidadeVeiculo = 'Macaé - RJ';
    } else {
      nomeVeiculo = 'Lancha Real 32';
      placaVeiculo = 'BR-BUZ32';
      cidadeVeiculo = 'Marina Porto Búzios - RJ';
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
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1E24),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _motorBloqueado ? const Color(0xFFFF5252) : const Color(0xFF334155),
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
            // Notch / Topo do Celular
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

            // Cabeçalho da Central
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
            const SizedBox(height: 14),

            // Card do Veículo com Placa Mercosul
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10141A),
                borderRadius: BorderRadius.circular(16),
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
                            fontSize: 13.5,
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
            const SizedBox(height: 12),

            // Minimapa Interativo com Radar Tecnológico
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF090D12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Grade do Mapa
                  Positioned.fill(
                      child: CustomPaint(painter: _GridMapPainter())),

                  // Trajeto desenhado quando em movimento
                  if (_emMovimento)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RotaSimuladaPainter(),
                      ),
                    ),

                  // Ícone do Veículo com Pulso e Rotação
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _motorBloqueado
                              ? const Color(0xFFFF5252).withValues(alpha: 0.3)
                              : corStatus.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: corStatus,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _veiculoSelecionado == 'moto'
                                ? Icons.two_wheeler
                                : (_veiculoSelecionado == 'lancha'
                                    ? Icons.directions_boat
                                    : Icons.directions_car),
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _motorBloqueado
                              ? 'IGNIÇÃO CORTADA'
                              : (_emMovimento
                                  ? '${_velocidade.toInt()} km/h'
                                  : '-22.504771, -41.920289'),
                          style: TextStyle(
                            color: _motorBloqueado
                                ? const Color(0xFFFF5252)
                                : Colors.white70,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

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

  // --- PAINEL DE CONTROLES DO SIMULADOR (BOTÕES DE TESTE AO VIVO) ---
  Widget _buildPainelControlesTeste() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TESTE OS COMANDOS REMOTOS',
          style: TextStyle(
            color: Color(0xFFFF5252),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Controle total na palma da sua mão',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Experimente como funciona o comando de bloqueio e como você recebe os alertas caso alguém ligue o seu veículo:',
          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 24),

        // Botão 1: Testar Bloqueio / Desbloqueio
        SizedBox(
          width: double.infinity,
          height: 54,
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8),
            ),
            onPressed: _testarBloqueioMotor,
          ),
        ),
        const SizedBox(height: 12),

        // Botão 2: Simular Movimento / Aceleração
        SizedBox(
          width: double.infinity,
          height: 52,
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
              size: 22,
              color: _emMovimento
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF00E676),
            ),
            label: Text(
              _emMovimento ? 'PARAR VEÍCULO' : 'SIMULAR MOVIMENTO (ACELERAR)',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
            onPressed: _alternarMovimento,
          ),
        ),
        const SizedBox(height: 12),

        // Botão 3: Ver Notificação no WhatsApp
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
              side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
              backgroundColor: const Color(0xFF131F18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.chat_outlined, size: 20),
            label: Text(
              _mostrarAlertaWhatsapp
                  ? 'OCULTAR ALERTA DO WHATSAPP'
                  : 'VER ALERTA NO WHATSAPP (MOCKUP)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            onPressed: _simularAlertaWhatsapp,
          ),
        ),

        // MOCKUP REALISTA DO ALERTA NO WHATSAPP (QUANDO ATIVADO)
        if (_mostrarAlertaWhatsapp) ...[
          const SizedBox(height: 20),
          _buildMockupAlertaWhatsapp(),
        ],

        const SizedBox(height: 20),

        // CTA para Contratar pelo WhatsApp
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
                  'Pronto para proteger seu veículo? Fale agora com nossa central no WhatsApp.',
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
                    'Olá! Testei o simulador no site da Target e quero contratar para meu veículo.'),
                child: const Text('Contratar',
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B141A), // Fundo WhatsApp Dark
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF202C33)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho WhatsApp
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

          // Corpo da Mensagem
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF005C4B), // Verde do balão enviado WhatsApp
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Color(0xFFFFD600), size: 16),
                      SizedBox(width: 6),
                      Text(
                        '🚨 ALERTA: IGNIÇÃO ACIONADA!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Veículo: Carro de Mamãe (MQA-6E92)\nLocal: Av. Brasília, Rio das Ostras - RJ\nHorário: 19:48:12\nVelocidade: 0 km/h',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5252),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.lock, size: 14),
                        label: const Text('Bloquear Motor',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _testarBloqueioMotor();
                          _mostrarMensagem(
                              'Comando de BLOQUEIO enviado com sucesso!');
                        },
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.map, size: 14),
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

  // --- 5. SELOS DE AUTORIDADE & HOMOLOGAÇÃO ---
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
        'desc': 'Corte de ignição seguro sem risco de acidentes na pista.',
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

  // --- 6. SEÇÃO: PRINCIPAIS RECURSOS ---
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

  // --- 7. SEÇÃO DE PLANOS COM SELETOR DE QUANTIDADE DE VEÍCULOS ---
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
                'Opções para uso pessoal, embarcações e frotas corporativas. Fale com a gente pelo WhatsApp (22) 99769-4019.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 28),

              // SELETOR RÁPIDO DE QUANTIDADE DE VEÍCULOS (FRUTINHA INTERATIVA)
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
                        _buildBotaoQtd(4, '3 a 5 Veículos (Família/Comércio)'),
                        _buildBotaoQtd(10, 'Frotas (+10 Veículos)'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Grade de 4 Planos
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
                          'Alertas básicos de ignição',
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
                          'Acesso à plataforma Target PRO',
                          'Relatórios avançados',
                          'Gestão de múltiplos veículos',
                          'Alertas no WhatsApp 24h',
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
                          'Instalação por conta do cliente',
                          'Contrato mínimo de 12 meses',
                        ],
                        textoBotao: 'Contratar plano Flex',
                        onTap: () => _abrirWhatsApp(
                            'Olá! Gostaria de contratar o Plano Flex com rastreador incluso para $_quantidadeVeiculos veículo(s).'),
                      ),
                      _buildCardPlano(
                        categoria: 'EMPRESARIAL & NÁUTICO',
                        titulo: 'Frotas & Barcos',
                        preco: 'Condições especiais',
                        subpreco: 'Solução sob medida para empresas',
                        destaque: false,
                        beneficios: [
                          'Gestão unificada em 1 painel',
                          'Monitoramento náutico via satélite',
                          'Relatórios gerenciais customizados',
                          'Atendimento exclusivo via WhatsApp',
                        ],
                        textoBotao: 'Solicitar proposta comercial',
                        onTap: () => _abrirWhatsApp(
                            'Olá! Gostaria de uma proposta corporativa para frota/embarcação ($_quantidadeVeiculos veículos).'),
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

  // --- 8. SEÇÃO: FAQ ---
  Widget _buildSecaoFaq(bool isDesktop) {
    final perguntas = [
      {
        'p': 'Como funciona a contratação do serviço?',
        'r':
            'Basta clicar no botão do WhatsApp e falar diretamente com nossa equipe pelo (22) 99769-4019. Agendamos a instalação ou enviamos o rastreador já configurado para o seu endereço.',
      },
      {
        'p': 'O rastreador descarrega a bateria do meu veículo ou barco?',
        'r':
            'Não! Nossos equipamentos possuem tecnologia inteligente de baixo consumo e bateria interna de backup, entrando em modo repouso quando a ignição está desligada.',
      },
      {
        'p': 'Posso acompanhar pelo computador e pelo celular ao mesmo tempo?',
        'r':
            'Sim! A Target disponibiliza acesso ilimitado via Web para computadores e aplicativo compatível com Android e iOS.',
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

  // --- 9. SEÇÃO: CTA FINAL ---
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
                'Proteja seu veículo ou embarcação hoje mesmo',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Fale com nossos especialistas agora pelo WhatsApp (22) 99769-4019 e ative sua segurança 24h.',
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

  // --- 10. FOOTER INSTITUCIONAL ---
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
                'Target Rastreamento Veicular & Náutico • WhatsApp: (22) 99769-4019',
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

  // --- WIDGET DO TOAST DE PROVA SOCIAL DINÂMICA ---
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

// --- PAINTER DO RADAR MILITAR HOLOGRÁFICO ANIMADO ---
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

    // Círculos concêntricos do radar
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), circlePaint);
    }

    // Linhas de Mira Eixo X e Y
    final crossPaint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy),
        Offset(center.dx + maxRadius, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius),
        Offset(center.dx, center.dy + maxRadius), crossPaint);

    // Feixe rotativo de varredura (Sweep Gradient)
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

// Painter para grade do mapa
class _GridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2633)
      ..strokeWidth = 0.8;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter de traçado de rota simulada
class _RotaSimuladaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.5,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
