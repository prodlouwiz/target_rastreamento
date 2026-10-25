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
  final GlobalKey _sobreKey = GlobalKey();

  // WhatsApp oficial da Target para contratação e suporte
  final String _whatsappNumero = '5522999999999'; // Pode ser atualizado para o número comercial real

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
      backgroundColor: const Color(0xFF121212), // Preto Profundo
      // Botão Flutuante do WhatsApp
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF25D366), // Verde WhatsApp
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.chat, size: 22),
        label: const Text(
          'Falar no WhatsApp',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        onPressed: () => _abrirWhatsApp('Olá! Gostaria de contratar o rastreamento veicular da Target para meu veículo.'),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. NAVBAR RESPONSIVA
          SliverAppBar(
            backgroundColor: const Color(0xFF121212).withValues(alpha: 0.95),
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

                // Links de Navegação (Apenas Desktop)
                if (isDesktop) ...[
                  _buildNavLink('Início', () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut)),
                  _buildNavLink('Recursos', () => _rolarParaSecao(_recursosKey)),
                  _buildNavLink('Para Quem É', () => _rolarParaSecao(_sobreKey)),
                  _buildNavLink('Planos', () => _rolarParaSecao(_planosKey)),
                  const SizedBox(width: 20),
                ],

                // Botão "Já sou cliente" (Abre tela de login / telemetria)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF333333), width: 1.2),
                    backgroundColor: const Color(0xFF1E1E1E),
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.person_outline, size: 18, color: Color(0xFFFF5252)),
                  label: Text(
                    isDesktop ? 'Já sou cliente' : 'Entrar',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _irParaLogin,
                ),

                const SizedBox(width: 10),

                // Botão WhatsApp no Topo
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
                      'Falar com Consultor',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _abrirWhatsApp('Olá! Quero falar com um consultor da Target Rastreamento.'),
                  ),
              ],
            ),
          ),

          // 2. CONTEÚDO PRINCIPAL (SEÇÕES DO SITE)
          SliverToBoxAdapter(
            child: Column(
              children: [
                // HERO SECTION
                _buildHeroSection(isDesktop, isTablet),

                // TRUST BAR (MÉTRICAS & DESTAQUES)
                _buildTrustBar(isDesktop),

                // SEÇÃO: IDEAL PARA (SEGMENTOS)
                Container(
                  key: _sobreKey,
                  child: _buildSecaoIdealPara(isDesktop),
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

  // --- 1. HERO SECTION (BANNER PRINCIPAL COM TEXTO E SHOWCASE 3D/MOCKUP) ---
  Widget _buildHeroSection(bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: isDesktop ? 60 : 40,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        // Brilho tecnológico sutil de fundo
        gradient: RadialGradient(
          center: Alignment(0.6, -0.4),
          radius: 1.2,
          colors: [
            Color(0x1FFF5252), // Vermelho Target suave
            Color(0xFF121212),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Coluna da Esquerda: Textos & CTAs
                    Expanded(flex: 6, child: _buildHeroTextos(isDesktop)),
                    const SizedBox(width: 48),
                    // Coluna da Direita: Mockup do App & Rastreador
                    Expanded(flex: 5, child: _buildHeroShowcase()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeroTextos(isDesktop),
                    const SizedBox(height: 40),
                    _buildHeroShowcase(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeroTextos(bool isDesktop) {
    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Pill Indicadora "Rastreador Online 4G"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'RASTREAMENTO 4G EM TEMPO REAL',
                style: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Título Principal
        RichText(
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
            ),
            children: [
              TextSpan(text: 'Rastreamento\nVeicular 4G para '),
              TextSpan(
                text: 'carro,\nmoto e frota',
                style: TextStyle(color: Color(0xFFFF5252)), // Vermelho Target
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Subtítulo
        Text(
          'Monitore seu veículo 24 horas por dia pelo computador ou celular, receba alertas imediatos de ignição, consulte histórico de trajetos e tenha bloqueio remoto instantâneo.',
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // Botões de Ação
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            // Botão Contratar / WhatsApp
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              icon: const Icon(Icons.shopping_cart_outlined, size: 20),
              label: const Text(
                'Contratar serviços',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              onPressed: () => _abrirWhatsApp('Olá! Gostaria de contratar o serviço de rastreamento da Target para meu veículo.'),
            ),

            // Botão WhatsApp Direto
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              icon: const Icon(Icons.chat, size: 20),
              label: const Text(
                'Falar no WhatsApp',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              onPressed: () => _abrirWhatsApp('Olá! Gostaria de tirar dúvidas com o suporte da Target Rastreamento.'),
            ),

            // Botão Já sou cliente
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF424242), width: 1.5),
                backgroundColor: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.login, size: 20, color: Color(0xFFFF5252)),
              label: const Text(
                'Já sou cliente',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: _irParaLogin,
            ),
          ],
        ),
      ],
    );
  }

  // --- SHOWCASE INTERATIVO (MOCKUP DO SMARTPHONE & RASTREADOR 4G) ---
  Widget _buildHeroShowcase() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF333333), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5252).withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Topo do Mockup (Status Bar estilizado)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.radar, color: Color(0xFFFF5252), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'TARGET LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF00E676), size: 6),
                      SizedBox(width: 4),
                      Text('ONLINE', style: TextStyle(color: Color(0xFF00E676), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Mini Card do Carro com Placa Mercosul
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: Row(
                children: [
                  const MercosulPlate(
                    plate: 'MQA6E92',
                    width: 95,
                    height: 34,
                    fontSize: 13,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carro de Mamãe',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Rio das Ostras - RJ',
                          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Parking', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Simulação de Mapa com Radar Tecnológico
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF21262D)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Grade de linhas do mapa
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridMapPainter(),
                    ),
                  ),
                  // Ponto central de localização do carro com pulso
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5252),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions_car, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '-22.504771, -41.920289',
                          style: TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Métricas Rápidas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniMetrica(Icons.speed, '0 km/h', 'Velocidade'),
                _buildMiniMetrica(Icons.satellite_alt, '15', 'Satélites'),
                _buildMiniMetrica(Icons.route, '25,61 km', 'Odômetro'),
                _buildMiniMetrica(Icons.battery_charging_full, '6%', 'Bateria'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetrica(IconData icon, String valor, String rotulo) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF5252)),
        const SizedBox(height: 2),
        Text(valor, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        Text(rotulo, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 9.5)),
      ],
    );
  }

  // --- 2. TRUST BAR (MÉTRICAS & DESTAQUES) ---
  Widget _buildTrustBar(bool isDesktop) {
    final itens = [
      {'icon': Icons.verified_user_outlined, 'texto': '+5.000 veículos monitorados'},
      {'icon': Icons.cell_tower, 'texto': 'Tecnologia 4G Multi-Operadora'},
      {'icon': Icons.devices, 'texto': 'App Android, iOS & Web'},
      {'icon': Icons.lock_outline, 'texto': 'Bloqueio remoto do motor'},
      {'icon': Icons.history, 'texto': 'Histórico de rotas 24/7'},
      {'icon': Icons.support_agent, 'texto': 'Suporte técnico humanizado'},
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF181818),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Wrap(
            spacing: isDesktop ? 36 : 18,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: itens.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item['icon'] as IconData, color: const Color(0xFFFF5252), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    item['texto'] as String,
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 12.5,
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

  // --- 3. SEÇÃO: IDEAL PARA (SEGMENTOS) ---
  Widget _buildSecaoIdealPara(bool isDesktop) {
    final segmentos = [
      {
        'icon': Icons.directions_car,
        'titulo': 'Carros particulares',
        'desc': 'Mais controle, tranquilidade e segurança para você e sua família no dia a dia.',
      },
      {
        'icon': Icons.two_wheeler,
        'titulo': 'Motos',
        'desc': 'Rastreamento compacto e discreto com proteção antifurto de rápida recuperação.',
      },
      {
        'icon': Icons.local_shipping,
        'titulo': 'Caminhões e Vans',
        'desc': 'Mais visibilidade para rotas, paradas, logística e entregas com pontualidade.',
      },
      {
        'icon': Icons.apartment,
        'titulo': 'Frotas empresariais',
        'desc': 'Gestão de múltiplos veículos em uma só tela, redução de custos e telemetria.',
      },
      {
        'icon': Icons.agriculture,
        'titulo': 'Máquinas e equipamentos',
        'desc': 'Acompanhamento de ativos pesados, controle de horímetro e proteção patrimonial.',
      },
      {
        'icon': Icons.storefront,
        'titulo': 'Empresas e revendedores',
        'desc': 'Soluções completas para operação, instalação homologada e revenda autorizada.',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VERSÁTIL',
                style: TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ideal para',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Soluções de rastreamento inteligente para todo tipo de veículo e operação.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 36),

              // Grid de Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final colunas = isDesktop ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colunas,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isDesktop ? 2.4 : 2.2,
                    ),
                    itemCount: segmentos.length,
                    itemBuilder: (context, index) {
                      final item = segmentos[index];
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2C2C2C)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item['icon'] as IconData, color: const Color(0xFFFF5252), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item['titulo'] as String,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['desc'] as String,
                                    style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12, height: 1.3),
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

  // --- 4. SEÇÃO: PRINCIPAIS RECURSOS (TECNOLOGIA) ---
  Widget _buildSecaoRecursos(bool isDesktop) {
    final recursos = [
      {'icon': Icons.location_on_outlined, 'titulo': 'Localização em tempo real'},
      {'icon': Icons.history, 'titulo': 'Histórico de rotas detalhado'},
      {'icon': Icons.lock_outline, 'titulo': 'Bloqueio remoto do motor'},
      {'icon': Icons.notifications_active_outlined, 'titulo': 'Alertas no celular e WhatsApp'},
      {'icon': Icons.fence_outlined, 'titulo': 'Cerca virtual inteligente'},
      {'icon': Icons.description_outlined, 'titulo': 'Relatórios de telemetria'},
      {'icon': Icons.phone_android, 'titulo': 'App Android, iOS e Web'},
      {'icon': Icons.headset_mic_outlined, 'titulo': 'Suporte técnico ágil'},
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFF161616),
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
                'Tudo o que você precisa para acompanhar, proteger e gerenciar seu patrimônio.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 36),

              // Grid de Recursos
              LayoutBuilder(
                builder: (context, constraints) {
                  final colunas = isDesktop ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colunas,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: isDesktop ? 2.6 : 3.0,
                    ),
                    itemCount: recursos.length,
                    itemBuilder: (context, index) {
                      final item = recursos[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF2C2C2C)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5252).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(item['icon'] as IconData, color: const Color(0xFFFF5252), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['titulo'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
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

  // --- 5. SEÇÃO: PLANOS & PREÇOS (CONFORME OS SCREENSHOTS) ---
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
                'Temos opções para uso pessoal, empresas e frotas. Fale com nossa equipe e escolha o plano ideal.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
              ),
              const SizedBox(height: 44),

              // Grade de 4 Planos
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
                      // 1. Essencial
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
                        onTap: () => _abrirWhatsApp('Olá! Gostaria de saber mais sobre o Plano Essencial da Target (R\$ 37/mês).'),
                      ),

                      // 2. Pro (Mais Popular)
                      _buildCardPlano(
                        categoria: 'MAIS POPULAR',
                        titulo: 'Pro',
                        preco: 'A partir de R\$ 42,00/mês',
                        subpreco: 'Mais recursos para quem quer controle completo',
                        destaque: true,
                        badgeDestaque: 'MAIS POPULAR',
                        beneficios: [
                          'Tudo do Plano Essencial',
                          'Acesso à plataforma Target PRO',
                          'Relatórios avançados',
                          'Gestão de veículos',
                          'Ideal para uso comercial',
                        ],
                        textoBotao: 'Contratar plano Pro',
                        onTap: () => _abrirWhatsApp('Olá! Quero contratar o Plano Pro da Target (R\$ 42,00/mês).'),
                      ),

                      // 3. Flex (Parcelado)
                      _buildCardPlano(
                        categoria: 'PARCELADO',
                        titulo: 'Flex',
                        preco: 'R\$ 59,90/mês no cartão',
                        subpreco: 'Sem taxa de adesão — rastreador incluso',
                        destaque: false,
                        beneficios: [
                          'Rastreador incluso no plano',
                          'Aplicativo Android, iOS e Web',
                          'Bloqueador remoto incluso',
                          'Instalação por conta do cliente',
                          'Contrato mínimo de 12 meses',
                        ],
                        textoBotao: 'Contratar plano Flex',
                        onTap: () => _abrirWhatsApp('Olá! Tenho interesse no Plano Flex com rastreador incluso (R\$ 59,90/mês).'),
                      ),

                      // 4. Frotas
                      _buildCardPlano(
                        categoria: 'EMPRESARIAL',
                        titulo: 'Frotas',
                        preco: 'Condições especiais',
                        subpreco: 'Solução corporativa sob medida',
                        destaque: false,
                        beneficios: [
                          'Gestão completa de múltiplos carros',
                          'Relatórios gerenciais customizados',
                          'Controle de velocidade e percurso',
                          'Atendimento comercial exclusivo',
                        ],
                        textoBotao: 'Solicitar proposta para frota',
                        onTap: () => _abrirWhatsApp('Olá! Gostaria de uma proposta corporativa para frota de veículos com a Target.'),
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
          // Badge Superior (Mais Popular)
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
                    letterSpacing: 1.2,
                  ),
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
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  titulo,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  preco,
                  style: TextStyle(
                    color: destaque ? const Color(0xFFFF5252) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subpreco,
                  style: const TextStyle(color: Color(0xFF757575), fontSize: 11),
                ),
                const Divider(color: Color(0xFF2C2C2C), height: 28),

                // Lista de Benefícios
                ...beneficios.map((b) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check, color: Color(0xFFFF5252), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b,
                            style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const Spacer(),

          // Botão do Card
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
                child: Text(
                  textoBotao,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. SEÇÃO: CTA FINAL ---
  Widget _buildSecaoCtaFinal() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF181818),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Icon(Icons.security, color: Color(0xFFFF5252), size: 44),
              const SizedBox(height: 16),
              const Text(
                'Pronto para proteger o seu patrimônio?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Fale com nossos especialistas agora mesmo no WhatsApp ou entre na sua conta para gerenciar seus veículos.',
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
                    label: const Text('Falar no WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _abrirWhatsApp(),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFF5252)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.login, size: 20, color: Color(0xFFFF5252)),
                    label: const Text('Acessar Área do Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // --- 7. FOOTER INSTITUCIONAL ---
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF101010),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              const TargetLogo(iconSize: 40),
              const SizedBox(height: 16),
              const Text(
                'Target Rastreamento Veicular • Tecnologia, Precisão e Monitoramento 24h',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF757575), fontSize: 12),
              ),
              const SizedBox(height: 8),
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

// Painter para grade tecnológica de fundo do mapa
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

