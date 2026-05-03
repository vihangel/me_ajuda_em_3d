import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/ui_components.dart';

/// Tipo de resultado do pagamento.
enum PaymentFeedbackType { success, pending, error }

/// Tela de feedback apos o pagamento.
///
/// Mostra ao cliente o resultado do pagamento com animacao e detalhes.
class PaymentFeedbackPage extends StatefulWidget {
  const PaymentFeedbackPage({
    super.key,
    required this.type,
    required this.productTitle,
    required this.quantity,
    required this.totalCents,
    this.message,
  });

  final PaymentFeedbackType type;
  final String productTitle;
  final int quantity;
  final int totalCents;
  final String? message;

  @override
  State<PaymentFeedbackPage> createState() => _PaymentFeedbackPageState();
}

class _PaymentFeedbackPageState extends State<PaymentFeedbackPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, iconColor, bgColor, title, subtitle) = switch (widget.type) {
      PaymentFeedbackType.success => (
        Icons.check_circle_rounded,
        Colors.green.shade700,
        Colors.green.shade50,
        'Pagamento confirmado!',
        'Seu pagamento foi registrado com sucesso.',
      ),
      PaymentFeedbackType.pending => (
        Icons.schedule_rounded,
        Colors.amber.shade800,
        Colors.amber.shade50,
        'Pagamento pendente',
        'Estamos aguardando a confirmacao do seu pagamento.',
      ),
      PaymentFeedbackType.error => (
        Icons.error_outline_rounded,
        colors.error,
        colors.errorContainer,
        'Erro no pagamento',
        widget.message ?? 'Ocorreu um problema ao processar seu pagamento.',
      ),
    };

    return Scaffold(
      backgroundColor: colors.surfaceContainerHighest,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Icone animado ──
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withValues(alpha: 0.18),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: iconColor, size: 48),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Titulo ──
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colors.onSurface,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitulo ──
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Detalhes do pagamento ──
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SoftPanel(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _DetailRow(
                            label: 'Produto',
                            value: widget.productTitle,
                          ),
                          const Divider(height: 20),
                          _DetailRow(
                            label: 'Quantidade',
                            value: '${widget.quantity} un.',
                          ),
                          const Divider(height: 20),
                          _DetailRow(
                            label: 'Total',
                            value: formatMoney(widget.totalCents),
                            bold: true,
                            valueColor: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Botao voltar ──
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: GradientButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'Voltar ao portal',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),

                  if (widget.type == PaymentFeedbackType.error) ...[
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tentar novamente'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Linha de detalhe
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              fontSize: bold ? 16 : 14,
              color: valueColor ?? colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
