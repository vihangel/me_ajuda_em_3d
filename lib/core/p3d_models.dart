enum QuoteStatus {
  draft('Rascunho'),
  sent('Enviado'),
  approved('Aprovado'),
  rejected('Recusado');

  const QuoteStatus(this.label);
  final String label;
}

enum JobStatus {
  briefing('Briefing'),
  quoted('Orcado'),
  approved('Aprovado'),
  queue('Fila'),
  printing('Imprimindo'),
  finishing('Acabamento'),
  readyPickup('Pronto'),
  delivered('Entregue'),
  canceled('Cancelado');

  const JobStatus(this.label);
  final String label;
}

enum FilamentStatus {
  ok('OK'),
  low('Baixo'),
  empty('Vazio');

  const FilamentStatus(this.label);
  final String label;
}

enum CustomerKind {
  person('Pessoa fisica'),
  company('Empresa');

  const CustomerKind(this.label);
  final String label;
}

enum CustomerOrderStatus {
  received('Recebido'),
  reviewing('Em analise'),
  quoted('Orcado'),
  approved('Aprovado'),
  production('Producao'),
  ready('Pronto'),
  closed('Encerrado');

  const CustomerOrderStatus(this.label);
  final String label;
}

class CustomerProduct {
  const CustomerProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.examples,
    required this.fromPriceCents,
    required this.needsImage,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final List<String> examples;
  final int fromPriceCents;
  final bool needsImage;
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.code,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.kind,
    required this.productTitle,
    required this.description,
    required this.quantity,
    required this.hasReferenceImage,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String customerName;
  final String email;
  final String phone;
  final CustomerKind kind;
  final String productTitle;
  final String description;
  final int quantity;
  final bool hasReferenceImage;
  final CustomerOrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CreateCustomerOrderInput {
  const CreateCustomerOrderInput({
    required this.customerName,
    required this.email,
    required this.phone,
    required this.kind,
    required this.productTitle,
    required this.description,
    required this.quantity,
    required this.hasReferenceImage,
  });

  final String customerName;
  final String email;
  final String phone;
  final CustomerKind kind;
  final String productTitle;
  final String description;
  final int quantity;
  final bool hasReferenceImage;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.severity,
    this.read = false,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String severity;
  final bool read;
}

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String type;
  final String icon;
}

class DashboardSummary {
  const DashboardSummary({
    required this.pendingQuotes,
    required this.inProduction,
    required this.readyPickup,
    required this.lowFilaments,
    required this.criticalDeadlines,
  });

  final int pendingQuotes;
  final int inProduction;
  final int readyPickup;
  final int lowFilaments;
  final int criticalDeadlines;
}

class P3dClient {
  const P3dClient({
    required this.id,
    required this.name,
    required this.phone,
    required this.channel,
    required this.notes,
    required this.currentStatus,
    required this.lastQuoteLabel,
  });

  final String id;
  final String name;
  final String phone;
  final String channel;
  final String notes;
  final String currentStatus;
  final String lastQuoteLabel;
}

class Filament {
  const Filament({
    required this.id,
    required this.brand,
    required this.material,
    required this.finish,
    required this.colorName,
    required this.colorHex,
    required this.rollGrams,
    required this.remainingGrams,
    required this.costCents,
    required this.lowStockGrams,
    required this.lot,
  });

  final String id;
  final String brand;
  final String material;
  final String finish;
  final String colorName;
  final int colorHex;
  final int rollGrams;
  final int remainingGrams;
  final int costCents;
  final int lowStockGrams;
  final String lot;

  FilamentStatus get status {
    if (remainingGrams <= 0) return FilamentStatus.empty;
    if (remainingGrams <= lowStockGrams) return FilamentStatus.low;
    return FilamentStatus.ok;
  }

  double get remainingRatio => remainingGrams / rollGrams;
}

class SupplyItem {
  const SupplyItem({
    required this.id,
    required this.title,
    required this.category,
    required this.quantity,
    required this.minimumQuantity,
    required this.unitCostCents,
  });

  final String id;
  final String title;
  final String category;
  final int quantity;
  final int minimumQuantity;
  final int unitCostCents;

  bool get isLow => quantity <= minimumQuantity;
}

