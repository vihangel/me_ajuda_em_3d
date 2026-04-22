import '../core/business_rules.dart';
import '../core/p3d_models.dart';
import 'operation_repository.dart';
import 'services/api_client.dart';

/// Repository that talks to the backend through [ApiClient].
///
/// All HTTP details (headers, token refresh, 401 handling) are delegated
/// to the client — this class only maps JSON ↔ domain models.
class ApiOperationRepository implements OperationRepository {
  ApiOperationRepository({required this.client});

  final ApiClient client;

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    final data = await client.get('/dashboard') as Map<String, dynamic>;
    return DashboardSummary(
      pendingQuotes: data['pendingQuotes'] as int? ?? 0,
      inProduction: data['inProduction'] as int? ?? 0,
      readyPickup: data['readyPickup'] as int? ?? 0,
      lowFilaments: data['lowFilaments'] as int? ?? 0,
      criticalDeadlines: data['criticalDeadlines'] as int? ?? 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Materials
  // ---------------------------------------------------------------------------

  @override
  Future<List<Filament>> getFilaments() async {
    final list = await client.get('/materials') as List;
    return list.map((e) => _parseFilament(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<SupplyItem>> getSupplies() async {
    final list = await client.get('/supplies') as List;
    return list.map((e) => _parseSupply(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Filament> createFilament({
    required String brand,
    required String material,
    required String finish,
    required String colorName,
    required int colorHex,
    required int rollGrams,
    required int remainingGrams,
    required int costCents,
    required int lowStockGrams,
  }) async {
    final data = await client.post('/materials', {
      'brand': brand,
      'material': material,
      'finish': finish,
      'colorName': colorName,
      'colorHex': colorHex,
      'rollGrams': rollGrams,
      'remainingGrams': remainingGrams,
      'costCents': costCents,
      'lowStockGrams': lowStockGrams,
    });
    return _parseFilament(data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Quotes
  // ---------------------------------------------------------------------------

  @override
  Future<List<QuoteTemplate>> getTemplates() async {
    final list = await client.get('/templates') as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return QuoteTemplate(
        id: m['_id']?.toString() ?? m['id']?.toString() ?? '',
        title: m['title'] as String? ?? '',
        category: m['category'] as String? ?? '',
        basePriceCents: m['basePriceCents'] as int? ?? 0,
        artFeeCents: m['artFeeCents'] as int? ?? 0,
        gramsEstimate: m['gramsEstimate'] as int? ?? 0,
        printMinutesEstimate: m['printMinutesEstimate'] as int? ?? 0,
        defaultDeadlineDays: m['defaultDeadlineDays'] as int? ?? 3,
      );
    }).toList();
  }

  @override
  Future<List<Quote>> getQuotes() async {
    final list = await client.get('/quotes') as List;
    return list.map((e) => _parseQuote(e as Map<String, dynamic>)).toList();
  }

  // ---------------------------------------------------------------------------
  // Jobs
  // ---------------------------------------------------------------------------

  @override
  Future<List<ProductionJob>> getJobs() async {
    final list = await client.get('/jobs') as List;
    final jobs =
        list.map((e) => _parseJob(e as Map<String, dynamic>)).toList();
    return buildQueueOrder(jobs);
  }

  // ---------------------------------------------------------------------------
  // Clients
  // ---------------------------------------------------------------------------

  @override
  Future<List<P3dClient>> getClients() async {
    final list = await client.get('/clients') as List;
    return list.map((e) => _parseClient(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<P3dClient> createClient({
    required String name,
    required String phone,
    required String channel,
    required String notes,
  }) async {
    final data = await client.post('/clients', {
      'name': name,
      'phone': phone,
      'channel': channel,
      'notes': notes,
    });
    return _parseClient(data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Customer orders (rota publica)
  // ---------------------------------------------------------------------------

  @override
  Future<List<CustomerProduct>> getCustomerProducts() async {
    final list = await client.get('/customer-products') as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return CustomerProduct(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        icon: m['icon'] as String? ?? 'other',
        examples: (m['examples'] as List?)?.cast<String>() ?? const [],
        fromPriceCents: m['fromPriceCents'] as int? ?? 0,
        needsImage: m['needsImage'] as bool? ?? false,
      );
    }).toList();
  }

  @override
  Future<List<CatalogItem>> getCatalogItems(String categoryId) async {
    final data = await client.get(
      '/catalog',
      queryParams: {'categoryId': categoryId},
    );
    if (data == null) return const [];
    final list = data as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return CatalogItem(
        id: m['_id']?.toString() ?? m['id']?.toString() ?? '',
        categoryId: m['categoryId'] as String? ?? '',
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        style: m['style'] as String? ?? '',
        priceCents: m['priceCents'] as int? ?? 0,
        imageTag: m['imageTag'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<List<CustomerOrder>> getCustomerOrdersByEmail(String email) async {
    final list = await client.get(
      '/customer-orders',
      queryParams: {'email': email.trim().toLowerCase()},
    ) as List;
    return list
        .map((e) => _parseCustomerOrder(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CustomerOrder> createCustomerOrder(
    CreateCustomerOrderInput input,
  ) async {
    final data = await client.post('/customer-orders', {
      'customerName': input.customerName,
      'email': input.email,
      'phone': input.phone,
      'kind': input.kind.name,
      'productTitle': input.productTitle,
      'description': input.description,
      'quantity': input.quantity,
      'hasReferenceImage': input.hasReferenceImage,
    });
    return _parseCustomerOrder(data as Map<String, dynamic>);
  }

  @override
  Future<void> updateCustomerOrderStatus(
    String id,
    CustomerOrderStatus status,
  ) async {
    await client.patch('/customer-orders/$id/status', {
      'status': status.name,
    });
  }

  @override
  Future<void> updateJobStatus(String id, JobStatus status) async {
    await client.patch('/jobs/$id/status', {
      'status': status.name,
    });
  }

  @override
  Future<void> updateMaterial(String id, Map<String, dynamic> fields) async {
    await client.patch('/materials/$id', fields);
  }

  // ---------------------------------------------------------------------------
  // Search & Notifications
  // ---------------------------------------------------------------------------

  @override
  Future<List<GlobalSearchResult>> search(String query) async {
    final data = await client.get('/search', queryParams: {'q': query});
    if (data == null) return const [];
    final map = data as Map<String, dynamic>;
    final results = <GlobalSearchResult>[];

    for (final order in (map['orders'] as List?) ?? []) {
      final m = order as Map<String, dynamic>;
      results.add(GlobalSearchResult(
        title: '#${m['code']} ${m['productTitle']}',
        subtitle: '${m['customerName']} • ${m['status']}',
        type: 'Pedido',
        icon: 'order',
      ));
    }
    for (final c in (map['clients'] as List?) ?? []) {
      final m = c as Map<String, dynamic>;
      results.add(GlobalSearchResult(
        title: m['name'] as String? ?? '',
        subtitle: '${m['phone']} • ${m['channel']}',
        type: 'Cliente',
        icon: 'client',
      ));
    }
    for (final mat in (map['materials'] as List?) ?? []) {
      final m = mat as Map<String, dynamic>;
      results.add(GlobalSearchResult(
        title: '${m['material']} ${m['colorName']}',
        subtitle: '${m['brand']} • ${m['remainingGrams']}g',
        type: 'Material',
        icon: 'material',
      ));
    }

    return results.take(12).toList();
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    final data = await client.get('/notifications');
    if (data == null) return const [];
    final list = data as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return AppNotification(
        id: m['_id']?.toString() ?? '',
        title: m['title'] as String? ?? '',
        message: m['message'] as String? ?? '',
        severity: m['severity'] as String? ?? 'warning',
        createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Parsers
  // ---------------------------------------------------------------------------

  static Filament _parseFilament(Map<String, dynamic> m) => Filament(
        id: m['_id']?.toString() ?? m['id']?.toString() ?? '',
        brand: m['brand'] as String? ?? '',
        material: m['material'] as String? ?? '',
        finish: m['finish'] as String? ?? '',
        colorName: m['colorName'] as String? ?? '',
        colorHex: m['colorHex'] as int? ?? 0xFF888888,
        rollGrams: m['rollGrams'] as int? ?? 1000,
        remainingGrams: m['remainingGrams'] as int? ?? 0,
        costCents: m['costCents'] as int? ?? 0,
        lowStockGrams: m['lowStockGrams'] as int? ?? 200,
        lot: m['lot'] as String? ?? '',
      );

  static SupplyItem _parseSupply(Map<String, dynamic> m) => SupplyItem(
        id: m['_id']?.toString() ?? m['id']?.toString() ?? '',
        title: m['title'] as String? ?? '',
        category: m['category'] as String? ?? '',
        quantity: m['quantity'] as int? ?? 0,
        minimumQuantity: m['minimumQuantity'] as int? ?? 0,
        unitCostCents: m['unitCostCents'] as int? ?? 0,
      );

  static P3dClient _parseClient(Map<String, dynamic> m) => P3dClient(
        id: m['_id']?.toString() ?? m['id']?.toString() ?? '',
        name: m['name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        channel: m['channel'] as String? ?? '',
        notes: m['notes'] as String? ?? '',
        currentStatus: m['currentStatus'] as String? ?? 'Novo',
        lastQuoteLabel: m['lastQuoteLabel'] as String? ?? 'Sem orcamento',
      );

  static CustomerOrder _parseCustomerOrder(Map<String, dynamic> m) =>
      CustomerOrder(
        id: m['_id']?.toString() ?? m['id']?.toString() ?? '',
        code: m['code'] as String? ?? '',
        customerName: m['customerName'] as String? ?? '',
        email: m['email'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        kind: CustomerKind.values.firstWhere(
          (k) => k.name == (m['kind'] as String? ?? 'person'),
          orElse: () => CustomerKind.person,
        ),
        productTitle: m['productTitle'] as String? ?? '',
        description: m['description'] as String? ?? '',
        quantity: m['quantity'] as int? ?? 1,
        hasReferenceImage: m['hasReferenceImage'] as bool? ?? false,
        status: CustomerOrderStatus.values.firstWhere(
          (s) => s.name == (m['status'] as String? ?? 'received'),
          orElse: () => CustomerOrderStatus.received,
        ),
        createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(m['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
      );

  static Quote _parseQuote(Map<String, dynamic> m) {
    final items = (m['items'] as List?)?.map((e) {
          final i = e as Map<String, dynamic>;
          return QuoteItem(
            title: i['title'] as String? ?? '',
            quantity: i['quantity'] as int? ?? 1,
            material: i['material'] as String? ?? '',
            finish: i['finish'] as String? ?? '',
            color: i['color'] as String? ?? '',
            gramsEstimate: i['gramsEstimate'] as int? ?? 0,
            printMinutesEstimate: i['printMinutesEstimate'] as int? ?? 0,
            artFeeCents: i['artFeeCents'] as int? ?? 0,
            unitPriceCents: i['unitPriceCents'] as int? ?? 0,
          );
        }).toList() ??
        const [];

    return Quote(
      id: m['_id']?.toString() ?? m['id']?.toString() ?? '',
      code: m['code'] as String? ?? '',
      client: _parseClient(m['client'] as Map<String, dynamic>? ?? {}),
      status: QuoteStatus.values.firstWhere(
        (s) => s.name == (m['status'] as String? ?? 'draft'),
        orElse: () => QuoteStatus.draft,
      ),
      items: items,
      discountCents: m['discountCents'] as int? ?? 0,
      deadlineDays: m['deadlineDays'] as int? ?? 3,
      createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      approvedAt: m['approvedAt'] != null
          ? DateTime.tryParse(m['approvedAt'].toString())
          : null,
      notes: m['notes'] as String? ?? '',
    );
  }

  static ProductionJob _parseJob(Map<String, dynamic> m) {
    final updates = (m['updates'] as List?)?.map((e) {
          final u = e as Map<String, dynamic>;
          return JobUpdate(
            statusSnapshot: JobStatus.values.firstWhere(
              (s) => s.name == (u['statusSnapshot'] as String? ?? 'queue'),
              orElse: () => JobStatus.queue,
            ),
            unitsDone: u['unitsDone'] as int? ?? 0,
            messageInternal: u['messageInternal'] as String? ?? '',
            messageClient: u['messageClient'] as String? ?? '',
            sentToClient: u['sentToClient'] as bool? ?? false,
            createdAt: DateTime.tryParse(u['createdAt']?.toString() ?? '') ??
                DateTime.now(),
          );
        }).toList() ??
        const [];

    return ProductionJob(
      id: m['_id']?.toString() ?? m['id']?.toString() ?? '',
      quoteCode: m['quoteCode'] as String? ?? '',
      client: _parseClient(m['client'] as Map<String, dynamic>? ?? {}),
      title: m['title'] as String? ?? '',
      status: JobStatus.values.firstWhere(
        (s) => s.name == (m['status'] as String? ?? 'queue'),
        orElse: () => JobStatus.queue,
      ),
      priority: m['priority'] as int? ?? 1,
      queueOrder: m['queueOrder'] as int? ?? 0,
      unitsTotal: m['unitsTotal'] as int? ?? 0,
      unitsDone: m['unitsDone'] as int? ?? 0,
      unitsFailed: m['unitsFailed'] as int? ?? 0,
      dueAt: DateTime.tryParse(m['dueAt']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      material: m['material'] as String? ?? '',
      updates: updates,
      startedAt: m['startedAt'] != null
          ? DateTime.tryParse(m['startedAt'].toString())
          : null,
      readyAt: m['readyAt'] != null
          ? DateTime.tryParse(m['readyAt'].toString())
          : null,
    );
  }
}
