import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/p3d_models.dart';
import '../core/ui_components.dart';
import '../data/operation_repository.dart';
import '../features/quotes/presentation/quotes_page.dart';

// ---------------------------------------------------------------------------
// Top-bar action per tab
// ---------------------------------------------------------------------------

Widget? adminAction(BuildContext context, int index, OperationRepository repo, VoidCallback refresh) {
  return switch (index) {
    0 => ActionPill(icon: Icons.add_rounded, label: 'Novo pedido',
        onPressed: () => showCreateOrderDialog(context, repo, refresh)),
    1 => ActionPill(icon: Icons.add_rounded, label: 'Cadastrar',
        onPressed: () => showCreateMaterialDialog(context, repo, refresh)),
    2 => ActionPill(icon: Icons.add_rounded, label: 'Novo orcamento',
        onPressed: () => showQuoteEditorPreview(context)),
    3 => ActionPill(icon: Icons.swap_vert_rounded, label: 'Reordenar',
        onPressed: () => showReorderQueueSheet(context, repo)),
    4 => ActionPill(icon: Icons.person_add_alt_rounded, label: 'Novo cliente',
        onPressed: () => showCreateClientDialog(context, repo, refresh)),
    _ => null,
  };
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

Future<void> showSearchSheet(BuildContext context, OperationRepository repo, String query) async {
  final results = await repo.search(query);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(context: context, showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Busca global', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (results.isEmpty)
          const EmptyStateView(title: 'Nada encontrado', message: 'Tente buscar por cliente, pedido ou material.')
        else
          for (final r in results)
            ListTile(leading: CircleAvatar(child: Icon(_searchIcon(r.icon))),
                title: Text(r.title), subtitle: Text('${r.type} • ${r.subtitle}')),
      ]),
    ),
  );
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

Future<void> showNotificationsSheet(BuildContext context, OperationRepository repo) async {
  final items = await repo.getNotifications();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(context: context, showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Notificacoes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const EmptyStateView(title: 'Tudo certo', message: 'Nenhum alerta operacional agora.')
        else
          for (final n in items)
            ListTile(
              leading: CircleAvatar(child: Icon(n.severity == 'danger' ? Icons.priority_high_rounded : Icons.warning_amber_rounded)),
              title: Text(n.title), subtitle: Text(n.message)),
      ]),
    ),
  );
}

// ---------------------------------------------------------------------------
// Create order
// ---------------------------------------------------------------------------

