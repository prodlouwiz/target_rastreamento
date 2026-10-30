import 'package:flutter/foundation.dart';

/// Configuração centralizada das rotas de API do Pilot GPS.
/// 
/// Garante compatibilidade total em todos os ambientes:
/// - No Localhost (desenvolvimento web com `flutter run -d chrome`): conecta diretamente
///   ao `global.pilot-gps.com` (já que em desenvolvimento usa-se `--disable-web-security`).
/// - Na Produção Web (ex: targetrastreamento.com.br): usa a rota relativa `/api/...` (Same-Origin)
///   repassada pelo Nginx/Cloudflare Tunnel via proxy reverso, eliminando o bloqueio de CORS.
/// - No Mobile (Android / iOS) e Desktop: conecta diretamente ao `global.pilot-gps.com`.
class PilotApiConfig {
  static const String directHost = 'global.pilot-gps.com';

  /// Identifica se a execução web está ocorrendo localmente (ambiente de desenvolvimento).
  static bool get isLocalhost {
    if (!kIsWeb) return false;
    final host = Uri.base.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host.startsWith('192.168.');
  }

  /// Constrói um [Uri] seguro e compatível com a plataforma e ambiente atual.
  static Uri getUri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    if (kIsWeb) {
      // Se estiver rodando localmente no navegador (localhost), chama direto o Pilot GPS
      if (isLocalhost) {
        return Uri.https(directHost, normalizedPath, queryParameters);
      }

      // Em produção (ex: targetrastreamento.com.br), usa o mesmo host para passar pelo proxy reverso do Nginx
      final base = Uri.base;
      final scheme = base.scheme.isNotEmpty ? base.scheme : 'https';
      final host = base.host.isNotEmpty ? base.host : 'targetrastreamento.com.br';
      final port = base.hasPort ? base.port : null;

      return Uri(
        scheme: scheme,
        host: host,
        port: port,
        path: normalizedPath,
        queryParameters: queryParameters,
      );
    }

    // Mobile / Desktop nativo
    return Uri.https(directHost, normalizedPath, queryParameters);
  }

  /// Retorna o URI direto para o servidor do Pilot GPS (usado como fallback)
  static Uri getDirectUri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.https(directHost, normalizedPath, queryParameters);
  }
}
