import 'package:flutter/material.dart';

import '../../../core/business_rules.dart';
import '../../../core/formatters.dart';
import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _rollCost = TextEditingController(text: '89.90');
  final _rollGrams = TextEditingController(text: '1000');
  final _estimatedGrams = TextEditingController(text: '420');
  final _estimatedMinutes = TextEditingController(text: '840');
  final _machineMinuteCents = TextEditingController(text: '18');
  final _finishingMinutes = TextEditingController(text: '45');
  final _laborMinuteCents = TextEditingController(text: '42');
  final _artFee = TextEditingController(text: '25.00');
  final _suppliesCost = TextEditingController(text: '12.60');
  final _taxPct = TextEditingController(text: '8');
  final _marginPct = TextEditingController(text: '35');
  final _quantity = TextEditingController(text: '30');

  QuoteCalculationResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _rollCost.dispose();
    _rollGrams.dispose();
    _estimatedGrams.dispose();
    _estimatedMinutes.dispose();
    _machineMinuteCents.dispose();
    _finishingMinutes.dispose();
    _laborMinuteCents.dispose();
    _artFee.dispose();
    _suppliesCost.dispose();
    _taxPct.dispose();
    _marginPct.dispose();
    _quantity.dispose();
    super.dispose();
  }

  int _reais(String text) => ((double.tryParse(text) ?? 0) * 100).round();
  int _intVal(String text) => int.tryParse(text) ?? 0;
  double _pct(String text) => (double.tryParse(text) ?? 0) / 100;

  void _calculate() {
    final input = QuoteCalculationInput(
      rollCostCents: _reais(_rollCost.text),
      rollGrams: _intVal(_rollGrams.text),
      estimatedGrams: _intVal(_estimatedGrams.text),
      estimatedMinutes: _intVal(_estimatedMinutes.text),
      machineMinuteCents: _intVal(_machineMinuteCents.text),
      finishingMinutes: _intVal(_finishingMinutes.text),
      laborMinuteCents: _intVal(_laborMinuteCents.text),
      artFeeCents: _reais(_artFee.text),
      suppliesCostCents: _reais(_suppliesCost.text),
      variableTaxPct: _pct(_taxPct.text),
      desiredMarginPct: _pct(_marginPct.text),
      quantity: _intVal(_quantity.text),
    );
    setState(() => _result = calculateQuoteTotals(input));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final twoColumns = width > 900;

    final form = _buildForm(context);
    final resultCard = _buildResult(context);

    if (twoColumns) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: form),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: resultCard),
            ],
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [form, const SizedBox(height: 16), resultCard],
    );
  }

  Widget _buildForm(BuildContext context) {
    return SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parametros de custo',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _field('Custo do rolo (R\$)', _rollCost),
          _field('Peso do rolo (g)', _rollGrams),
          _field('Peso estimado da peca (g)', _estimatedGrams),
          _field('Tempo de impressao (min)', _estimatedMinutes),
          _field('Custo maquina (centavos/min)', _machineMinuteCents),
          _field('Tempo acabamento (min)', _finishingMinutes),
          _field('Custo mao de obra (centavos/min)', _laborMinuteCents),
          _field('Taxa de arte (R\$)', _artFee),
          _field('Custo insumos (R\$)', _suppliesCost),
          _field('Imposto variavel (%)', _taxPct),
          _field('Margem desejada (%)', _marginPct),
          _field('Quantidade', _quantity),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              icon: Icons.calculate_rounded,
              label: 'Calcular',
              onPressed: _calculate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final r = _result;
    if (r == null) {
      return const SoftPanel(
        child: EmptyStateView(
          title: 'Sem calculo',
          message: 'Preencha os campos e clique em Calcular.',
        ),
      );
    }

    return SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultado',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _resultRow('Custo filamento', formatMoney(r.filamentCostCents)),
          _resultRow('Custo insumos', formatMoney(r.suppliesCostCents)),
          _resultRow('Custo maquina', formatMoney(r.machineCostCents)),
          _resultRow('Custo acabamento', formatMoney(r.finishingCostCents)),
          const Divider(height: 24),
          _resultRow(
            'Subtotal operacional',
            formatMoney(r.operationalSubtotalCents),
            bold: true,
          ),
          _resultRow(
            'Preco minimo (c/ imposto)',
            formatMoney(r.minimumPriceCents),
          ),
          const Divider(height: 24),
          _resultRow(
            'Preco sugerido total',
            formatMoney(r.suggestedPriceCents),
            bold: true,
            color: Theme.of(context).colorScheme.primary,
          ),
          if (_intVal(_quantity.text) > 0) ...[
            const SizedBox(height: 4),
            _resultRow(
              'Preco unitario sugerido',
              formatMoney(r.suggestedPriceCents ~/ _intVal(_quantity.text)),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calculo usa a funcao pura calculateQuoteTotals. '
                    'Ajuste os parametros para simular cenarios diferentes.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
