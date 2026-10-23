import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Future<void> _fazerLogin() async {
    if (_userController.text.isEmpty || _passwordController.text.isEmpty) {
      _mostrarErro('Preencha o usuário e a senha.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final url = Uri.parse('https://global.pilot-gps.com/api/v3/auth/token');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': _userController.text.trim(),
          'password': _passwordController.text.trim(),
          'long_lived': true,
        }),
      );

      print("Status da resposta: ${response.statusCode}");
      print("Corpo da resposta: ${response.body}");

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        
        final String token = (dados['token'] ?? dados['data']?['token'] ?? '').toString();
        final int? nodeId = dados['node_id'] != null ? int.tryParse(dados['node_id'].toString()) : null;

        if (token.isNotEmpty) {
          print("Token recebido com sucesso!");
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(token: token, nodeId: nodeId),
              ),
            );
          }
        } else {
          _mostrarErro("Erro: Token não encontrado na resposta.");
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _mostrarErro('Usuário ou senha incorretos.');
      } else {
        _mostrarErro('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _mostrarErro("Sem conexão com a internet ou erro de rede.");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.radar, size: 80, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text('TARGET', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const Text('RASTREAMENTO VEICULAR', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, letterSpacing: 3, color: Colors.grey)),
              const SizedBox(height: 48),
              TextField(
                controller: _userController,
                decoration: InputDecoration(labelText: 'Usuário', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Senha', prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : _fazerLogin,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}