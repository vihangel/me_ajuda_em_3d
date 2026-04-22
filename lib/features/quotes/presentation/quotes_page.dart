import 'package:flutter/material.dart';

import '../../../core/business_rules.dart';
import '../../../core/formatters.dart';
import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';

void showQuoteEditorPreview(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _QuoteEditorPreview(),
  );
}

class QuotesPage extends StatelessWidget {
  const QuotesPage({super.key, required this.repository});

  final OperationRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Quote>>(
      future: repository.getQuotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingStateView();
        }
        if (snapshot.hasError) {
          return ErrorStateView(
            message: 'Erro ao carregar orcamentos.',
            onRetry: () {},
          );
        }
        final quotes = snapshot.data ?? [];
        if (quotes.isEmpty) {
          return const EmptyStateView(
            title: 'Nenhum orcamento',
            message:
                'Crie o primeiro orcamento a partir de um cliente ou template.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: quotes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _QuoteCard(quote: quotes[index]),
        );
      },
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = quoteStatusColor(quote.status, colors);

    return AppCard(
      onTap: () => _showQuoteDetail(context),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${quote.code} • ${quote.client.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                AppStatusChip(label: quote.status.label, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              quote.items
                  .map((item) => '${item.quantity}x ${item.title}')
                  .join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.event_available,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text('${quote.deadlineDays} dias'),
                const Spacer(),
                Text(
                  formatMoney(quote.finalTotalCents),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuoteDetail(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = quoteStatusColor(quote.status, colors);

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Orcamento #${quote.code}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                AppStatusChip(label: quote.status.label, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${quote.client.name} • ${quote.client.phone}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            for (final item in quote.items) ...[
              SoftPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity}x ${item.title}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.material} • ${item.finish} • ${item.color}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.gramsEstimate}g • ${item.printMinutesEstimate}min',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Unitario'),
                        Text(
                          formatMoney(item.unitPriceCents),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (quote.discountCents > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Desconto'),
                    Text(
                      '- ${formatMoney(quote.discountCents)}',
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  formatMoney(quote.finalTotalCents),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                ),
              ],
            ),
            if (quote.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Obs: ${quote.notes}',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 20),
            if (quote.status == QuoteStatus.draft) ...[
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Orcamento #${quote.code} enviado ao cliente.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.send_outlined),
                label: const Text('Enviar ao cliente'),
              ),
            ],
            if (quote.status == QuoteStatus.sent) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '#${quote.code} aprovado.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Aprovar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '#${quote.code} recusado.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Recusar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuoteEditorPreview extends StatelessWidget {
  const _QuoteEditorPreview();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final result = calculateQuoteTotals(
      const QuoteCalculationInput(
        rollCostCents: 8990,
        rollGrams: 1000,
        estimatedGrams: 420,
        estimatedMinutes: 840,
        machineMinuteCents: 18,
        finishingMinutes: 45,
        laborMinuteCents: 42,
        artFeeCents: 2500,
        suppliesCostCents: 1260,
        variableTaxPct: 0.08,
        desiredMarginPct: 0.35,
        quantity: 30,
      ),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return DefaultTabController(
          length: 2,
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(
                'Editor de orcamento',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const TabBar(
                tabs: [
                  Tab(text: 'Rapido'),
                  Tab(text: 'Real'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: TabBarView(
                  children: [
                    _EditorModeCard(
                      icon: Icons.flash_on_outlined,
                      title: 'Atendimento inicial',
                      lines: const [
                        'Tipo: ima personalizado',
                        'Complexidade: media',
                        'Quantidade: 30',
                        'Arte: sim',
                        'Faixa: R\$ 390 a R\$ 460',
                      ],
                    ),
                    _EditorModeCard(
                      icon: Icons.calculate_outlined,
                      title: 'Fechamento real',
                      lines: [
                        'Peso estimado: 420g',
                        'Tempo slicer: 14h',
                        'Custo operacional: ${formatMoney(result.operationalSubtotalCents)}',
                        'Preco minimo: ${formatMoney(result.minimumPriceCents)}',
                        'Sugerido: ${formatMoney(result.suggestedPriceCents)}',
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: colors.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No app real, o widget chama um controller. O calculo fica em funcao pura e o repository troca fake data por API MongoDB no Railway.',
                          style: TextStyle(color: colors.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rascunho salvo com sucesso.'),
                    ),
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar rascunho'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Orcamento enviado ao cliente.'),
                    ),
                  );
                },
                icon: const Icon(Icons.send_outlined),
                label: const Text('Enviar ao cliente'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EditorModeCard extends StatelessWidget {
  const _EditorModeCard({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(line),
              ),
          ],
        ),
      ),
    );
  }
}
