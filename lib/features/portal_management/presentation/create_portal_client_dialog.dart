import 'package:flutter/material.dart';

import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';

/// Dialog para cadastrar um novo cliente no portal.
Future<void> showCreatePortalClientDialog(
  BuildContext context,
  OperationRepository repo,
  VoidCallback refresh,
) async {
  final nameCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final employeeCtrl = TextEditingController(text: '1');

  String generatedCode = '';

  void updateCode(void Function(void Function()) set) {
    final name = nameCtrl.text.trim().toLowerCase();
    final company = companyCtrl.text.trim().toLowerCase();
    if (name.isEmpty || company.isEmpty) {
      set(() => generatedCode = '');
      return;
    }
    final parts = name.split(' ');
    final firstName = parts.first;
    final lastInitial = parts.length > 1 ? parts.last[0] : '';
    final companyClean = company.replaceAll(RegExp(r'[^a-z0-9]'), '');
    set(() {
      generatedCode = '$firstName-$lastInitial-$companyClean';
    });
  }

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => AlertDialog(
        title: const Text('Novo cliente do portal'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  hintText: 'Luiz Almeida',
                ),
                onChanged: (_) => updateCode(set),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome da empresa',
                  hintText: 'Banca do Luiz',
                ),
                onChanged: (_) => updateCode(set),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: '(65) 99800-1234',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: employeeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Numero de funcionarios',
                ),
                keyboardType: TextInputType.number,
              ),
              if (generatedCode.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Codigo de acesso',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              generatedCode,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          GradientButton(
            label: 'Cadastrar',
            compact: true,
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty ||
                  companyCtrl.text.trim().isEmpty) {
                return;
              }
              await repo.createPortalClient(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                channel: 'portal',
                notes: '',
                portalCode: generatedCode,
                companyName: companyCtrl.text.trim(),
                employeeCount: int.tryParse(employeeCtrl.text) ?? 1,
              );
              if (context.mounted) Navigator.pop(context);
              refresh();
            },
          ),
        ],
      ),
    ),
  );
}
