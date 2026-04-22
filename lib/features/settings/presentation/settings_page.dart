import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SettingField(
            icon: Icons.schedule,
            label: 'Custo hora da maquina',
            value: 'R\$ 10,80',
          ),
          _SettingField(
            icon: Icons.brush_outlined,
            label: 'Arte padrao',
            value: 'R\$ 25,00',
          ),
          _SettingField(
            icon: Icons.event_available,
            label: 'Prazo padrao',
            value: '3 dias',
          ),
          _SettingField(
            icon: Icons.percent,
            label: 'Taxa variavel',
            value: '8%',
          ),
          _SettingField(
            icon: Icons.trending_up,
            label: 'Margem desejada',
            value: '35%',
          ),
          _SettingField(
            icon: Icons.message_outlined,
            label: 'Texto padrao de entrega',
            value: 'Seu pedido esta pronto para retirada.',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _SettingField extends StatelessWidget {
  const _SettingField({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.edit_outlined, color: colors.onSurfaceVariant),
      ),
    );
  }
}
