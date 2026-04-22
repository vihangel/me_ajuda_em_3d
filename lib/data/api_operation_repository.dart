import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../core/business_rules.dart';
import '../core/p3d_models.dart';
import 'operation_repository.dart';

class ApiOperationRepository implements OperationRepository {
  ApiOperationRepository({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  String get _base => ApiConfig.baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  Map<String, String> get _json => {'Content-Type': 'application/json'};

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    final res = await _client.get(_uri('/dashboard'));
    if (res.statusCode != 200) throw Exception('Erro ao carregar dashboard');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
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
    final res = await _client.get(_uri('/materials'));
    if (res.statusCode != 200) throw Exception('Erro ao carregar materiais');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => _parseFilament(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<SupplyItem>> getSupplies() async {
    final res = await _client.get(_uri('/supplies'));
    if (res.statusCode != 200) throw Exception('Erro ao carregar insumos');
    final list = jsonDecode(res.body) as List;
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
    final res = await _client.post(
      _uri('/materials'),
      headers: _json,
      body: jsonEncode({
        'brand': brand,
        'material': material,
        'finish': finish,
        'colorName': colorName,
        'colorHex': colorHex,
        'rollGrams': rollGrams,
        'remainingGrams': remainingGrams,
        'costCents': costCents,
        'lowStockGrams': lowStockGrams,
      }),
    );
    if (res.statusCode != 201) throw Exception('Erro ao cadastrar filamento');
    return _parseFilament(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Quotes
  // ---------------------------------------------------------------------------

  @override
  Future<List<QuoteTemplate>> getTemplates() async {
    final res = await _client.get(_uri('/templates'));
    if (res.statusCode != 200) throw Exception('Erro ao carregar templates');
    final list = jsonDecode(res.body) as List;
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
    final res = await _client.get(_uri('/quotes'));
    if (res.statusCode != 200) throw Exception('Erro ao carregar orcamentos');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => _parseQuote(e as Map<String, dynamic>)).toList();
  }

  // ---------------------------------------------------------------------------
  // Jobs
  // ---------------------------------------------------------------------------

  @override
  Future<List<ProductionJob>> getJobs() async {
    final res = await _client.get(_uri('/jobs'));
    if (res.statusCode != 200) throw Exception('Erro ao carregar producao');
    final list = jsonDecode(res.body) as List;
    final jobs =
        list.map((e) => _parseJob(e as Map<String, dynamic>)).toList();
    return buildQueueOrder(jobs);
  }

  // ---------------------------------------------------------------------------
  // Clients
  // ---------------------------------------------------------------------------

  @override
  Future<List<P3dClient>> getClients() async {
    final res = await _client.get(_uri('/clients'));
    if (res.statusCode != 200) throw Exception('Erro ao carregar clientes');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => _parseClient(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<P3dClient> createClient({
    required String name,
    required String phone,
    required String channel,
    required String notes,
  }) async {
    final res = await _client.post(
      _uri('/clients'),
      headers: _json,
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'channel': channel,
        'notes': notes,
      }),
    );
    if (res.statusCode != 201) throw Exception('Erro ao criar cliente');
    return _parseClient(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Customer orders (rota pública)
  // ---------------------------------------------------------------------------

  @override
  Future<List<CustomerProduct>> getCustomerProducts() async {
    final res = await _client.get(_uri('/customer-products'));
    if (res.statusCode != 200) throw Exception('Erro ao carregar produtos');
    final list = jsonDecode(res.body) as List;
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
  Future<List<CustomerOrder>> getCustomerOrdersByEmail(String email) async {
    final res = await _client.get(
      _uri('/customer-orders', {'email': email.trim().toLowerCase()}),
    );
    if (res.statusCode != 200) throw Exception('Erro ao buscar pedidos');
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => _parseCustomerOrder(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CustomerOrder> createCustomerOrder(
    CreateCustomerOrderInput input,
  ) async {
    final res = await _client.post(
      _uri('/customer-orders'),
      headers: _json,
      body: jsonEncode({
        'customerName': input.customerName,
        'email': input.email,
        'phone': input.phone,
        'kind': input.kind.name,
        'productTitle': input.productTitle,
        'description': input.description,
        'quantity': input.quantity,
        'hasReferenceImage': input.hasReferenceImage,
      }),
    );
    if (res.statusCode != 201) throw Exception('Erro ao criar pedido');
    return _parseCustomerOrder(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Search & Notifications
  // ---------------------------------------------------------------------------

  @override
  Future<List<GlobalSearchResult>> search(String query) async {
    final res = await _client.get(_uri('/search', {'q': query}));
    if (res.statusCode != 200) return const [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    final results = <GlobalSearchResult>[];

    for (final order in (data['orders'] as List?) ?? []) {
      final m = order as Map<String, dynamic>;
      results.add(GlobalSearchResult(
        title: '#${m['code']} ${m['productTitle']}',
        subtitle: '${m['customerName']} • ${m['status']}',
        type: 'Pedido',
        icon: 'order',
      ));
    }
    for (final client in (data['clients'] as List?) ?? []) {
      final m = client as Map<String, dynamic>;
      results.add(GlobalSearchResult(
        title: m['name'] as String? ?? '',
        subtitle: '${m['phone']} • ${m['channel']}',
        type: 'Cliente',
        icon: 'client',
      ));
    }
    for (final mat in (data['materials'] as List?) ?? []) {
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
    final res = await _client.get(_uri('/notifications'));
    if (res.statusCode != 200) return const [];
    final list = jsonDecode(res.body) as List;
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

  static Filament _parseFilament(Map<String, dynamic> m) {
    return Filament(
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
  }

  static SupplyItem _parseSupply(Map<String, dynamic> m) {
    return SupplyItem(
      id: m['_id']?.toString() ?? m['id']?.toString() ?? '',
      title: m['title'] as String? ?? '',
      category: m['category'] as String? ?? '',
      quantity: m['quantity'] as int? ?? 0,
      minimumQuantity: m['minimumQuantity'] as int? ?? 0,
      unitCostCents: m['unitCostCents'] as int? ?? 0,
    );
  }

  static P3dClient _parseClient(Map<String, dynamic> m) {
    return P3dClient(
      id: m['_id']?.toString() ?? m['id']?.toString() ?? '',
      name: m['name'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      channel: m['channel'] as String? ?? '',
      notes: m['notes'] as String? ?? '',
      currentStatus: m['currentStatus'] as String? ?? 'Novo',
      lastQuoteLabel: m['lastQuoteLabel'] as String? ?? 'Sem orcamento',
    );
  }

  static CustomerOrder _parseCustomerOrder(Map<String, dynamic> m) {
    return CustomerOrder(
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
  }

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
