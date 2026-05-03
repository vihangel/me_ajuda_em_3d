import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';

/// Pagina admin para gerenciar clientes do portal e seus produtos.
class PortalManagementPage extends StatefulWidget {
  const PortalManagementPage({super.key, required this.repository});

  final OperationRepository repository;

  @override
  State<PortalManagementPage> createState() => _PortalManagementPageState();
}

class _PortalManagementPageState extends State<PortalManagementPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<P3dClient>>(
      future: widget.repository.getPortalClients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingStateView();
        }
        if (snapshot.hasError) {
          return ErrorStateView(
            message: 'Erro ao carregar clientes do portal.',
            onRetry: () => setState(() {}),
          );
        }

        final clients = snapshot.data ?? [];

        if (clients.isEmpty) {
          return const EmptyStateView(
            title: 'Nenhum cliente no portal',
            message: 'Cadastre clientes recorrentes para que acessem o portal.',
            icon: Icons.storefront_outlined,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: clients.length,
          separatorBuilder: (_, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final client = clients[index];
            return _PortalClientCard(
              client: client,
              repository: widget.repository,
              onChanged: () => setState(() {}),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Portal client card
// ---------------------------------------------------------------------------

class _PortalClientCard extends StatelessWidget {
  const _PortalClientCard({
    required this.client,
    required this.repository,
    required this.onChanged,
  });

  final P3dClient client;
  final OperationRepository repository;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppCard(
      onTap: () => _showClientProducts(context),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                client.name.characters.first.toUpperCase(),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.companyName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${client.name} • ${client.phone}',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // Code badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              client.portalCode,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: colors.outline),
        ],
      ),
    );
  }

  void _showClientProducts(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ClientProductsSheet(
        client: client,
        repository: repository,
        onChanged: onChanged,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client products sheet
// ---------------------------------------------------------------------------

class _ClientProductsSheet extends StatefulWidget {
  const _ClientProductsSheet({
    required this.client,
    required this.repository,
    required this.onChanged,
  });

  final P3dClient client;
  final OperationRepository repository;
  final VoidCallback onChanged;

  @override
  State<_ClientProductsSheet> createState() => _ClientProductsSheetState();
}

class _ClientProductsSheetState extends State<_ClientProductsSheet> {
  List<PortalProduct>? _products;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await widget.repository.getPortalProducts(
      widget.client.portalCode,
    );
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  void _showAddProduct() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '10');
    final costCtrl = TextEditingController();
    final sellCtrl = TextEditingController();
    final imageCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo produto'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Produto',
                    hintText: 'Ex: Caixinha de figurinha',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descricao',
                    hintText: 'Detalhes do produto...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Custo (R\$)',
                          hintText: '5,00',
                          prefixText: 'R\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: sellCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Venda (R\$)',
                          hintText: '15,00',
                          prefixText: 'R\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL da imagem (opcional)',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          GradientButton(
            label: 'Criar',
            compact: true,
            onPressed: () async {
              final qty = int.tryParse(qtyCtrl.text) ?? 0;
              if (titleCtrl.text.trim().isEmpty || qty <= 0) return;
              final costCents = _parseMoney(costCtrl.text);
              final sellCents = _parseMoney(sellCtrl.text);
              await widget.repository.createPortalOrderRequest(
                widget.client.portalCode,
                PortalOrderRequest(
                  productTitle: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  quantity: qty,
                  costPriceCents: costCents,
                  sellPriceCents: sellCents,
                  imageUrl: imageCtrl.text.trim(),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
              widget.onChanged();
            },
          ),
        ],
      ),
    );
  }

  /// Converte texto de dinheiro (ex: "5,50" ou "5.50") para centavos.
  static int _parseMoney(String text) {
    if (text.trim().isEmpty) return 0;
    final normalized = text
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^\d.]'), '');
    final value = double.tryParse(normalized) ?? 0;
    return (value * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        if (_loading) {
          return const LoadingStateView();
        }

        final products = _products ?? [];

        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client.companyName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.client.name} • ${widget.client.portalCode} • ${widget.client.employeeCount} funcionarios',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                GradientButton(
                  icon: Icons.add_rounded,
                  label: 'Produto',
                  compact: true,
                  onPressed: _showAddProduct,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary
            if (products.isNotEmpty) ...[
              _PortalSummaryRow(products: products),
              const SizedBox(height: 16),
            ],

            // Products
            Text(
              'Produtos (${products.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EmptyStateView(
                  title: 'Sem produtos',
                  message: 'Adicione o primeiro produto deste cliente.',
                  icon: Icons.inventory_2_outlined,
                ),
              )
            else
              for (final product in products) ...[
                _AdminProductCard(
                  product: product,
                  repository: widget.repository,
                  onChanged: () {
                    _load();
                    widget.onChanged();
                  },
                ),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Portal summary row
// ---------------------------------------------------------------------------

class _PortalSummaryRow extends StatelessWidget {
  const _PortalSummaryRow({required this.products});
  final List<PortalProduct> products;

  @override
  Widget build(BuildContext context) {
    final totalQty = products.fold<int>(0, (s, p) => s + p.quantity);
    final paidQty = products.fold<int>(0, (s, p) => s + p.paidQuantity);
    final active = products
        .where((p) => p.status != PortalProductStatus.delivered)
        .length;

    return Row(
      children: [
        _MiniStat(label: 'Total un.', value: '$totalQty'),
        const SizedBox(width: 8),
        _MiniStat(
          label: 'Pagos',
          value: '$paidQty',
          color: Colors.green.shade700,
        ),
        const SizedBox(width: 8),
        _MiniStat(
          label: 'Pendentes',
          value: '${totalQty - paidQty}',
          color: Colors.orange.shade700,
        ),
        const SizedBox(width: 8),
        _MiniStat(
          label: 'Ativos',
          value: '$active',
          color: Colors.indigo.shade600,
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Expanded(
      child: SoftPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: c,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin product card (with actions)
// ---------------------------------------------------------------------------

class _AdminProductCard extends StatelessWidget {
  const _AdminProductCard({
    required this.product,
    required this.repository,
    required this.onChanged,
  });

  final PortalProduct product;
  final OperationRepository repository;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + status + image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail
              if (product.hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product.imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.broken_image_outlined,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
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
              _ProductStatusChip(status: product.status),
            ],
          ),
          const SizedBox(height: 12),

          // Prices row (admin only — custo, venda, lucro)
          if (product.costPriceCents > 0 || product.unitPriceCents > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  if (product.costPriceCents > 0) ...[
                    _PricePill(
                      label: 'Custo',
                      value: formatMoney(product.costPriceCents),
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (product.unitPriceCents > 0) ...[
                    _PricePill(
                      label: 'Venda',
                      value: formatMoney(product.unitPriceCents),
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (product.costPriceCents > 0 &&
                      product.unitPriceCents > 0) ...[
                    _PricePill(
                      label: 'Lucro/un',
                      value: formatMoney(
                        product.unitPriceCents - product.costPriceCents,
                      ),
                      color: Colors.green.shade700,
                    ),
                  ],
                ],
              ),
            ),

          // Quantity + payment progress
          Row(
            children: [
              Text(
                '${product.paidQuantity}/${product.quantity} pagos',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: product.paidRatio,
                    minHeight: 6,
                    backgroundColor: colors.outlineVariant.withValues(
                      alpha: 0.2,
                    ),
                    valueColor: AlwaysStoppedAnimation(
                      product.paidRatio >= 1.0
                          ? Colors.green.shade600
                          : const Color(0xFF4865F4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatDate(product.updatedAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.outline),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              // Status change
              Expanded(
                child: _StatusDropdown(
                  currentStatus: product.status,
                  onChanged: (status) async {
                    await repository.updatePortalProductStatus(
                      product.id,
                      status,
                    );
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Payment update
              SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: () => _showPaymentDialog(context),
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text('Pagamento'),
                  style: OutlinedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final ctrl = TextEditingController(text: '${product.paidQuantity}');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pagamento: ${product.title}'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total: ${product.quantity} unidades'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(labelText: 'Quantidade paga'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          GradientButton(
            label: 'Atualizar',
            compact: true,
            onPressed: () async {
              final qty = int.tryParse(ctrl.text) ?? 0;
              await repository.updatePortalProductPayment(product.id, qty);
              if (ctx.mounted) Navigator.pop(ctx);
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Price pill (admin)
// ---------------------------------------------------------------------------

class _PricePill extends StatelessWidget {
  const _PricePill({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product status chip
// ---------------------------------------------------------------------------

class _ProductStatusChip extends StatelessWidget {
  const _ProductStatusChip({required this.status});
  final PortalProductStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Chip(
      visualDensity: VisualDensity.compact,
      shape: const StadiumBorder(),
      side: BorderSide(color: color.withValues(alpha: 0.16)),
      backgroundColor: color.withValues(alpha: 0.10),
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

  static Color _statusColor(PortalProductStatus status) => switch (status) {
    PortalProductStatus.producing => Colors.deepOrange.shade600,
    PortalProductStatus.finishing => Colors.amber.shade800,
    PortalProductStatus.delivering => Colors.blue.shade700,
    PortalProductStatus.delivered => Colors.green.shade700,
  };
}

// ---------------------------------------------------------------------------
// Status dropdown
// ---------------------------------------------------------------------------

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.currentStatus, required this.onChanged});

  final PortalProductStatus currentStatus;
  final ValueChanged<PortalProductStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: DropdownButtonFormField<PortalProductStatus>(
        isDense: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        initialValue: currentStatus,
        items: [
          for (final s in PortalProductStatus.values)
            DropdownMenuItem(value: s, child: Text(s.label)),
        ],
        onChanged: (v) {
          if (v != null && v != currentStatus) onChanged(v);
        },
      ),
    );
  }
}
