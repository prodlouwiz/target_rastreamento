import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class EmergenciaScreen extends StatelessWidget {
  const EmergenciaScreen({super.key});

  static const String _whatsappNumero = '5522997694019';

  Future<void> _abrirWhatsAppEmergencia() async {
    const msg = '''🚨 *EMERGÊNCIA - ROUBO / FURTO EM ANDAMENTO*
Olá, central de apoio Target! Preciso de auxílio imediato para localização e bloqueio de veículo com suspeita de sinistro.''';

    final url = Uri.parse(
        'https://wa.me/$_whatsappNumero?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _ligarPolicia() async {
    final url = Uri.parse('tel:190');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF140808),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 22),
            SizedBox(width: 10),
            Text(
              'Central de Bloqueio & Emergência 24h',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF9E9E9E)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 60 : 20,
          vertical: 40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner de Alerta Imediato
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF261010),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF5252), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.security,
                            color: Color(0xFFFF5252), size: 30),
                      ),
                      const SizedBox(width: 18),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seu veículo foi roubado ou furtado agora?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Mantenha a calma. Siga os 3 passos abaixo imediatamente para cortar o combustível e acionar as autoridades.',
                              style: TextStyle(
                                color: Color(0xFFFFCDD2),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // PASSO 1: BLOQUEAR NO APLICATIVO
                _buildPassoEmergencia(
                  numero: '1',
                  titulo: 'Corte a ignição pelo Aplicativo Target',
                  descricao:
                      'Acesse sua conta agora mesmo. Em caso de furto, selecione seu veículo e aperte "Bloquear Motor". O corte progressivo é executado via satélite 4G em menos de 5 segundos.',
                  botaoTexto: 'Abrir Tela de Login para Bloquear',
                  botaoIcone: Icons.lock,
                  corBotao: const Color(0xFFFF5252),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // PASSO 2: ACIONAR A POLÍCIA MILITAR 190
                _buildPassoEmergencia(
                  numero: '2',
                  titulo: 'Ligue para a Polícia Militar (190)',
                  descricao:
                      'Informe imediatamente o roubo/furto, modelo, cor, placa e o endereço exato que você está vendo no mapa em tempo real da Target. As viaturas mais próximas serão despachadas para o ponto exato.',
                  botaoTexto: 'Ligar 190 (Polícia Militar)',
                  botaoIcone: Icons.call,
                  corBotao: const Color(0xFF1976D2),
                  onTap: _ligarPolicia,
                ),
                const SizedBox(height: 20),

                // PASSO 3: APOIO DE PLANTÃO TARGET NO WHATSAPP
                _buildPassoEmergencia(
                  numero: '3',
                  titulo: 'Fale com o Suporte Emergencial Target',
                  descricao:
                      'Nossa equipe técnica pode apoiar você no rastreamento contínuo da rota, gerando relatórios de trajeto e auxiliando na comunicação das coordenadas para as forças de segurança.',
                  botaoTexto: 'Chamar Plantão no WhatsApp: (22) 99769-4019',
                  botaoIcone: Icons.chat,
                  corBotao: const Color(0xFF25D366),
                  onTap: _abrirWhatsAppEmergencia,
                ),
                const SizedBox(height: 36),

                // DICAS DE SEGURANÇA FUNDAMENTAIS
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF263238)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: Color(0xFFFFB300), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'RECOMENDAÇÕES DE SEGURANÇA',
                            style: TextStyle(
                              color: Color(0xFFFFB300),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• NUNCA persiga o veículo por conta própria. Sua vida vale muito mais do que qualquer bem material.\n'
                        '• Deixe que a Polícia Militar e o sistema de rastreamento localizem o veículo de forma tática.\n'
                        '• Mantenha o aplicativo aberto para acompanhar as atualizações de satélite e transmitir a coordenada atualizada aos policiais.',
                        style: TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassoEmergencia({
    required String numero,
    required String titulo,
    required String descricao,
    required String botaoTexto,
    required IconData botaoIcone,
    required Color corBotao,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF263238)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: corBotao.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: corBotao, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    numero,
                    style: TextStyle(
                      color: corBotao,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descricao,
            style: const TextStyle(
              color: Color(0xFFB0BEC5),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: corBotao,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(botaoIcone, size: 18),
            label: Text(
              botaoTexto,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
