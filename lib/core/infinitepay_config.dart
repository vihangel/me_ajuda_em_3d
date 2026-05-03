/// Configuracao da InfinitePay.
///
/// Coloque aqui sua InfiniteTag (handle) e URLs de callback.
/// O handle e sua InfiniteTag sem o simbolo $ do inicio.
class InfinitePayConfig {
  const InfinitePayConfig._();

  // =========================================================================
  // COLOQUE SUAS CHAVES AQUI
  // =========================================================================

  /// Sua InfiniteTag (nome de usuario no App InfinitePay).
  /// Use sem o simbolo $ do inicio.
  /// Exemplo: 'minha-loja' se sua tag for $minha-loja
  static const String handle = 'vitoria-angel';

  /// URL para redirecionar o cliente apos o pagamento (opcional).
  /// Exemplo: 'https://seusite.com/pagamento-concluido'
  static const String redirectUrl = '';

  /// URL do webhook para receber notificacoes de pagamento (opcional).
  /// Exemplo: 'https://seusite.com/webhook-infinitepay'
  static const String webhookUrl = '';

  // =========================================================================
  // CONFIGURACAO DA API (nao precisa alterar)
  // =========================================================================

  /// URL base da API de checkout da InfinitePay.
  static const String checkoutApiUrl =
      'https://api.checkout.infinitepay.io/links';

  /// URL para verificar status de pagamento.
  static const String paymentCheckUrl =
      'https://api.checkout.infinitepay.io/payment_check';

  /// Verifica se o handle foi configurado.
  static bool get isConfigured => handle.isNotEmpty;
}
