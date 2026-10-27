import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OrcamentoScreen extends StatefulWidget {
  const OrcamentoScreen({super.key});

  @override
  State<OrcamentoScreen> createState() => _OrcamentoScreenState();
}

class _OrcamentoScreenState extends State<OrcamentoScreen> {
  static const String _whatsappNumero = '5522997694019';

  // Opções selecionadas
  String _tipoVeiculo = 'carro'; // carro, moto, caminhao, frota
  int _quantidade = 1;
  String _plano = 'pro'; // proprio (40), pro (49.99), flex (70)
  String _cidade = 'Rio das Ostras';

  final List<String> _cidades = [
    'Rio das Ostras',
    'Macaé',
    'Casimiro de Abreu',
    'Cabo Frio',
    'Búzios',
    'Campos dos Goytacazes',
    'Outra Região do RJ',
  ];

  double get _precoUnitario {
    switch (_plano) {
      case 'proprio':
        return 40.0;
      case 'pro':
        return 49.99;
      case 'flex':
        return 70.0;
      default:
        return 49.99;
    }
  }

  double get _totalMensal => _precoUnitario * _quantidade;

  String get _nomePlano {
    switch (_plano) {
      case 'proprio':
        return 'Plano Próprio (R\$ 40,00/mês)';
      case 'pro':
        return 'Plano Pro (R\$ 49,99/mês)';
      case 'flex':
        return 'Plano Flex (R\$ 70,00/mês)';
      default:
        return 'Plano Pro';
    }
  }

  String get _nomeVeiculo {
    switch (_tipoVeiculo) {
      case 'carro':
        return 'Carro de Passeio / Utilitário';
      case 'moto':
        return 'Motocicleta';
      case 'caminhao':
        return 'Caminhão / Veículo Pesado';
      case 'frota':
        return 'Frota Empresarial';
      default:
        return 'Veículo';
    }
  }

  Future<void> _enviarCotacaoWhatsApp() async {
    final msg = '''Olá, equipe Target Rastreamento!
Gostaria de fechar minha cotação personalizada gerada no site:

📋 *DETALHES DA PROPOSTA:*
• *Veículo:* $_nomeVeiculo
• *Quantidade:* $_quantidade veículo(s)
• *Plano Escolhido:* $_nomePlano
• *Cidade para Instalação:* $_cidade
• *Estimativa Mensal:* R\$ ${_totalMensal.toStringAsFixed(2)}/mês

Gostaria de verificar a disponibilidade de agendamento da instalação técnica própria!''';

    final url = Uri.parse(
        'https://wa.me/$_whatsappNumero?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F141A),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.calculate_outlined, color: Color(0xFFFF5252), size: 22),
            SizedBox(width: 10),
            Text(
              'Simulador de Orçamento & Cotação',
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
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'COTAÇÃO ONLINE EM 1 MINUTO',
                  style: TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Calcule o valor exato para o seu veículo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Escolha o tipo de veículo, a quantidade e o plano ideal. Sem letras miúdas.',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Layout: Formulário à esquerda + Resumo à direita no Desktop
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildFormulario()),
                      const SizedBox(width: 30),
                      Expanded(flex: 2, child: _buildCardResumo()),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildFormulario(),
                      const SizedBox(height: 30),
                      _buildCardResumo(),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TIPO DE VEÍCULO
        const Text(
          '1. Qual tipo de veículo você quer proteger?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildCardTipoVeiculo(
              id: 'carro',
              label: 'Carro',
              sub: 'Passeio / SUV / Pickup',
              icone: Icons.directions_car,
            ),
            _buildCardTipoVeiculo(
              id: 'moto',
              label: 'Moto',
              sub: 'Urbana / Alta Cilindrada',
              icone: Icons.two_wheeler,
            ),
            _buildCardTipoVeiculo(
              id: 'caminhao',
              label: 'Caminhão',
              sub: 'Vans / Logística / VUC',
              icone: Icons.local_shipping,
            ),
            _buildCardTipoVeiculo(
              id: 'frota',
              label: 'Frota',
              sub: 'Corporativa / Múltiplos',
              icone: Icons.apartment,
            ),
          ],
        ),
        const SizedBox(height: 30),

