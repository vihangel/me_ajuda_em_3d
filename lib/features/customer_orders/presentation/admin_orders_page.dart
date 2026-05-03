import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';
import 'order_helpers.dart';

/// Pagina admin para gerenciar todos os pedidos de clientes.
class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key, required this.repository});

  final OperationRepository repository;

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                for (final status in CustomerOrderStatus.values) ...[
                  _FilterChip(
                    label: status.label,
                    selected: _filter == status.name,
                    color: orderStatusColor(
                      status,
                      Theme.of(context).colorScheme,
                    ),
                    onTap: () => setState(() => _filter = status.name),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        // Order list
        Expanded(
          child: FutureBuilder<List<CustomerOrder>>(
            future: widget.repository.getAllCustomerOrders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingStateView();
              }
              if (snapshot.hasError) {
                return ErrorStateView(
                  message: 'Erro ao carregar pedidos.',
                  onRetry: () => setState(() {}),
                );
              }

              var orders = snapshot.data ?? [];
              if (_filter != 'all') {
                orders = orders.where((o) => o.status.name == _filter).toList();
              }

              if (orders.isEmpty) {
                return const EmptyStateView(
                  title: 'Nenhum pedido',
                  message: 'Pedidos de clientes aparecem aqui.',
                  icon: Icons.shopping_bag_outlined,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: orders.length,
                separatorBuilder: (_, i) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _OrderCard(
                    order: order,
                    repository: widget.repository,
                    onChanged: () => setState(() {}),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: c.withValues(alpha: 0.15),
      checkmarkColor: c,
      labelStyle: TextStyle(
        color: selected ? c : null,
        fontWeight: selected ? FontWeight.w700 : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order card
// ---------------------------------------------------------------------------

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.repository,
    required this.onChanged,
  });

  final CustomerOrder order;
  final OperationRepository repository;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = orderStatusColor(order.status, colors);

    return AppCard(
      onTap: () => _showOrderDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${order.code}',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.productTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppStatusChip(label: order.status.label, color: statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: colors.outline),
              const SizedBox(width: 4),
              Text(
                order.customerName,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.inventory_2_outlined, size: 16, color: colors.outline),
              const SizedBox(width: 4),
              Text(
                '${order.quantity} un.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                formatDate(order.createdAt),
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

  void _showOrderDetail(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#${order.code}',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.productTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info rows
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Cliente',
              value: '${order.customerName} (${order.kind.label})',
            ),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: order.email,
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Telefone',
              value: order.phone,
            ),
            _InfoRow(
              icon: Icons.description_outlined,
              label: 'Descricao',
              value: order.description,
            ),
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Quantidade',
              value: '${order.quantity} unidades',
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Criado em',
              value: formatDate(order.createdAt),
            ),
            if (order.hasReferenceImage)
              _InfoRow(
                icon: Icons.image_outlined,
                label: 'Imagem',
                value: 'Cliente enviou imagem de referencia',
              ),
            const SizedBox(height: 16),

            // Status workflow
            Text(
              'Alterar status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _StatusWorkflow(
              currentStatus: order.status,
              onStatusChanged: (newStatus) async {
                await repository.updateCustomerOrderStatus(order.id, newStatus);
                if (context.mounted) Navigator.pop(context);
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info row
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.outline),
                ),
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status workflow buttons
// ---------------------------------------------------------------------------

class _StatusWorkflow extends StatelessWidget {
  const _StatusWorkflow({
    required this.currentStatus,
    required this.onStatusChanged,
  });

  final CustomerOrderStatus currentStatus;
  final ValueChanged<CustomerOrderStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final status in CustomerOrderStatus.values)
          _WorkflowChip(
            label: status.label,
            color: orderStatusColor(status, colors),
            isCurrent: status == currentStatus,
            onTap: status == currentStatus
                ? null
                : () => onStatusChanged(status),
          ),
      ],
    );
  }
}

class _WorkflowChip extends StatelessWidget {
  const _WorkflowChip({
    required this.label,
    required this.color,
    required this.isCurrent,
    this.onTap,
  });

  final String label;
  final Color color;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrent ? color.withValues(alpha: 0.18) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? color
                  : Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrent) ...[
                Icon(Icons.check_circle, color: color, size: 16),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isCurrent
                      ? color
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
