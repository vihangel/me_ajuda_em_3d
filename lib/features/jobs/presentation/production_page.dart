import 'package:flutter/material.dart';

import '../../../core/business_rules.dart';
import '../../../core/formatters.dart';
import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';

class ProductionPage extends StatelessWidget {
  const ProductionPage({super.key, required this.repository});

  final OperationRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductionJob>>(
      future: repository.getJobs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingStateView();
        }
        if (snapshot.hasError) {
          return ErrorStateView(
            message: 'Erro ao carregar producao.',
            onRetry: () {},
          );
        }
        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return const EmptyStateView(
            title: 'Sem jobs ativos',
            message: 'Jobs aprovados aparecem na fila de producao.',
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            _JobSection(
              title: 'Fila',
              jobs: jobs.where((job) => job.status == JobStatus.queue).toList(),
            ),
            _JobSection(
              title: 'Imprimindo',
              jobs: jobs
                  .where((job) => job.status == JobStatus.printing)
                  .toList(),
            ),
            _JobSection(
              title: 'Acabamento',
              jobs: jobs
                  .where((job) => job.status == JobStatus.finishing)
                  .toList(),
            ),
            _JobSection(
              title: 'Pronto',
              jobs: jobs
                  .where((job) => job.status == JobStatus.readyPickup)
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _JobSection extends StatelessWidget {
  const _JobSection({required this.title, required this.jobs});

  final String title;
  final List<ProductionJob> jobs;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final job in jobs) ...[
                _JobCard(job: job),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final ProductionJob job;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = jobStatusColor(job.status, colors);
    final progress = job.unitsTotal == 0 ? 0.0 : job.unitsDone / job.unitsTotal;

    return AppCard(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _JobDetailSheet(job: job),
      ),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                AppStatusChip(
                  label: deriveJobPriorityLabel(job),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${job.client.name} • #${job.quoteCode} • ${job.material}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              color: statusColor,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('${job.unitsDone}/${job.unitsTotal} feitas'),
                const Spacer(),
                Text('vence ${formatDate(job.dueAt)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JobDetailSheet extends StatelessWidget {
  const _JobDetailSheet({required this.job});

  final ProductionJob job;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              job.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text('${job.client.name} • #${job.quoteCode}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TinyStat(label: 'Total', value: '${job.unitsTotal}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TinyStat(label: 'Feitas', value: '${job.unitsDone}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TinyStat(
                    label: 'Falhas',
                    value: '${job.unitsFailed}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TinyStat(
                    label: 'Faltam',
                    value: '${job.unitsRemaining}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final update in job.updates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.check_circle,
                  color: jobStatusColor(update.statusSnapshot, colors),
                ),
                title: Text(update.messageClient),
                subtitle: Text(
                  '${update.statusSnapshot.label} • ${formatDate(update.createdAt)}',
                ),
                trailing: Icon(
                  update.sentToClient
                      ? Icons.mark_email_read
                      : Icons.mark_email_unread_outlined,
                ),
              ),
            if (job.updates.isEmpty)
              const EmptyStateView(
                title: 'Sem updates',
                message: 'Registre a primeira movimentacao do job.',
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showUpdateClient(context),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Atualizar cliente'),
            ),
            const SizedBox(height: 8),
            if (job.status != JobStatus.readyPickup &&
                job.status != JobStatus.delivered)
              OutlinedButton.icon(
                onPressed: () => _showMarkReady(context),
                icon: const Icon(Icons.inventory_outlined),
                label: const Text('Pronto para retirada'),
              ),
            if (job.status == JobStatus.readyPickup)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${job.title} marcado como entregue.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Marcar como entregue'),
              ),
          ],
        );
      },
    );
  }

  void _showUpdateClient(BuildContext context) {
    final messageCtrl = TextEditingController(
      text: 'Seu pedido "${job.title}" esta em andamento. '
          '${job.unitsDone} de ${job.unitsTotal} unidades prontas.',
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atualizar cliente'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enviar mensagem para ${job.client.name}',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Mensagem para o cliente',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
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
            label: 'Enviar',
            compact: true,
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Mensagem enviada para ${job.client.name}.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showMarkReady(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pronto para retirada?'),
        content: Text(
          'Confirma que "${job.title}" esta pronto para ${job.client.name} retirar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          GradientButton(
            label: 'Confirmar',
            compact: true,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${job.title} marcado como pronto para retirada.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
