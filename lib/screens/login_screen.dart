import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/target_logo.dart';
import 'map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _mostrarSenha = false;
  bool _lembrarMe = true;

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
      _mostrarErro('Informe o seu usuário e senha para continuar.');
      return;
    }

    // Fecha o teclado virtual
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
          _mostrarErro("Falha na autenticação: token não recebido do servidor.");
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _mostrarErro('Usuário ou senha incorretos. Verifique suas credenciais.');
      } else if (response.statusCode == 408) {
        _mostrarErro('Tempo de conexão esgotado. Tente novamente em instantes.');
      } else {
        _mostrarErro('Erro ao conectar (${response.statusCode}). Tente novamente.');
      }
    } catch (e) {
      _mostrarErro("Sem conexão com a internet. Verifique sua rede e tente novamente.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E1E), // Cinza Superfície
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFFF5252), width: 1), // Vermelho Target
        ),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF5252), size: 22),
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
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo padronizada de acordo com o Brand Book
                  const TargetLogo(iconSize: 76),
                  const SizedBox(height: 48),

                  // Campo: Usuário / E-mail
                  TextField(
                    controller: _userController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username, AutofillHints.email],
                    style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 15),
                    decoration: const InputDecoration(
                      labelText: 'Usuário ou E-mail',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Campo: Senha
                  TextField(
                    controller: _passwordController,
                    obscureText: !_mostrarSenha,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _fazerLogin(),
                    autofillHints: const [AutofillHints.password],
                    style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFF9E9E9E), // Cinza Secundário
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _mostrarSenha = !_mostrarSenha);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Linha: Lembrar-me
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _lembrarMe,
                          activeColor: const Color(0xFFFF5252), // Vermelho Target
                          checkColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF9E9E9E), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setState(() => _lembrarMe = val ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() => _lembrarMe = !_lembrarMe);
                        },
                        child: const Text(
                          'Lembrar de mim',
                          style: TextStyle(
                            color: Color(0xFF9E9E9E), // Cinza Secundário
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Botão de Ação Primário (Vermelho Target)
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _fazerLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFFFFF),
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('ENTRAR'),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Rodapé discreto
                  const Text(
                    'Target • Monitoramento em tempo real',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      color: Color(0xFF9E9E9E), // Cinza Secundário
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
