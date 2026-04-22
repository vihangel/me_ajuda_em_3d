class ApiConfig {
  const ApiConfig._();

  /// Troque pela URL do Railway em produção.
  /// Ex: 'https://me-ajuda-em-3d-api-production.up.railway.app'
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
