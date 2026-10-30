import 'package:flutter/foundation.dart';

/// Configuração centralizada das rotas de API do Pilot GPS.
/// 
/// Garante que:
/// - Na Web (Browser em produção, ex: targetrastreamento.com.br): as chamadas usem a rota
///   relativa `/api/...` (Same-Origin), que é repassada pelo Nginx/Cloudflare Tunnel via
///   proxy reverso para o `global.pilot-gps.com`. Isso elimina 100% dos bloqueios de CORS do navegador.
/// - No Mobile (Android / iOS) e Desktop: as chamadas vão diretamente para `global.pilot-gps.com`.
class PilotApiConfig {
  static const String directHost = 'global.pilot-gps.com';

  /// Constrói um [Uri] seguro e compatível com a plataforma atual.
  /// 
  /// [path]: Caminho completo do endpoint (ex: '/api/v3/auth/token' ou '/ax/api.php').
  /// [queryParameters]: Parâmetros opcionais de busca (query string).
  static Uri getUri(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    if (kIsWeb) {
      final base = Uri.base;
      // Se estiver no browser, usa o scheme e host do próprio site (Same-Origin)
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

    // Mobile / Desktop nativo: chamada direta sem restrições de CORS de navegador
    return Uri.https(directHost, normalizedPath, queryParameters);
  }
}
