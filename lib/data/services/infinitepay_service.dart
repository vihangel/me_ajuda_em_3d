import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/infinitepay_config.dart';
import '../../core/p3d_models.dart';

/// Resultado da criacao de um link de checkout InfinitePay.
class CheckoutLinkResult {
  const CheckoutLinkResult({required this.url, required this.orderNsu});

  final String url;
  final String orderNsu;
}

/// Resultado da verificacao de pagamento.
class PaymentCheckResult {
  const PaymentCheckResult({
    required this.success,
    required this.paid,
    required this.amount,
    required this.paidAmount,
    required this.installments,
    required this.captureMethod,
  });

  final bool success;
  final bool paid;
  final int amount;
  final int paidAmount;
  final int installments;
  final String captureMethod;
}

/// Servico para integrar com a API de checkout da InfinitePay.
///
/// Gera links de pagamento para que o cliente pague via Pix ou cartao.
/// As taxas de parcelamento sao repassadas ao cliente automaticamente
/// pela InfinitePay.
class InfinitePayService {
  InfinitePayService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Gera um link de checkout para pagamento parcial ou total de um produto.
  ///
  /// [product] — o produto do portal
  /// [quantityToPay] — quantas unidades o cliente quer pagar agora
  /// [customerName] — nome do cliente (pre-preenche no checkout)
  /// [customerPhone] — telefone do cliente (pre-preenche no checkout)
  ///
  /// Retorna a URL do checkout para redirecionar o cliente.
  Future<CheckoutLinkResult> createCheckoutLink({
    required PortalProduct product,
    required int quantityToPay,
    String? customerName,
    String? customerPhone,
  }) async {
    if (!InfinitePayConfig.isConfigured) {
      throw InfinitePayException(
        'InfinitePay nao configurada. '
        'Defina o handle em lib/core/infinitepay_config.dart',
      );
    }

    final orderNsu = '${product.id}-${DateTime.now().millisecondsSinceEpoch}';

    final payload = <String, dynamic>{
      'handle': InfinitePayConfig.handle,
      'items': [
        {
          'quantity': quantityToPay,
          'price': product.unitPriceCents,
          'description': product.title,
        },
      ],
      'order_nsu': orderNsu,
    };

    // Adicionar URL de redirecionamento se configurada
    if (InfinitePayConfig.redirectUrl.isNotEmpty) {
      payload['redirect_url'] = InfinitePayConfig.redirectUrl;
    }

    // Adicionar webhook se configurado
    if (InfinitePayConfig.webhookUrl.isNotEmpty) {
      payload['webhook_url'] = InfinitePayConfig.webhookUrl;
    }

    // Adicionar dados do cliente se disponíveis
    if (customerName != null || customerPhone != null) {
      final customer = <String, dynamic>{};
      if (customerName != null) customer['name'] = customerName;
      if (customerPhone != null) customer['phone_number'] = customerPhone;
      payload['customer'] = customer;
    }

    final response = await _client.post(
      Uri.parse(InfinitePayConfig.checkoutApiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw InfinitePayException(
        'Erro ao gerar link de pagamento: ${response.statusCode} '
        '${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url =
        data['url'] as String? ??
        data['checkout_url'] as String? ??
        data['link'] as String? ??
        '';

    if (url.isEmpty) {
      throw InfinitePayException('Link de pagamento nao retornado pela API.');
    }

    return CheckoutLinkResult(url: url, orderNsu: orderNsu);
  }

  /// Verifica o status de um pagamento.
  Future<PaymentCheckResult> checkPayment({
    required String orderNsu,
    required String transactionNsu,
    required String slug,
  }) async {
    final response = await _client.post(
      Uri.parse(InfinitePayConfig.paymentCheckUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'handle': InfinitePayConfig.handle,
        'order_nsu': orderNsu,
        'transaction_nsu': transactionNsu,
        'slug': slug,
      }),
    );

    if (response.statusCode != 200) {
      throw InfinitePayException(
        'Erro ao verificar pagamento: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PaymentCheckResult(
      success: data['success'] as bool? ?? false,
      paid: data['paid'] as bool? ?? false,
      amount: data['amount'] as int? ?? 0,
      paidAmount: data['paid_amount'] as int? ?? 0,
      installments: data['installments'] as int? ?? 1,
      captureMethod: data['capture_method'] as String? ?? '',
    );
  }
}

class InfinitePayException implements Exception {
  const InfinitePayException(this.message);
  final String message;

  @override
  String toString() => 'InfinitePayException: $message';
}
