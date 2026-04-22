import 'package:flutter/material.dart';

import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key, required this.repository});

  final OperationRepository repository;

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SoftPanel(
            padding: const EdgeInsets.all(4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por nome, telefone ou canal',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<P3dClient>>(
            future: widget.repository.getClients(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingStateView();
              }
              if (snapshot.hasError) {
                return ErrorStateView(
                  message: 'Erro ao carregar clientes.',
                  onRetry: () => setState(() {}),
                );
              }

              final clients = (snapshot.data ?? []).where((client) {
                if (_query.isEmpty) return true;
                return client.name.toLowerCase().contains(_query) ||
                    client.phone.toLowerCase().contains(_query) ||
                    client.channel.toLowerCase().contains(_query);
              }).toList();

              if (clients.isEmpty) {
                return const EmptyStateView(
                  title: 'Nada encontrado',
                  message: 'Tente outro termo ou cadastre um novo cliente.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: clients.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return _ClientCard(
                    client: client,
                    repository: widget.repository,
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

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client, required this.repository});

  final P3dClient client;
  final OperationRepository repository;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _clientStatusColor(client.currentStatus, colors);

    return AppCard(
      onTap: () => _showClientDetail(context),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.primary.withValues(alpha: 0.12),
            child: Text(
              client.name.characters.first.toUpperCase(),
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${client.phone} • ${client.channel}',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                if (client.lastQuoteLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    client.lastQuoteLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.outline,
                        ),
                  ),
                ],
              ],
            ),
          ),
          AppStatusChip(label: client.currentStatus, color: statusColor),
        ],
      ),
    );
  }

  void _showClientDetail(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.primary.withValues(alpha: 0.12),
                  child: Text(
                    client.name.characters.first.toUpperCase(),
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      AppStatusChip(
                        label: client.currentStatus,
                        color: _clientStatusColor(
                            client.currentStatus, colors),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Telefone',
              value: client.phone,
            ),
            _DetailRow(
              icon: Icons.campaign_outlined,
              label: 'Canal',
              value: client.channel,
            ),
            _DetailRow(
              icon: Icons.receipt_long_outlined,
              label: 'Ultimo orcamento',
              value: client.lastQuoteLabel,
            ),
            if (client.notes.isNotEmpty)
              _DetailRow(
                icon: Icons.notes_outlined,
                label: 'Observacoes',
                value: client.notes,
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Orcamento para ${client.name} sera criado.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.request_quote_outlined),
                    label: const Text('Criar orcamento'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showEditClient(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditClient(BuildContext context) {
    final nameCtrl = TextEditingController(text: client.name);
    final phoneCtrl = TextEditingController(text: client.phone);
    final channelCtrl = TextEditingController(text: client.channel);
    final notesCtrl = TextEditingController(text: client.notes);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar cliente'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: channelCtrl,
                decoration: const InputDecoration(labelText: 'Canal'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Observacoes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          GradientButton(
            label: 'Salvar',
            compact: true,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${nameCtrl.text} atualizado.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.outline,
                      ),
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

Color _clientStatusColor(String status, ColorScheme colors) {
  final lower = status.toLowerCase();
  if (lower.contains('pronto')) return Colors.green.shade700;
  if (lower.contains('fila') || lower.contains('producao')) {
    return Colors.indigo.shade600;
  }
  if (lower.contains('aguardando') || lower.contains('analise')) {
    return Colors.amber.shade800;
  }
  if (lower.contains('novo')) return colors.primary;
  return colors.outline;
}
