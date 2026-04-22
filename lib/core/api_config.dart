class ApiConfig {
  const ApiConfig._();

  /// Base URL da API incluindo o prefixo do modulo 3D.
  ///
  /// Em producao aponte para o Railway:
  /// `https://oicoach-production.up.railway.app/api/3d`
  ///
  /// Para rodar local:
  /// `http://localhost:3000/api/3d`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/3d',
  );

  /// Base URL para rotas de autenticacao (sem prefixo de modulo).
  static String get authBaseUrl {
    // Remove o sufixo do modulo (/3d) para chegar em /api
    final uri = Uri.parse(baseUrl);
    final segments = uri.pathSegments.toList();
    if (segments.isNotEmpty && segments.last == '3d') {
      segments.removeLast();
    }
    return uri.replace(pathSegments: segments).toString();
  }
}
