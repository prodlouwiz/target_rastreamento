import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../widgets/target_logo.dart';
import 'emergencia_screen.dart';
import 'landing_page_screen.dart';
import 'map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Dados pré-preenchidos para acesso rápido e direto
  final TextEditingController _userController = TextEditingController(text: 'prodlouwiz');
  final TextEditingController _passwordController = TextEditingController(text: 'Target@2026');
  
  bool _isLoading = false;
  bool _mostrarSenha = false;
  bool _lembrarMe = true;

  // WhatsApp oficial da Target
  static const String _whatsappNumero = '5522997694019';

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    final usuario = _userController.text.trim();
    final senha = _passwordController.text.trim();

    if (usuario.isEmpty || senha.isEmpty) {
      _mostrarMensagem('Informe o seu usuário e senha para continuar.', isErro: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://global.pilot-gps.com/api/v3/auth/token');

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
      _mostrarMensagem("Sem conexão com a central. Verifique sua rede e tente novamente.", isErro: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _abrirWhatsAppContratacao() async {
    const mensagem = 'Olá! Gostaria de me tornar cliente da Target Rastreamento e contratar o serviço.';
    final uri = Uri.parse('https://wa.me/$_whatsappNumero?text=${Uri.encodeComponent(mensagem)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
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
            color: isErro ? const Color(0xFFFF1E2D) : const Color(0xFF35D49A),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(
              isErro ? Icons.error_outline : Icons.check_circle_outline,
              color: isErro ? const Color(0xFFFF1E2D) : const Color(0xFF35D49A),
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
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barra Superior com botão "Voltar ao site"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF9E9E9E),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Voltar ao site', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LandingPageScreen()),
                            );
                          }
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF2C2C2C)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock, size: 12, color: Color(0xFF35D49A)),
                            SizedBox(width: 4),
                            Text('Acesso Seguro', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Logo oficial Target
                  const TargetLogo(iconSize: 76),
                  const SizedBox(height: 36),

                  // Card de Login
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2C2C2C)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Área do Cliente',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Entre com suas credenciais para monitorar seus veículos.',
                          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                        ),
                        const SizedBox(height: 22),

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
                                activeColor: const Color(0xFFFF1E2D),
                                checkColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF9E9E9E), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) => setState(() => _lembrarMe = val ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _lembrarMe = !_lembrarMe),
                              child: const Text(
                                'Lembrar de mim',
                                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Botão Primário: ENTRAR
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _fazerLogin,
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
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Seção: Não sou cliente? Falar no WhatsApp
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181818),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Ainda não tem acesso à plataforma?',
                          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12.5),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF25D366),
                            side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text(
                            'Contratar pelo WhatsApp (22) 99769-4019',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _abrirWhatsAppContratacao,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextButton.icon(
                    icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF1E2D), size: 16),
                    label: const Text(
                      '🚨 Central de Bloqueio & Emergência 24h',
                      style: TextStyle(
                        color: Color(0xFFFF1E2D),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmergenciaScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Rodapé institucional
                  const Text(
                    'Target Rastreamento Veicular • Tecnologia & Precisão',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: Color(0xFF616161),
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
}