        // 2. QUANTIDADE DE VEÍCULOS
        const Text(
          '2. Quantos veículos você quer rastrear?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF263238)),
          ),
          child: Row(
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF0F141A),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.remove),
                onPressed: _quantidade > 1
                    ? () => setState(() => _quantidade--)
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                '$_quantidade ${_quantidade == 1 ? "veículo" : "veículos"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _quantidade++),
              ),
              const Spacer(),
              if (_quantidade >= 3)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Desconto Frota Aplicado!',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // 3. PLANO DESEJADO
        const Text(
          '3. Qual o plano mais adequado para você?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            _buildCardOpcaoPlano(
              id: 'proprio',
              nome: 'Plano Próprio',
              preco: 'R\$ 40,00/mês',
              desc: 'Rastreador não incluso (Venda à parte). Sem fidelidade.',
            ),
            const SizedBox(height: 10),
            _buildCardOpcaoPlano(
              id: 'pro',
              nome: 'Plano Pro (Mais Popular)',
              preco: 'R\$ 49,99/mês',
              desc:
                  'Rastreador em comodato + Bloqueio remoto + Cercas virtuais.',
              destaque: true,
            ),
            const SizedBox(height: 10),
            _buildCardOpcaoPlano(
              id: 'flex',
              nome: 'Plano Flex',
              preco: 'R\$ 70,00/mês',
              desc:
                  'Rastreador em comodato + Relatórios customizados + Gestão completa.',
            ),
          ],
        ),
        const SizedBox(height: 30),

        // 4. CIDADE DE INSTALAÇÃO
        const Text(
          '4. Cidade para instalação técnica própria:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF263238)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _cidade,
              dropdownColor: const Color(0xFF161B22),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              items: _cidades.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _cidade = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardTipoVeiculo({
    required String id,
    required String label,
    required String sub,
    required IconData icone,
  }) {
    final ativo = _tipoVeiculo == id;
    return InkWell(
      onTap: () => setState(() => _tipoVeiculo = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ativo
              ? const Color(0xFFFF5252).withValues(alpha: 0.15)
              : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ativo ? const Color(0xFFFF5252) : const Color(0xFF263238),
            width: ativo ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icone,
              color: ativo ? const Color(0xFFFF5252) : const Color(0xFF90A4AE),
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: ativo ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(color: Color(0xFF78909C), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardOpcaoPlano({
    required String id,
    required String nome,
    required String preco,
    required String desc,
    bool destaque = false,
  }) {
    final ativo = _plano == id;
    return InkWell(
      onTap: () => setState(() => _plano = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ativo
              ? const Color(0xFFFF5252).withValues(alpha: 0.12)
              : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ativo ? const Color(0xFFFF5252) : const Color(0xFF263238),
            width: ativo ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              ativo ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: ativo ? const Color(0xFFFF5252) : const Color(0xFF78909C),
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (destaque) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style:
                        const TextStyle(color: Color(0xFF90A4AE), fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Text(
              preco,
              style: TextStyle(
                color: ativo ? const Color(0xFFFF5252) : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card de Resumo Financeiro da Proposta
  Widget _buildCardResumo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF5252).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5252).withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMO DA PROPOSTA',
            style: TextStyle(
              color: Color(0xFFFF5252),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seu Plano Personalizado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Divider(color: Color(0xFF263238), height: 28),

          _buildLinhaResumo('Veículo:', _nomeVeiculo),
          const SizedBox(height: 10),
          _buildLinhaResumo('Quantidade:', '$_quantidade veículo(s)'),
          const SizedBox(height: 10),
          _buildLinhaResumo('Plano:', _nomePlano),
          const SizedBox(height: 10),
          _buildLinhaResumo('Instalação em:', _cidade),
          const Divider(color: Color(0xFF263238), height: 28),

          // Valor Total Estimado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Mensalidade Total:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'R\$ ${_totalMensal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFFF5252),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    '/mês',
                    style: TextStyle(color: Color(0xFF90A4AE), fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '* Instalação técnica realizada exclusivamente por equipe própria com agendamento prévio.',
            style: TextStyle(color: Color(0xFF78909C), fontSize: 11),
          ),
          const SizedBox(height: 24),

          // Botão Enviar Proposta para WhatsApp
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.chat, size: 20),
              label: const Text(
                'Enviar Proposta via WhatsApp',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: _enviarCotacaoWhatsApp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaResumo(String rotulo, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(rotulo, style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 13)),
        Text(valor,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
