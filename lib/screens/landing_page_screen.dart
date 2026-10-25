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

class _LandingPageScreenState extends State<LandingPageScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _planosKey = GlobalKey();
  final GlobalKey _recursosKey = GlobalKey();
  final GlobalKey _comoFuncionaKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  // WhatsApp oficial da Target
  static const String _whatsappNumero = '5522997694019';

  Future<void> _abrirWhatsApp([String mensagem = 'Olá! Gostaria de mais informações sobre o rastreamento veicular da Target.']) async {
    final uri = Uri.parse('https://wa.me/$_whatsappNumero?text=${Uri.encodeComponent(mensagem)}');
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
      backgroundColor: const Color(0xFF0F1216), // Fundo escuro tecnológico
      // Botão Flutuante do WhatsApp
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF25D366), // Verde WhatsApp
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.chat, size: 22),
        label: const Text(
          'WhatsApp (22) 99769-4019',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        onPressed: () => _abrirWhatsApp('Olá! Gostaria de falar com um especialista sobre o rastreamento Target.'),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. NAVBAR RESPONSIVA COM EFEITO BLUR E DESIGN PREMIUM
          SliverAppBar(
            backgroundColor: const Color(0xFF0F1216).withValues(alpha: 0.95),
            floating: true,
            pinned: true,
            elevation: 2,
            toolbarHeight: 70,
            titleSpacing: isDesktop ? 40 : 16,
            title: Row(
              children: [
                // Logo Target Compacta
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
                  _buildNavLink('Início', () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut)),
                  _buildNavLink('Como Funciona', () => _rolarParaSecao(_comoFuncionaKey)),
                  _buildNavLink('Recursos', () => _rolarParaSecao(_recursosKey)),
                  _buildNavLink('Planos', () => _rolarParaSecao(_planosKey)),
                  _buildNavLink('FAQ', () => _rolarParaSecao(_faqKey)),
                  const SizedBox(width: 16),
                ],

                // Botão "Login" com estilo moderno e destaque
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFFF5252), width: 1.2),
                    backgroundColor: const Color(0xFF1E1E1E),
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 18 : 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.login, size: 16, color: Color(0xFFFF5252)),
                  label: Text(
                    isDesktop ? 'Área do Cliente' : 'Login',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _irParaLogin,
                ),

                const SizedBox(width: 10),

                // Botão Falar no Zap
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text(
                      'Falar no WhatsApp',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _abrirWhatsApp('Olá! Quero falar com um especialista sobre o rastreamento da Target.'),
                  ),
              ],
            ),
          ),

          // 2. CONTEÚDO PRINCIPAL (SEÇÕES DO SITE)
          SliverToBoxAdapter(
            child: Column(
              children: [
                // HERO SECTION (Inspirado no Shield Track & Trackplus)
                _buildHeroSection(isDesktop, isTablet),

                // BARRA DE CATEGORIAS RÁPIDAS (Carros, Motos, Lanchas, etc.)
                _buildCategoriasBar(isDesktop),

                // TRUST BAR (MÉTRICAS & DESTAQUES)
                _buildTrustBar(isDesktop),

                // SEÇÃO: COMO FUNCIONA & SHOWCASE INTERATIVO
                Container(
                  key: _comoFuncionaKey,
                  child: _buildSecaoComoFunciona(isDesktop),
                ),

                // SEÇÃO: PRINCIPAIS RECURSOS
                Container(
                  key: _recursosKey,
                  child: _buildSecaoRecursos(isDesktop),
                ),

                // SEÇÃO: PLANOS & PREÇOS
                Container(
                  key: _planosKey,
                  child: _buildSecaoPlanos(isDesktop),
                ),

                // SEÇÃO: FAQ (DÚVIDAS FREQUENTES)
                Container(
                  key: _faqKey,
                  child: _buildSecaoFaq(isDesktop),
                ),

                // SEÇÃO: CTA FINAL
                _buildSecaoCtaFinal(),

                // FOOTER INSTITUCIONAL
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. HERO SECTION (BANNER TECNOLÓGICO) ---
  Widget _buildHeroSection(bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: isDesktop ? 70 : 45,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1216),
        // Efeito de iluminação suave azul/vermelho tecnológico
        gradient: RadialGradient(
          center: Alignment(0.3, -0.6),
          radius: 1.3,
          colors: [
            Color(0x28FF5252), // Vermelho Target luminoso
            Color(0xFF0F1216),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge Tecnológica Superior (Estilo Shield Track)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E242E).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2C3E50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB300), // Ponto âmbar brilhante
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0xFFFFB300), blurRadius: 6, spreadRadius: 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tecnologia de Ponta em Rastreamento',
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

              // Headline de Alto Impacto
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 44,
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
                        color: Color(0xFFFF5252), // Vermelho Target Vibrante
                        shadows: [
                          Shadow(color: Color(0x66FF5252), blurRadius: 20),
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
                  'Rastreamento veicular e náutico via satélite, com acesso 24h pelo celular ou computador. Tenha tranquilidade onde quer que você esteja.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Dois Botões Centrais (Conforme o Shield Track)
              Wrap(
                spacing: 16,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  // Botão Primário: Falar com um Especialista (WhatsApp)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5252), // Vermelho Target
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 6,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Text(
                      'Falar com um Especialista',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    onPressed: () => _abrirWhatsApp('Olá! Gostaria de falar com um especialista sobre o rastreamento da Target.'),
                  ),

                  // Botão Secundário: Como Funciona
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF333333), width: 1.5),
                      backgroundColor: const Color(0xFF161B22),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.play_circle_outline, size: 20, color: Color(0xFFFF5252)),
                    label: const Text(
                      'Como Funciona',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _rolarParaSecao(_comoFuncionaKey),
                  ),

                  // Botão Área do Cliente
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF2C2C2C), width: 1.2),
                      backgroundColor: const Color(0xFF1E1E1E),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF9E9E9E)),
                    label: const Text(
                      'Área do Cliente',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
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

  // --- 2. BARRA DE CATEGORIAS RÁPIDAS (Estilo Shield Track) ---
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
      color: const Color(0xFF0C0F13),
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
                  Icon(c['icon'] as IconData, color: const Color(0xFFFF5252), size: 19),
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

  // --- 3. TRUST BAR (MÉTRICAS & CONFIANÇA) ---
  Widget _buildTrustBar(bool isDesktop) {
    final itens = [
      {'icon': Icons.verified_user_outlined, 'texto': '+5.000 veículos monitorados'},
      {'icon': Icons.cell_tower, 'texto': 'Tecnologia 4G Multi-Operadora'},
      {'icon': Icons.devices, 'texto': 'Acesso Web, Android e iPhone'},
      {'icon': Icons.lock_outline, 'texto': 'Bloqueio remoto antifurto'},
      {'icon': Icons.history, 'texto': 'Histórico de rotas 24/7'},
      {'icon': Icons.support_agent, 'texto': 'Suporte via WhatsApp (22) 99769-4019'},
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF14181F),
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
                  Icon(item['icon'] as IconData, color: const Color(0xFFFF5252), size: 17),
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

  // --- 4. SEÇÃO: COMO FUNCIONA & SHOWCASE INTERATIVO ---
  Widget _buildSecaoComoFunciona(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COMO FUNCIONA',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Simples, Rápido e Seguro',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Veja como funciona o monitoramento em tempo real da Target.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 36),

              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildPassosFuncionamento()),
                        const SizedBox(width: 40),
                        Expanded(child: _buildMockupVisual()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildPassosFuncionamento(),
                        const SizedBox(height: 36),
                        _buildMockupVisual(),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassosFuncionamento() {
    final passos = [
      {
        'num': '01',
        'titulo': 'Instalação Rápida e Discreta',
        'desc': 'Rastreador ultracompacto 4G instalado em local seguro do veículo ou embarcação com consumo mínimo de bateria.',
      },
      {
        'num': '02',
        'titulo': 'Transmissão em Tempo Real',
        'desc': 'O dispositivo envia coordenadas métricas, velocidade, ignição e satélites a cada segundo para nossos servidores Pilot GPS.',
      },
      {
        'num': '03',
        'titulo': 'Acesso Total pelo Celular ou PC',
        'desc': 'Você acompanha a rota ao vivo, recebe alertas no WhatsApp e pode enviar comandos de bloqueio remoto a qualquer momento.',
      },
    ];

    return Column(
      children: passos.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF5252)),
                ),
                alignment: Alignment.center,
                child: Text(
                  p['num']!,
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['titulo']!,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p['desc']!,
                      style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMockupVisual() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.radar, color: Color(0xFFFF5252), size: 18),
                  SizedBox(width: 6),
                  Text('MONITORAMENTO ATIVO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xFF00E676), size: 6),
                    SizedBox(width: 4),
                    Text('AO VIVO', style: TextStyle(color: Color(0xFF00E676), fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2C2C2C)),
            ),
            child: const Row(
              children: [
                MercosulPlate(plate: 'MQA6E92', width: 95, height: 34, fontSize: 13),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Carro de Mamãe', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('Rio das Ostras - RJ', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Container(
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF21262D)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: CustomPaint(painter: _GridMapPainter())),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFFFF5252), shape: BoxShape.circle),
                      child: const Icon(Icons.directions_car, color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 4),
                    const Text('-22.504771, -41.920289', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontFamily: 'monospace')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. SEÇÃO: PRINCIPAIS RECURSOS ---
  Widget _buildSecaoRecursos(bool isDesktop) {
    final recursos = [
      {'icon': Icons.location_on_outlined, 'titulo': 'Localização em tempo real', 'desc': 'Precisão métrica com atualização rápida.'},
      {'icon': Icons.history, 'titulo': 'Histórico de rotas', 'desc': 'Consulte trajetos, paradas e velocidades.'},
      {'icon': Icons.lock_outline, 'titulo': 'Bloqueio remoto', 'desc': 'Corte da ignição pelo celular em segundos.'},
      {'icon': Icons.notifications_active_outlined, 'titulo': 'Alertas no app e WhatsApp', 'desc': 'Avisos imediatos de ignição ligada e cerca.'},
      {'icon': Icons.fence_outlined, 'titulo': 'Cerca virtual inteligente', 'desc': 'Defina áreas seguras e receba notificações.'},
      {'icon': Icons.description_outlined, 'titulo': 'Relatórios completos', 'desc': 'Quilometragem, horímetro e telemetria.'},
      {'icon': Icons.phone_android, 'titulo': 'App Android, iOS e Web', 'desc': 'Acesse de qualquer smartphone ou computador.'},
      {'icon': Icons.headset_mic_outlined, 'titulo': 'Suporte 24h especializado', 'desc': 'Atendimento rápido e direto no WhatsApp.'},
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF14181F),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20, vertical: 70),
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
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tudo o que você precisa para acompanhar e proteger seu patrimônio.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 36),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colunas = isDesktop ? 4 : (constraints.maxWidth > 650 ? 2 : 1);
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
                          color: const Color(0xFF1E222A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF2C323D)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(item['icon'] as IconData, color: const Color(0xFFFF5252), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item['titulo'] as String,
                                    style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item['desc'] as String,
                                    style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11.5, height: 1.3),
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

  // --- 6. SEÇÃO: PLANOS & PREÇOS (COM NÚMERO OFICIAL DO WHATSAPP) ---
  Widget _buildSecaoPlanos(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20, vertical: 80),
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
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Opções para uso pessoal, embarcações e frotas corporativas. Fale com a gente pelo WhatsApp (22) 99769-4019.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 44),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colunas = isDesktop ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
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
                        onTap: () => _abrirWhatsApp('Olá! Gostaria de consultar o Plano Essencial da Target (R\$ 37/mês).'),
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
                          'Ideal para uso comercial',
                        ],
                        textoBotao: 'Contratar plano Pro',
                        onTap: () => _abrirWhatsApp('Olá! Gostaria de contratar o Plano Pro da Target (R\$ 42,00/mês).'),
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
                        onTap: () => _abrirWhatsApp('Olá! Gostaria de contratar o Plano Flex com rastreador incluso (R\$ 59,90/mês).'),
                      ),
                      _buildCardPlano(
                        categoria: 'EMPRESARIAL & NÁUTICO',
                        titulo: 'Frotas & Barcos',
                        preco: 'Condições especiais',
                        subpreco: 'Solução sob medida para empresas',
                        destaque: false,
                        beneficios: [
                          'Gestão completa de frota',
                          'Monitoramento de embarcações',
                          'Relatórios gerenciais customizados',
                          'Atendimento exclusivo via WhatsApp',
                        ],
                        textoBotao: 'Solicitar proposta comercial',
                        onTap: () => _abrirWhatsApp('Olá! Gostaria de uma proposta corporativa para frota/embarcação com a Target.'),
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
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: destaque ? const Color(0xFFFF5252) : const Color(0xFF2C2C2C),
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
                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2),
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
                  style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  preco,
                  style: TextStyle(color: destaque ? const Color(0xFFFF5252) : Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(subpreco, style: const TextStyle(color: Color(0xFF757575), fontSize: 11)),
                const Divider(color: Color(0xFF2C2C2C), height: 28),
                ...beneficios.map((b) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check, color: Color(0xFFFF5252), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(b, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12.5))),
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
                  backgroundColor: destaque ? const Color(0xFFFF5252) : const Color(0xFF121212),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  side: destaque ? null : const BorderSide(color: Color(0xFF333333)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onTap,
                child: Text(textoBotao, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 7. SEÇÃO: FAQ (DÚVIDAS FREQUENTES) ---
  Widget _buildSecaoFaq(bool isDesktop) {
    final perguntas = [
      {
        'p': 'Como funciona a contratação do serviço?',
        'r': 'Basta clicar no botão do WhatsApp e falar diretamente com nossa equipe pelo (22) 99769-4019. Agendamos a instalação ou enviamos o rastreador já configurado para o seu endereço.',
      },
      {
        'p': 'O rastreador descarrega a bateria do meu veículo ou barco?',
        'r': 'Não! Nossos equipamentos possuem tecnologia inteligente de baixo consumo e bateria interna de backup, entrando em modo sleep quando a ignição está desligada.',
      },
      {
        'p': 'Posso acompanhar pelo computador e pelo celular ao mesmo tempo?',
        'r': 'Sim! A Target disponibiliza acesso ilimitado via Web para computadores e aplicativo compatível com Android e iOS.',
      },
      {
        'p': 'O bloqueio do motor realmente funciona?',
        'r': 'Sim. O corte da ignição é acionado remotamente pelo aplicativo ou central com total segurança na próxima desaceleração do veículo.',
      },
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF14181F),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20, vertical: 70),
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
                style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 28),
              ...perguntas.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E222A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2C323D)),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    iconColor: const Color(0xFFFF5252),
                    collapsedIconColor: const Color(0xFF9E9E9E),
                    title: Text(
                      item['p']!,
                      style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          item['r']!,
                          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13, height: 1.4),
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

  // --- 8. SEÇÃO: CTA FINAL ---
  Widget _buildSecaoCtaFinal() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F1216),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFFF5252), size: 44),
              const SizedBox(height: 16),
              const Text(
                'Proteja seu veículo ou embarcação hoje mesmo',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.chat, size: 20),
                    label: const Text('Falar no WhatsApp: (22) 99769-4019', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _abrirWhatsApp('Olá! Gostaria de contratar a proteção veicular da Target.'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFF5252)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.login, size: 20, color: Color(0xFFFF5252)),
                    label: const Text('Área do Cliente (Login)', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // --- 9. FOOTER INSTITUCIONAL ---
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0A0D10),
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
                style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 12.5, fontWeight: FontWeight.w600),
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
