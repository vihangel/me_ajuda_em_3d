import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.repository});

  final OperationRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummary>(
      future: repository.getDashboardSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingStateView();
        }
        if (snapshot.hasError) {
          return ErrorStateView(
            message: 'Nao foi possivel carregar a home.',
            onRetry: () {},
          );
        }
        final summary = snapshot.data;
        if (summary == null) {
          return const EmptyStateView(
            title: 'Sem resumo',
            message:
                'Quando houver materiais e jobs, os alertas aparecem aqui.',
          );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid.count(
                crossAxisCount: switch (MediaQuery.sizeOf(context).width) {
                  > 1100 => 4,
                  > 700 => 3,
                  _ => 2,
                },
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  MetricCard(
                    label: 'Pedidos pendentes',
                    value: '${summary.pendingOrders}',
                    icon: Icons.shopping_bag_outlined,
                    color: const Color(0xFF4865F4),
                  ),
                  MetricCard(
                    label: 'Orcamentos pendentes',
                    value: '${summary.pendingQuotes}',
                    icon: Icons.pending_actions,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  MetricCard(
                    label: 'Em producao',
                    value: '${summary.inProduction}',
                    icon: Icons.precision_manufacturing,
                    color: Colors.indigo.shade600,
                  ),
                  MetricCard(
                    label: 'Pronto para retirada',
                    value: '${summary.readyPickup}',
                    icon: Icons.inventory,
                    color: Colors.green.shade700,
                  ),
                  MetricCard(
                    label: 'Filamento baixo',
                    value: '${summary.lowFilaments}',
                    icon: Icons.warning_amber,
                    color: Colors.amber.shade800,
                  ),
                  MetricCard(
                    label: 'Prazo critico',
                    value: '${summary.criticalDeadlines}',
                    icon: Icons.timer_outlined,
                    color: Colors.red.shade700,
                  ),
                  MetricCard(
                    label: 'Portal: ativos',
                    value: '${summary.portalActiveProducts}',
                    icon: Icons.storefront_outlined,
                    color: Colors.teal.shade700,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader(title: 'Hoje')),
            SliverToBoxAdapter(
              child: FutureBuilder<List<ProductionJob>>(
                future: repository.getJobs(),
                builder: (context, snapshot) {
                  final jobs = snapshot.data ?? [];
                  final visible = jobs.take(3).toList();
                  if (visible.isEmpty) {
                    return const SizedBox(
                      height: 180,
                      child: EmptyStateView(
                        title: 'Fila limpa',
                        message: 'Nenhum job ativo por enquanto.',
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (final job in visible) ...[
                          _DashboardJobTile(job: job),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardJobTile extends StatelessWidget {
  const _DashboardJobTile({required this.job});

  final ProductionJob job;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: jobStatusColor(
            job.status,
            colors,
          ).withValues(alpha: 0.12),
          child: Icon(Icons.print, color: jobStatusColor(job.status, colors)),
        ),
        title: Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${job.client.name} • vence ${formatDate(job.dueAt)}'),
        trailing: AppStatusChip(
          label: job.status.label,
          color: jobStatusColor(job.status, colors),
        ),
      ),
    );
  }
}
