import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';

class MaterialsPage extends StatelessWidget {
  const MaterialsPage({super.key, required this.repository});

  final OperationRepository repository;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: SoftPanel(
              padding: EdgeInsets.all(4),
              child: TabBar(
                tabs: [
                  Tab(text: 'Filamentos'),
                  Tab(text: 'Insumos'),
                  Tab(text: 'Baixo estoque'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _FilamentList(repository: repository, lowOnly: false),
                _SupplyList(repository: repository, lowOnly: false),
                _LowStockList(repository: repository),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilamentList extends StatelessWidget {
  const _FilamentList({required this.repository, required this.lowOnly});

  final OperationRepository repository;
  final bool lowOnly;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Filament>>(
      future: repository.getFilaments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingStateView();
        }
        if (snapshot.hasError) {
          return ErrorStateView(
            message: 'Erro ao carregar filamentos.',
            onRetry: () {},
          );
        }

        final filaments = (snapshot.data ?? [])
            .where(
              (filament) => !lowOnly || filament.status != FilamentStatus.ok,
            )
            .toList();

        if (filaments.isEmpty) {
          return const EmptyStateView(
            title: 'Estoque saudavel',
            message: 'Nenhum filamento abaixo do minimo agora.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filaments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _FilamentCard(filament: filaments[index]),
        );
      },
    );
  }
}

class _FilamentCard extends StatelessWidget {
  const _FilamentCard({required this.filament});

  final Filament filament;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = switch (filament.status) {
      FilamentStatus.ok => Colors.green.shade700,
      FilamentStatus.low => Colors.amber.shade800,
      FilamentStatus.empty => colors.error,
    };

    return AppCard(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(filament.colorHex),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${filament.material} ${filament.colorName}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${filament.brand} • ${filament.finish} • lote ${filament.lot}',
                      ),
                    ],
                  ),
                ),
                AppStatusChip(label: filament.status.label, color: statusColor),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: filament.remainingRatio.clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              color: statusColor,
              backgroundColor: colors.surfaceContainerHighest,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${filament.remainingGrams}g de ${filament.rollGrams}g',
                  ),
                ),
                Text(formatMoney(filament.costCents)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplyList extends StatelessWidget {
  const _SupplyList({required this.repository, required this.lowOnly});

  final OperationRepository repository;
  final bool lowOnly;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SupplyItem>>(
      future: repository.getSupplies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingStateView();
        }
        if (snapshot.hasError) {
          return ErrorStateView(
            message: 'Erro ao carregar insumos.',
            onRetry: () {},
          );
        }

        final supplies = (snapshot.data ?? [])
            .where((supply) => !lowOnly || supply.isLow)
            .toList();
        if (supplies.isEmpty) {
          return const EmptyStateView(
            title: 'Sem insumo critico',
            message: 'Os insumos estao acima do estoque minimo.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: supplies.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final supply = supplies[index];
            return AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(supply.title),
                subtitle: Text(
                  '${supply.category} • minimo ${supply.minimumQuantity}',
                ),
                trailing: Text(
                  '${supply.quantity}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LowStockList extends StatelessWidget {
  const _LowStockList({required this.repository});

  final OperationRepository repository;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: 360,
          child: _FilamentList(repository: repository, lowOnly: true),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 280,
          child: _SupplyList(repository: repository, lowOnly: true),
        ),
      ],
    );
  }
}
