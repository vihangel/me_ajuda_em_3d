import 'package:flutter/material.dart';

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
          child: SearchBar(
            hintText: 'Buscar por nome, telefone ou canal',
            leading: const Icon(Icons.search),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: widget.repository.getClients(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingStateView();
              }
              if (snapshot.hasError) {
                return ErrorStateView(
                  message: 'Erro ao carregar clientes.',
                  onRetry: () {},
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
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(client.name.characters.first.toUpperCase()),
                      ),
                      title: Text(client.name),
                      subtitle: Text(
                        '${client.phone} • ${client.lastQuoteLabel}',
                      ),
                      trailing: AppStatusChip(
                        label: client.currentStatus,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        builder: (_) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(client.phone),
                              Text('Canal: ${client.channel}'),
                              const SizedBox(height: 16),
                              AppStatusChip(
                                label: client.currentStatus,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(client.notes),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.request_quote_outlined),
                                label: const Text('Criar orcamento'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