Future<void> showCreateOrderDialog(BuildContext context, OperationRepository repo, VoidCallback refresh) async {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final description = TextEditingController();
  var kind = CustomerKind.person;
  var quantity = 1;
  var productTitle = 'Chaveiro personalizado';

  await showDialog<void>(context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => AlertDialog(
        title: const Text('Novo pedido'),
        content: SizedBox(width: 440, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          SegmentedButton<CustomerKind>(
            segments: [for (final v in CustomerKind.values) ButtonSegment(value: v, label: Text(v.label))],
            selected: {kind}, onSelectionChanged: (v) => set(() => kind = v.first)),
          const SizedBox(height: 10),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
          const SizedBox(height: 10),
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 10),
          TextField(controller: phone, decoration: const InputDecoration(labelText: 'Telefone')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(value: productTitle, items: const [
            DropdownMenuItem(value: 'Chaveiro personalizado', child: Text('Chaveiro personalizado')),
            DropdownMenuItem(value: 'Encomenda decoracao', child: Text('Encomenda decoracao')),
            DropdownMenuItem(value: 'Quadro ou placa', child: Text('Quadro ou placa')),
            DropdownMenuItem(value: 'Pedido com base em imagem', child: Text('Pedido com base em imagem')),
            DropdownMenuItem(value: 'Outros', child: Text('Outros')),
          ], onChanged: (v) => set(() => productTitle = v ?? productTitle),
              decoration: const InputDecoration(labelText: 'Produto')),
          const SizedBox(height: 10),
          TextField(controller: description, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Detalhes')),
          const SizedBox(height: 10),
          Row(children: [
            const Expanded(child: Text('Quantidade')),
            IconButton(onPressed: quantity > 1 ? () => set(() => quantity--) : null, icon: const Icon(Icons.remove)),
            Text('$quantity'),
            IconButton(onPressed: () => set(() => quantity++), icon: const Icon(Icons.add)),
          ]),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          GradientButton(label: 'Criar', compact: true, onPressed: () async {
            await repo.createCustomerOrder(CreateCustomerOrderInput(
              customerName: name.text, email: email.text, phone: phone.text, kind: kind,
              productTitle: productTitle, description: description.text, quantity: quantity, hasReferenceImage: false));
            if (context.mounted) Navigator.pop(context);
            refresh();
          }),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Create material
// ---------------------------------------------------------------------------

Future<void> showCreateMaterialDialog(BuildContext context, OperationRepository repo, VoidCallback refresh) async {
  final brand = TextEditingController(text: '3D Fila');
  final material = TextEditingController(text: 'PLA');
  final color = TextEditingController(text: 'Azul marinho');

  await showDialog<void>(context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cadastrar filamento'),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: brand, decoration: const InputDecoration(labelText: 'Marca')),
        const SizedBox(height: 10),
        TextField(controller: material, decoration: const InputDecoration(labelText: 'Material')),
        const SizedBox(height: 10),
        TextField(controller: color, decoration: const InputDecoration(labelText: 'Cor')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        GradientButton(label: 'Cadastrar', compact: true, onPressed: () async {
          await repo.createFilament(brand: brand.text, material: material.text, finish: 'Fosco',
              colorName: color.text, colorHex: 0xFF14213D, rollGrams: 1000, remainingGrams: 1000, costCents: 9990, lowStockGrams: 180);
          if (context.mounted) Navigator.pop(context);
          refresh();
        }),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Create client
// ---------------------------------------------------------------------------

Future<void> showCreateClientDialog(BuildContext context, OperationRepository repo, VoidCallback refresh) async {
  final name = TextEditingController();
  final phone = TextEditingController();
  final channel = TextEditingController(text: 'WhatsApp');
  final notes = TextEditingController();

  await showDialog<void>(context: context,
    builder: (context) => AlertDialog(
      title: const Text('Novo cliente'),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 10),
        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Telefone')),
        const SizedBox(height: 10),
        TextField(controller: channel, decoration: const InputDecoration(labelText: 'Canal')),
        const SizedBox(height: 10),
        TextField(controller: notes, decoration: const InputDecoration(labelText: 'Observacoes')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        GradientButton(label: 'Salvar', compact: true, onPressed: () async {
          await repo.createClient(name: name.text, phone: phone.text, channel: channel.text, notes: notes.text);
          if (context.mounted) Navigator.pop(context);
          refresh();
        }),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Reorder queue
// ---------------------------------------------------------------------------

Future<void> showReorderQueueSheet(BuildContext context, OperationRepository repo) async {
  final jobs = await repo.getJobs();
  final queue = jobs.where((j) => j.status == JobStatus.queue).toList();
  if (!context.mounted) return;
  if (queue.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum job na fila para reordenar.')));
    return;
  }
  await showModalBottomSheet<void>(context: context, showDragHandle: true, isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(expand: false, initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.85,
      builder: (context, ctrl) => ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        Text('Fila de producao', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Ordem atual por prioridade e prazo', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        for (var i = 0; i < queue.length; i++) ...[
          AppCard(child: Row(children: [
            CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                child: Text('${i + 1}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(queue[i].title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('${queue[i].client.name} • vence ${formatDate(queue[i].dueAt)}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ])),
            AppStatusChip(label: 'P${queue[i].priority}', color: Theme.of(context).colorScheme.primary),
          ])),
          const SizedBox(height: 8),
        ],
      ]),
    ),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

IconData _searchIcon(String icon) => switch (icon) {
  'client' => Icons.person_outline_rounded,
  'order' => Icons.shopping_bag_outlined,
  'material' => Icons.shelves,
  _ => Icons.search_rounded,
};