class QuoteTemplate {
  const QuoteTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.basePriceCents,
    required this.artFeeCents,
    required this.gramsEstimate,
    required this.printMinutesEstimate,
    required this.defaultDeadlineDays,
  });

  final String id;
  final String title;
  final String category;
  final int basePriceCents;
  final int artFeeCents;
  final int gramsEstimate;
  final int printMinutesEstimate;
  final int defaultDeadlineDays;
}

class QuoteItem {
  const QuoteItem({
    required this.title,
    required this.quantity,
    required this.material,
    required this.finish,
    required this.color,
    required this.gramsEstimate,
    required this.printMinutesEstimate,
    required this.artFeeCents,
    required this.unitPriceCents,
  });

  final String title;
  final int quantity;
  final String material;
  final String finish;
  final String color;
  final int gramsEstimate;
  final int printMinutesEstimate;
  final int artFeeCents;
  final int unitPriceCents;
}

class Quote {
  const Quote({
    required this.id,
    required this.code,
    required this.client,
    required this.status,
    required this.items,
    required this.discountCents,
    required this.deadlineDays,
    required this.createdAt,
    this.approvedAt,
    this.notes = '',
  });

  final String id;
  final String code;
  final P3dClient client;
  final QuoteStatus status;
  final List<QuoteItem> items;
  final int discountCents;
  final int deadlineDays;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String notes;

  int get subtotalCents => items.fold<int>(
    0,
    (sum, item) => sum + (item.unitPriceCents * item.quantity),
  );

  int get finalTotalCents => subtotalCents - discountCents;
}

class JobUpdate {
  const JobUpdate({
    required this.statusSnapshot,
    required this.unitsDone,
    required this.messageInternal,
    required this.messageClient,
    required this.sentToClient,
    required this.createdAt,
  });

  final JobStatus statusSnapshot;
  final int unitsDone;
  final String messageInternal;
  final String messageClient;
  final bool sentToClient;
  final DateTime createdAt;
}

class ProductionJob {
  const ProductionJob({
    required this.id,
    required this.quoteCode,
    required this.client,
    required this.title,
    required this.status,
    required this.priority,
    required this.queueOrder,
    required this.unitsTotal,
    required this.unitsDone,
    required this.unitsFailed,
    required this.dueAt,
    required this.material,
    required this.updates,
    this.startedAt,
    this.readyAt,
  });

  final String id;
  final String quoteCode;
  final P3dClient client;
  final String title;
  final JobStatus status;
  final int priority;
  final int queueOrder;
  final int unitsTotal;
  final int unitsDone;
  final int unitsFailed;
  final DateTime dueAt;
  final String material;
  final List<JobUpdate> updates;
  final DateTime? startedAt;
  final DateTime? readyAt;

  int get unitsRemaining => unitsTotal - unitsDone - unitsFailed;
}

class QuoteCalculationInput {
  const QuoteCalculationInput({
    required this.rollCostCents,
    required this.rollGrams,
    required this.estimatedGrams,
    required this.estimatedMinutes,
    required this.machineMinuteCents,
    required this.finishingMinutes,
    required this.laborMinuteCents,
    required this.artFeeCents,
    required this.suppliesCostCents,
    required this.variableTaxPct,
    required this.desiredMarginPct,
    required this.quantity,
  });

  final int rollCostCents;
  final int rollGrams;
  final int estimatedGrams;
  final int estimatedMinutes;
  final int machineMinuteCents;
  final int finishingMinutes;
  final int laborMinuteCents;
  final int artFeeCents;
  final int suppliesCostCents;
  final double variableTaxPct;
  final double desiredMarginPct;
  final int quantity;
}

class QuoteCalculationResult {
  const QuoteCalculationResult({
    required this.filamentCostCents,
    required this.suppliesCostCents,
    required this.machineCostCents,
    required this.finishingCostCents,
    required this.operationalSubtotalCents,
    required this.minimumPriceCents,
    required this.suggestedPriceCents,
  });

  final int filamentCostCents;
  final int suppliesCostCents;
  final int machineCostCents;
  final int finishingCostCents;
  final int operationalSubtotalCents;
  final int minimumPriceCents;
  final int suggestedPriceCents;
}
