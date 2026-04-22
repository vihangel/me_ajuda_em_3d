import 'p3d_models.dart';

QuoteCalculationResult calculateQuoteTotals(QuoteCalculationInput input) {
  final filamentUnitCost = input.rollCostCents / input.rollGrams;
  final filamentCost = (filamentUnitCost * input.estimatedGrams).round();
  final machineCost = input.estimatedMinutes * input.machineMinuteCents;
  final finishingCost = input.finishingMinutes * input.laborMinuteCents;
  final subtotal =
      filamentCost +
      input.suppliesCostCents +
      machineCost +
      finishingCost +
      input.artFeeCents;
  final minimumPrice = subtotal / (1 - input.variableTaxPct);
  final suggestedUnitPrice = minimumPrice / (1 - input.desiredMarginPct);

  return QuoteCalculationResult(
    filamentCostCents: filamentCost,
    suppliesCostCents: input.suppliesCostCents,
    machineCostCents: machineCost,
    finishingCostCents: finishingCost,
    operationalSubtotalCents: subtotal,
    minimumPriceCents: minimumPrice.round(),
    suggestedPriceCents: (suggestedUnitPrice * input.quantity).round(),
  );
}

List<ProductionJob> buildQueueOrder(List<ProductionJob> jobs) {
  final ordered = [...jobs]
    ..sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;

      final dueCompare = a.dueAt.compareTo(b.dueAt);
      if (dueCompare != 0) return dueCompare;

      return a.queueOrder.compareTo(b.queueOrder);
    });

  return ordered;
}

String deriveJobPriorityLabel(ProductionJob job) {
  if (job.priority >= 3) return 'Urgente';
  if (job.dueAt.difference(DateTime.now()).inDays <= 1) return 'Prazo curto';
  return 'Normal';
}

int estimateLeadTimeDays({
  required int printMinutes,
  required int finishingMinutes,
  required int queueJobsAhead,
}) {
  final workMinutesPerDay = 6 * 60;
  final totalMinutes = printMinutes + finishingMinutes + (queueJobsAhead * 90);
  final days = (totalMinutes / workMinutesPerDay).ceil();
  return days < 1 ? 1 : days;
}
