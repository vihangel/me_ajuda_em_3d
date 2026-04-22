import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';
import 'order_helpers.dart';

class OrderLookupView extends StatefulWidget {
  const OrderLookupView({
    super.key,
    required this.repository,
    required this.controller,
  });

  final OperationRepository repository;
  final TextEditingController controller;

  @override
  State<OrderLookupView> createState() => _OrderLookupViewState();
}

class _OrderLookupViewState extends State<OrderLookupView> {
  late Future<List<CustomerOrder>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getCustomerOrdersByEmail(
      widget.controller.text,
    );
  }

  void _search() {
    setState(() {
      _future = widget.repository.getCustomerOrdersByEmail(
        widget.controller.text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SoftPanel(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email usado no pedido',
                    prefixIcon: Icon(Icons.mail_outline),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Buscar pedidos',
                onPressed: _search,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<CustomerOrder>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(height: 280, child: LoadingStateView());
            }
            if (snapshot.hasError) {
              return ErrorStateView(
                message: 'Nao foi possivel buscar pedidos.',
                onRetry: _search,
              );
            }
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return const EmptyStateView(
                title: 'Nenhum pedido aberto',
                message:
                    'Confira se o email e o mesmo usado ao fazer o pedido.',
              );
            }
            return Column(
              children: [
                for (final order in orders) ...[
                  _OrderCard(order: order),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = orderStatusColor(order.status, colors);

    return SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order.code} • ${order.productTitle}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              AppStatusChip(label: order.status.label, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(order.description, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(child: Text(order.kind.label)),
              Text('Qtd. ${order.quantity}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.update, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Atualizado em ${formatDate(order.updatedAt)}'),
            ],
          ),
        ],
      ),
    );
  }
}
