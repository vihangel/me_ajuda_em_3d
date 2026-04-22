import 'package:flutter/material.dart';

import '../../../core/ui_components.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _machineCost = '10,80';
  String _artFee = '25,00';
  String _defaultDeadline = '3';
  String _taxRate = '8';
  String _margin = '35';
  String _deliveryText = 'Seu pedido esta pronto para retirada.';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingCard(
          icon: Icons.schedule,
          label: 'Custo hora da maquina',
          value: 'R\$ $_machineCost',
          onEdit: () => _editSetting(
            title: 'Custo hora da maquina',
            currentValue: _machineCost,
            suffix: 'R\$',
            keyboard: TextInputType.numberWithOptions(decimal: true),
            onSave: (v) => setState(() => _machineCost = v),
          ),
        ),
        _SettingCard(
          icon: Icons.brush_outlined,
          label: 'Arte padrao',
          value: 'R\$ $_artFee',
          onEdit: () => _editSetting(
            title: 'Arte padrao',
            currentValue: _artFee,
            suffix: 'R\$',
            keyboard: TextInputType.numberWithOptions(decimal: true),
            onSave: (v) => setState(() => _artFee = v),
          ),
        ),
        _SettingCard(
          icon: Icons.event_available,
          label: 'Prazo padrao',
          value: '$_defaultDeadline dias',
          onEdit: () => _editSetting(
            title: 'Prazo padrao (dias)',
            currentValue: _defaultDeadline,
            keyboard: TextInputType.number,
            onSave: (v) => setState(() => _defaultDeadline = v),
          ),
        ),
        _SettingCard(
          icon: Icons.percent,
          label: 'Taxa variavel',
          value: '$_taxRate%',
          onEdit: () => _editSetting(
            title: 'Taxa variavel (%)',
            currentValue: _taxRate,
            keyboard: TextInputType.number,
            onSave: (v) => setState(() => _taxRate = v),
          ),
        ),
        _SettingCard(
          icon: Icons.trending_up,
          label: 'Margem desejada',
          value: '$_margin%',
          onEdit: () => _editSetting(
            title: 'Margem desejada (%)',
            currentValue: _margin,
            keyboard: TextInputType.number,
            onSave: (v) => setState(() => _margin = v),
          ),
        ),
        _SettingCard(
          icon: Icons.message_outlined,
          label: 'Texto padrao de entrega',
          value: _deliveryText,
          maxLines: 2,
          onEdit: () => _editSetting(
            title: 'Texto padrao de entrega',
            currentValue: _deliveryText,
            multiline: true,
            onSave: (v) => setState(() => _deliveryText = v),
          ),
        ),
      ],
    );
  }

  void _editSetting({
    required String title,
    required String currentValue,
    required ValueChanged<String> onSave,
    String? suffix,
    TextInputType? keyboard,
    bool multiline = false,
  }) {
    final controller = TextEditingController(text: currentValue);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 380,
          child: TextField(
            controller: controller,
            keyboardType: multiline
                ? TextInputType.multiline
                : (keyboard ?? TextInputType.text),
            minLines: multiline ? 2 : 1,
            maxLines: multiline ? 4 : 1,
            autofocus: true,
            decoration: InputDecoration(
              prefixText: suffix != null ? '$suffix ' : null,
              border: const OutlineInputBorder(),
            ),
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
              onSave(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title atualizado.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onEdit,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.primary, size: 22),
            ),
            const SizedBox(width: 14),
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
                  Text(
                    value,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
