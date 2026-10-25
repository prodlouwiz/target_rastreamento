import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/pilot_admin_service.dart';
import '../widgets/mercosul_plate.dart';
import '../widgets/target_logo.dart';
import 'map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controle de Abas: 0 = Já sou cliente, 1 = Não sou cliente
  int _abaSelecionada = 0;

  // Controladores: Já sou cliente (Login)
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _mostrarSenha = false;
  bool _lembrarMe = true;

  // Controladores: Não sou cliente (Cadastro)
  final TextEditingController _regNomeController = TextEditingController();
  final TextEditingController _regCpfCnpjController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regPlateController = TextEditingController();
  final TextEditingController _regVehicleModelController = TextEditingController();
  final TextEditingController _regImeiController = TextEditingController();
  final TextEditingController _regMsisdnController = TextEditingController();

  bool _isRegistering = false;
  bool _mostrarSenhaReg = false;
  String _placaDigitada = '';

  // Serviço de Administração da Pilot GPS
  final PilotAdminService _adminService = PilotAdminService();

  @override
  void initState() {
    super.initState();
    _regPlateController.addListener(() {
      setState(() {
        _placaDigitada = _regPlateController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _regNomeController.dispose();
    _regCpfCnpjController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    _regPlateController.dispose();
    _regVehicleModelController.dispose();
    _regImeiController.dispose();
    _regMsisdnController.dispose();
    super.dispose();
  }

  // --- FLUXO 1: JÁ SOU CLIENTE (LOGIN) ---
  Future<void> _fazerLogin([String? usuarioCustom, String? senhaCustom]) async {
    final usuario = usuarioCustom ?? _userController.text.trim();
    final senha = senhaCustom ?? _passwordController.text.trim();

    if (usuario.isEmpty || senha.isEmpty) {
      _mostrarMensagem('Informe o seu usuário e senha para continuar.', isErro: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://${_adminService.serverAddress}/api/v3/auth/token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': usuario,
          'password': senha,
          'long_lived': true,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('{"code": 408, "msg": "Tempo limite esgotado. Verifique sua conexão."}', 408),
      );

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);

        final String token = (dados['token'] ?? dados['data']?['token'] ?? '').toString();
        final int? nodeId = dados['node_id'] != null ? int.tryParse(dados['node_id'].toString()) : null;

        if (token.isNotEmpty) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(token: token, nodeId: nodeId),
              ),
            );
          }
        } else {
          _mostrarMensagem("Falha na autenticação: token não retornado pelo servidor.", isErro: true);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _mostrarMensagem('Usuário ou senha incorretos. Verifique suas credenciais.', isErro: true);
      } else if (response.statusCode == 408) {
        _mostrarMensagem('Tempo de conexão esgotado. Tente novamente em instantes.', isErro: true);
      } else {
        _mostrarMensagem('Erro ao conectar (${response.statusCode}). Tente novamente.', isErro: true);
      }
    } catch (e) {
      _mostrarMensagem("Sem conexão com a internet. Verifique sua rede e tente novamente.", isErro: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- FLUXO 2: NÃO SOU CLIENTE (CADASTRO ADMINISTRATIVO) ---
  Future<void> _fazerCadastro() async {
    final nome = _regNomeController.text.trim();
    final cpfCnpj = _regCpfCnpjController.text.trim();
    final email = _regEmailController.text.trim();
    final phone = _regPhoneController.text.trim();
    final password = _regPasswordController.text.trim();
    final plate = _regPlateController.text.trim();
    final imei = _regImeiController.text.trim();
    final vehicleModel = _regVehicleModelController.text.trim();
    final msisdn = _regMsisdnController.text.trim();

    if (nome.isEmpty || cpfCnpj.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _mostrarMensagem('Preencha todos os campos obrigatórios do titular.', isErro: true);
      return;
    }

    if (plate.isEmpty || imei.isEmpty) {
      _mostrarMensagem('Informe a placa do veículo e o IMEI do rastreador.', isErro: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isRegistering = true);

    try {
      final regData = ClientRegistrationData(
        name: nome,
        cpfCnpj: cpfCnpj,
        email: email,
        phone: phone,
        password: password,
        plate: plate,
        imei: imei,
        vehicleModel: vehicleModel.isNotEmpty ? vehicleModel : null,
        simCard: msisdn.isNotEmpty ? msisdn : null,
      );

      final resultado = await _adminService.registerNewClient(regData);

      if (resultado.success) {
        if (mounted) {
          _exibirModalSucessoCadastro(resultado);
        }
      } else {
        _mostrarMensagem(resultado.message, isErro: true);
      }
    } catch (e) {
      _mostrarMensagem('Erro durante o cadastro: $e', isErro: true);
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  void _exibirModalSucessoCadastro(RegistrationResult resultado) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00E676), size: 28),
            SizedBox(width: 10),
            Text('Conta Criada!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parabéns! Sua conta e veículo foram cadastrados com sucesso na central Pilot GPS.',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (resultado.accountId != null)
                    _buildLinhaResumo('Contrato / Conta ID:', resultado.accountId!),
                  _buildLinhaResumo('Usuário / Login:', resultado.login ?? _regEmailController.text),
                  _buildLinhaResumo('Veículo Vinculado:', _regPlateController.text.toUpperCase()),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // Faz o login automático com as credenciais criadas
              _fazerLogin(resultado.login ?? _regEmailController.text, resultado.password ?? _regPasswordController.text);
            },
            child: const Text('ENTRAR NO APLICATIVO', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaResumo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
          Text(valor, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _abrirConfiguracoesServidor() {
    final serverCtrl = TextEditingController(text: _adminService.serverAddress);
    final nodeCtrl = TextEditingController(text: _adminService.node.toString());
    final priceCtrl = TextEditingController(text: _adminService.billPrice.toString());
    final vehModelCtrl = TextEditingController(text: _adminService.defaultVehModel.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.tune, color: Color(0xFFFF5252), size: 22),
            SizedBox(width: 8),
            Text('Parâmetros do Servidor', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Configure o endpoint e parâmetros do painel Pilot GPS para cadastro e autenticação.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: serverCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Endereço do Servidor Pilot', prefixIcon: Icon(Icons.dns_outlined)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nodeCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Node ID', prefixIcon: Icon(Icons.hub_outlined)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Bill Price ID', prefixIcon: Icon(Icons.attach_money)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: vehModelCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Modelo do Rastreador (vehmodel ID)', prefixIcon: Icon(Icons.devices)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF9E9E9E))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                _adminService.serverAddress = serverCtrl.text.trim();
                _adminService.node = int.tryParse(nodeCtrl.text.trim()) ?? 1;
                _adminService.billPrice = int.tryParse(priceCtrl.text.trim()) ?? 143;
                _adminService.defaultVehModel = int.tryParse(vehModelCtrl.text.trim()) ?? 13;
              });
              Navigator.pop(ctx);
              _mostrarMensagem('Parâmetros do servidor atualizados com sucesso!');
            },
            child: const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _mostrarMensagem(String mensagem, {bool isErro = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isErro ? const Color(0xFFFF5252) : const Color(0xFF00E676),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(
              isErro ? Icons.error_outline : Icons.check_circle_outline,
              color: isErro ? const Color(0xFFFF5252) : const Color(0xFF00E676),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Preto Profundo
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barra superior com botão voltar ao site e parâmetros do servidor
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (Navigator.canPop(context))
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF9E9E9E),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Voltar ao site', style: TextStyle(fontSize: 12)),
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        const SizedBox.shrink(),
                      IconButton(
                        tooltip: 'Parâmetros do Servidor',
                        icon: const Icon(Icons.tune, color: Color(0xFF616161), size: 20),
                        onPressed: _abrirConfiguracoesServidor,
                      ),
                    ],
                  ),

                  // Logo oficial Target
                  const TargetLogo(iconSize: 72),
                  const SizedBox(height: 32),

                  // SELETOR DE ABAS ("Já sou cliente" | "Não sou cliente")
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2C2C2C)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildAbaBotao(
                            label: 'Já sou cliente',
                            ativa: _abaSelecionada == 0,
                            onTap: () => setState(() => _abaSelecionada = 0),
                          ),
                        ),
                        Expanded(
                          child: _buildAbaBotao(
                            label: 'Não sou cliente',
                            ativa: _abaSelecionada == 1,
                            onTap: () => setState(() => _abaSelecionada = 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // CONTEÚDO DINÂMICO CONFORME A ABA SELECIONADA
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _abaSelecionada == 0 ? _buildFormularioLogin() : _buildFormularioCadastro(),
                  ),

                  const SizedBox(height: 36),

                  // Rodapé institucional
                  const Text(
                    'Target Rastreamento Veicular • Tecnologia & Precisão',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- BOTÃO DE SELEÇÃO DE ABA ---
  Widget _buildAbaBotao({
    required String label,
    required bool ativa,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: ativa ? const Color(0xFFFF5252) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: ativa
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: ativa ? Colors.white : const Color(0xFF9E9E9E),
            fontSize: 13,
            fontWeight: ativa ? FontWeight.bold : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // --- FORMULÁRIO 1: LOGIN (JÁ SOU CLIENTE) ---
  Widget _buildFormularioLogin() {
    return Column(
      key: const ValueKey('form_login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo: Usuário
        TextField(
          controller: _userController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14.5),
          decoration: const InputDecoration(
            labelText: 'Usuário ou E-mail',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),

        // Campo: Senha
        TextField(
          controller: _passwordController,
          obscureText: !_mostrarSenha,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _fazerLogin(),
          autofillHints: const [AutofillHints.password],
          style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14.5),
          decoration: InputDecoration(
            labelText: 'Senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _mostrarSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF9E9E9E),
                size: 20,
              ),
              onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Lembrar de mim
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _lembrarMe,
                activeColor: const Color(0xFFFF5252),
                checkColor: Colors.white,
                side: const BorderSide(color: Color(0xFF9E9E9E), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) => setState(() => _lembrarMe = val ?? false),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _lembrarMe = !_lembrarMe),
              child: const Text(
                'Lembrar de mim',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),

        // Botão Primário: ENTRAR
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _fazerLogin(),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('ENTRAR'),
          ),
        ),
      ],
    );
  }

  // --- FORMULÁRIO 2: CADASTRO (NÃO SOU CLIENTE) ---
  Widget _buildFormularioCadastro() {
    return Column(
      key: const ValueKey('form_cadastro'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho explicativo
        const Text(
          'Criar Nova Conta Target',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Cadastre seus dados e o veículo para ativar o rastreamento.',
          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12.5),
        ),
        const SizedBox(height: 20),

        // SEÇÃO 1: DADOS PESSOAIS
        _buildDivisorSecao('DADOS DO TITULAR'),
        const SizedBox(height: 12),

        TextField(
          controller: _regNomeController,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            labelText: 'Nome Completo ou Razão Social *',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _regCpfCnpjController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'CPF ou CNPJ *',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _regPhoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'WhatsApp / Telefone *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _regEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            labelText: 'E-mail para Acesso *',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _regPasswordController,
          obscureText: !_mostrarSenhaReg,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Senha de Acesso desejada *',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _mostrarSenhaReg ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF9E9E9E),
                size: 20,
              ),
              onPressed: () => setState(() => _mostrarSenhaReg = !_mostrarSenhaReg),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // SEÇÃO 2: DADOS DO VEÍCULO & RASTREADOR
        _buildDivisorSecao('VEÍCULO & DISPOSITIVO'),
        const SizedBox(height: 12),

        // Pré-visualização da Placa Mercosul em tempo real!
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MercosulPlate(
              plate: _placaDigitada.isNotEmpty ? _placaDigitada : 'MERC-OSUL',
              width: 120,
              height: 42,
              fontSize: 16,
            ),
          ),
        ),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _regPlateController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Placa do Veículo *',
                  hintText: 'Ex: MQA6E92',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _regVehicleModelController,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Modelo (opcional)',
                  hintText: 'Ex: Fiat Pulse',
                  prefixIcon: Icon(Icons.car_rental),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _regImeiController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            labelText: 'IMEI do Rastreador (15 dígitos) *',
            hintText: 'Ex: 864501048291834',
            prefixIcon: Icon(Icons.radar),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _regMsisdnController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            labelText: 'Chip SIM do Rastreador (opcional)',
            hintText: 'Ex: 21998765432',
            prefixIcon: Icon(Icons.sim_card_outlined),
          ),
        ),
        const SizedBox(height: 24),

        // Botão Primário: CADASTRAR E COMEÇAR
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isRegistering ? null : _fazerCadastro,
            child: _isRegistering
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      ),
                      SizedBox(width: 12),
                      Text('ATIVANDO CONTA...'),
                    ],
                  )
                : const Text('CADASTRAR E COMEÇAR A RASTREAR'),
          ),
        ),
      ],
    );
  }

  Widget _buildDivisorSecao(String titulo) {
    return Row(
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Color(0xFFFF5252),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Color(0xFF2C2C2C), height: 1)),
      ],
    );
  }
}
