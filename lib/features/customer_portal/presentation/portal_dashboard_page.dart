import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatters.dart';
import '../../../core/infinitepay_config.dart';
import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';
import '../../../data/services/infinitepay_service.dart';
import 'payment_feedback_page.dart';

/// Dashboard do portal do cliente.
/// Mostra os produtos do cliente, status, pagamentos e permite solicitar mais.
class PortalDashboardPage extends StatefulWidget {
  const PortalDashboardPage({
    super.key,
    required this.client,
    required this.repository,
    required this.onLogout,
  });

  final P3dClient client;
  final OperationRepository repository;
  final VoidCallback onLogout;

  @override
  State<PortalDashboardPage> createState() => _PortalDashboardPageState();
}

class _PortalDashboardPageState extends State<PortalDashboardPage> {
  List<PortalProduct>? _products;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await widget.repository.getPortalProducts(
        widget.client.portalCode,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erro ao carregar produtos.';
      });
    }
  }

  void _showNewOrderDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _NewOrderDialog(
        onSubmit: (request) async {
          final nav = Navigator.of(ctx);
          final messenger = ScaffoldMessenger.of(context);
          final product = await widget.repository.createPortalOrderRequest(
            widget.client.portalCode,
            request,
          );
          if (!mounted) return;
          nav.pop();
          _loadProducts();
          messenger.showSnackBar(
            SnackBar(content: Text('Pedido "${product.title}" solicitado!')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _PortalTopBar(client: widget.client, onLogout: widget.onLogout),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wide ? 900 : double.infinity,
                  ),
                  child: _loading
                      ? const LoadingStateView()
                      : _error != null
                      ? ErrorStateView(message: _error!, onRetry: _loadProducts)
                      : _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final products = _products ?? [];
    final totalProducts = products.length;
    final totalQuantity = products.fold<int>(0, (s, p) => s + p.quantity);
    final totalPaid = products.fold<int>(0, (s, p) => s + p.paidQuantity);
    final inProgress = products
        .where((p) => p.status != PortalProductStatus.delivered)
        .length;

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryRow(
            totalProducts: totalProducts,
            totalQuantity: totalQuantity,
            totalPaid: totalPaid,
            inProgress: inProgress,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Seus produtos',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              GradientButton(
                icon: Icons.add_rounded,
                label: 'Novo pedido',
                compact: true,
                onPressed: _showNewOrderDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const EmptyStateView(
              title: 'Nenhum produto',
              message: 'Voce ainda nao tem produtos. Solicite um novo pedido!',
              icon: Icons.inventory_2_outlined,
            )
          else
            ...products.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProductCard(
                  product: product,
                  client: widget.client,
                  repository: widget.repository,
                  onPaymentDone: _loadProducts,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _PortalTopBar extends StatelessWidget {
  const _PortalTopBar({required this.client, required this.onLogout});
  final P3dClient client;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          const BrandMark(),
          const SizedBox(width: 16),
          Container(
            height: 28,
            width: 1,
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  client.companyName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${client.name} • ${client.portalCode}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Sair',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary row
// ---------------------------------------------------------------------------

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.totalProducts,
    required this.totalQuantity,
    required this.totalPaid,
    required this.inProgress,
  });
  final int totalProducts;
  final int totalQuantity;
  final int totalPaid;
  final int inProgress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        final cards = [
          _MiniMetric(
            icon: Icons.inventory_2_outlined,
            label: 'Produtos',
            value: '$totalProducts',
            color: const Color(0xFF4865F4),
          ),
          _MiniMetric(
            icon: Icons.all_inbox_rounded,
            label: 'Total unidades',
            value: '$totalQuantity',
            color: const Color(0xFF8462F5),
          ),
          _MiniMetric(
            icon: Icons.check_circle_outline,
            label: 'Pagos',
            value: '$totalPaid',
            color: Colors.green.shade700,
          ),
          _MiniMetric(
            icon: Icons.pending_outlined,
            label: 'Em andamento',
            value: '$inProgress',
            color: Colors.deepOrange.shade600,
          ),
        ];
        if (wide) {
          return Row(
            children: cards
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: c,
                    ),
                  ),
                )
                .toList(),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards
              .map(
                (c) =>
                    SizedBox(width: (constraints.maxWidth - 8) / 2, child: c),
              )
              .toList(),
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product card — with payment button
// ---------------------------------------------------------------------------

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.client,
    required this.repository,
    required this.onPaymentDone,
  });
  final PortalProduct product;
  final P3dClient client;
  final OperationRepository repository;
  final VoidCallback onPaymentDone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasPending = product.pendingQuantity > 0;

    return SoftPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with optional image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: colors.outline,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusChip(status: product.status),
            ],
          ),
          const SizedBox(height: 16),

          // Quantity + price info
          Row(
            children: [
              _InfoPill(
                icon: Icons.all_inbox_rounded,
                label: 'Total',
                value: '${product.quantity}',
              ),
              const SizedBox(width: 12),
              _InfoPill(
                icon: Icons.check_circle_outline,
                label: 'Pagos',
                value: '${product.paidQuantity}',
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 12),
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: 'Pendentes',
                value: '${product.pendingQuantity}',
                color: hasPending ? Colors.orange.shade700 : colors.outline,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Price info
          if (product.unitPriceCents > 0) ...[
            Row(
              children: [
                Text(
                  'Valor unitario: ${_money(product.unitPriceCents)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (hasPending)
                  Text(
                    'Pendente: ${_money(product.pendingCents)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  )
                else
                  Text(
                    'Tudo pago!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Payment progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pagamento',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '${(product.paidRatio * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: product.paidRatio >= 1.0
                      ? Colors.green.shade700
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: product.paidRatio,
              minHeight: 8,
              backgroundColor: colors.outlineVariant.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                product.paidRatio >= 1.0
                    ? Colors.green.shade600
                    : const Color(0xFF4865F4),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Pay button (only if there are pending items)
          if (hasPending)
            SizedBox(
              width: double.infinity,
              child: _PayButton(
                product: product,
                client: client,
                repository: repository,
                onPaymentDone: onPaymentDone,
              ),
            )
          else
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Pagamento completo',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Atualizado em ${_formatDate(product.updatedAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.outline),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _money(int cents) => formatMoney(cents);

  static String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ---------------------------------------------------------------------------
// Pay button — opens payment dialog with quantity selector
// ---------------------------------------------------------------------------

class _PayButton extends StatelessWidget {
  const _PayButton({
    required this.product,
    required this.client,
    required this.repository,
    required this.onPaymentDone,
  });
  final PortalProduct product;
  final P3dClient client;
  final OperationRepository repository;
  final VoidCallback onPaymentDone;

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      icon: Icons.pix_rounded,
      label: 'Pagar (Pix ou Cartao)',
      onPressed: () => showDialog(
        context: context,
        builder: (ctx) => _PaymentDialog(
          product: product,
          client: client,
          repository: repository,
          onPaymentDone: onPaymentDone,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment dialog — select quantity, generate InfinitePay link
// ---------------------------------------------------------------------------

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({
    required this.product,
    required this.client,
    required this.repository,
    required this.onPaymentDone,
  });
  final PortalProduct product;
  final P3dClient client;
  final OperationRepository repository;
  final VoidCallback onPaymentDone;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late int _qty = widget.product.pendingQuantity;
  bool _generating = false;
  String? _checkoutUrl;
  String? _error;

  int get _totalCents => _qty * widget.product.unitPriceCents;

  Future<void> _generateLink() async {
    if (_qty <= 0) return;

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final service = InfinitePayService();
      final result = await service.createCheckoutLink(
        product: widget.product,
        quantityToPay: _qty,
        customerName: widget.client.name,
        customerPhone: widget.client.phone,
      );

      if (!mounted) return;
      setState(() {
        _checkoutUrl = result.url;
        _generating = false;
      });
    } catch (e) {
      if (!mounted) return;

      // Se InfinitePay nao esta configurada, simular pagamento local
      if (e is InfinitePayException && e.message.contains('nao configurada')) {
        await _simulatePayment();
        return;
      }

      setState(() {
        _generating = false;
        _error = e is InfinitePayException
            ? e.message
            : 'Erro ao gerar link de pagamento.';
      });
    }
  }

  /// Simula pagamento quando InfinitePay nao esta configurada.
  /// Atualiza direto o paidQuantity no repository.
  Future<void> _simulatePayment() async {
    final newPaid = widget.product.paidQuantity + _qty;
    await widget.repository.updatePortalProductPayment(
      widget.product.id,
      newPaid,
    );
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pop(); // fecha o dialog
    widget.onPaymentDone();
    nav.push(
      MaterialPageRoute(
        builder: (_) => PaymentFeedbackPage(
          type: PaymentFeedbackType.success,
          productTitle: widget.product.title,
          quantity: _qty,
          totalCents: _totalCents,
        ),
      ),
    );
  }

  /// Marca como pago apos o cliente confirmar que pagou via InfinitePay.
  Future<void> _confirmPayment() async {
    final newPaid = widget.product.paidQuantity + _qty;
    await widget.repository.updatePortalProductPayment(
      widget.product.id,
      newPaid,
    );
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pop(); // fecha o dialog
    widget.onPaymentDone();
    nav.push(
      MaterialPageRoute(
        builder: (_) => PaymentFeedbackPage(
          type: PaymentFeedbackType.success,
          productTitle: widget.product.title,
          quantity: _qty,
          totalCents: _totalCents,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pending = widget.product.pendingQuantity;

    // If we have a checkout URL, show it
    if (_checkoutUrl != null) {
      return AlertDialog(
        title: const Text('Link de pagamento gerado'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade700,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$_qty x ${widget.product.title}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                formatMoney(_totalCents),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pague via Pix ou cartao de credito.\n'
                'Parcele em ate 12x (taxas do parcelamento '
                'sao adicionadas automaticamente).',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              // Checkout URL display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _checkoutUrl!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copiar link',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _checkoutUrl!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copiado!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          GradientButton(
            label: 'Ja paguei',
            compact: true,
            icon: Icons.check_rounded,
            onPressed: _confirmPayment,
          ),
        ],
      );
    }

    // Quantity selection screen
    return AlertDialog(
      title: const Text('Pagar produto'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product info
            SoftPanel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Valor unitario: ${formatMoney(widget.product.unitPriceCents)}',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  Text(
                    'Pendente: $pending de ${widget.product.quantity} unidades',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quantity selector
            Text(
              'Quantas unidades quer pagar agora?',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: Text(
                    '$_qty',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  onPressed: _qty < pending
                      ? () => setState(() => _qty++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick select buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (pending > 1)
                  _QuickQtyChip(
                    label: '1 un.',
                    selected: _qty == 1,
                    onTap: () => setState(() => _qty = 1),
                  ),
                if (pending > 5)
                  _QuickQtyChip(
                    label: '5 un.',
                    selected: _qty == 5,
                    onTap: () => setState(() => _qty = 5),
                  ),
                if (pending > 10)
                  _QuickQtyChip(
                    label: '10 un.',
                    selected: _qty == 10,
                    onTap: () => setState(() => _qty = 10),
                  ),
                _QuickQtyChip(
                  label: 'Tudo ($pending)',
                  selected: _qty == pending,
                  onTap: () => setState(() => _qty = pending),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Total
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(
                    'Total a pagar:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatMoney(_totalCents),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),

            if (!InfinitePayConfig.isConfigured) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'InfinitePay nao configurada. O pagamento sera '
                        'simulado localmente. Configure sua handle em '
                        'lib/core/infinitepay_config.dart',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: colors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _generating ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        _generating
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : GradientButton(
                label: InfinitePayConfig.isConfigured
                    ? 'Gerar link de pagamento'
                    : 'Pagar agora',
                compact: true,
                icon: Icons.pix_rounded,
                onPressed: _generateLink,
              ),
      ],
    );
  }
}

class _QuickQtyChip extends StatelessWidget {
  const _QuickQtyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colors.primary.withValues(alpha: 0.15),
      checkmarkColor: colors.primary,
      labelStyle: TextStyle(
        color: selected ? colors.primary : null,
        fontWeight: selected ? FontWeight.w700 : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final PortalProductStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      PortalProductStatus.producing => (
        Colors.deepOrange.shade600,
        Icons.precision_manufacturing_outlined,
      ),
      PortalProductStatus.finishing => (
        Colors.amber.shade800,
        Icons.auto_fix_high_rounded,
      ),
      PortalProductStatus.delivering => (
        Colors.blue.shade700,
        Icons.local_shipping_outlined,
      ),
      PortalProductStatus.delivered => (
        Colors.green.shade700,
        Icons.check_circle_outline,
      ),
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      shape: const StadiumBorder(),
      side: BorderSide(color: color.withValues(alpha: 0.16)),
      backgroundColor: color.withValues(alpha: 0.10),
      avatar: Icon(icon, color: color, size: 16),
      label: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info pill
// ---------------------------------------------------------------------------

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: c,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// New order dialog
// ---------------------------------------------------------------------------

class _NewOrderDialog extends StatefulWidget {
  const _NewOrderDialog({required this.onSubmit});
  final Future<void> Function(PortalOrderRequest request) onSubmit;

  @override
  State<_NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends State<_NewOrderDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '10');
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (title.isEmpty) {
      setState(() => _error = 'Informe o nome do produto.');
      return;
    }
    if (qty <= 0) {
      setState(() => _error = 'Quantidade deve ser maior que zero.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        PortalOrderRequest(
          productTitle: title,
          description: _descCtrl.text.trim(),
          quantity: qty,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Erro ao enviar pedido. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Solicitar novo pedido'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Produto',
                hintText: 'Ex: Caixinha de figurinha',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descricao (opcional)',
                hintText: 'Detalhes do pedido...',
              ),
              maxLines: 3,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              decoration: const InputDecoration(
                labelText: 'Quantidade',
                hintText: '10',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded, size: 18),
          label: const Text('Solicitar'),
        ),
      ],
    );
  }
}
