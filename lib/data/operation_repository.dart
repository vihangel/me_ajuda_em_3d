import '../core/business_rules.dart';
import '../core/p3d_models.dart';

abstract class OperationRepository {
  Future<DashboardSummary> getDashboardSummary();
  Future<List<Filament>> getFilaments();
  Future<List<SupplyItem>> getSupplies();
  Future<List<QuoteTemplate>> getTemplates();
  Future<List<Quote>> getQuotes();
  Future<List<ProductionJob>> getJobs();
  Future<List<P3dClient>> getClients();
  Future<List<CustomerProduct>> getCustomerProducts();
  Future<List<CatalogItem>> getCatalogItems(String categoryId);
  Future<List<CustomerOrder>> getCustomerOrdersByEmail(String email);
  Future<CustomerOrder> createCustomerOrder(CreateCustomerOrderInput input);
  Future<void> updateCustomerOrderStatus(String id, CustomerOrderStatus status);
  Future<void> updateJobStatus(String id, JobStatus status);
  Future<void> updateMaterial(String id, Map<String, dynamic> fields);
  Future<P3dClient> createClient({
    required String name,
    required String phone,
    required String channel,
    required String notes,
  });
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
  });
  Future<List<GlobalSearchResult>> search(String query);
  Future<List<AppNotification>> getNotifications();

  // Portal do cliente (usa P3dClient com portalCode)
  Future<P3dClient?> portalLogin(String code);
  Future<List<P3dClient>> getPortalClients();
  Future<List<PortalProduct>> getPortalProducts(String clientId);
  Future<P3dClient> createPortalClient({
    required String name,
    required String phone,
    required String channel,
    required String notes,
    required String portalCode,
    required String companyName,
    required int employeeCount,
  });
  Future<PortalProduct> createPortalOrderRequest(
    String clientId,
    PortalOrderRequest request,
  );
  Future<void> updatePortalProductStatus(
    String productId,
    PortalProductStatus status,
  );
  Future<void> updatePortalProductPayment(String productId, int paidQuantity);

  // Pedidos (admin)
  Future<List<CustomerOrder>> getAllCustomerOrders();
}

class InMemoryOperationRepository implements OperationRepository {
  InMemoryOperationRepository();

  // ---------------------------------------------------------------------------
  // Portal do cliente — produtos vinculados a clientes por clientId
  // ---------------------------------------------------------------------------

  final List<_PortalProductEntry> _portalProducts = [
    _PortalProductEntry(
      clientId: 'cli_001',
      product: PortalProduct(
        id: 'pp_001',
        title: 'Caixinha de figurinha da Copa',
        description: '200 caixinhas personalizadas com logo da banca.',
        quantity: 200,
        paidQuantity: 120,
        unitPriceCents: 1490,
        status: PortalProductStatus.producing,
        paymentStatus: PortalProductPaymentStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ),
    _PortalProductEntry(
      clientId: 'cli_001',
      product: PortalProduct(
        id: 'pp_002',
        title: 'Chaveiro personalizado',
        description: '80 chaveiros com nome dos funcionarios.',
        quantity: 80,
        paidQuantity: 80,
        unitPriceCents: 1290,
        status: PortalProductStatus.delivering,
        paymentStatus: PortalProductPaymentStatus.paid,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ),
    _PortalProductEntry(
      clientId: 'cli_002',
      product: PortalProduct(
        id: 'pp_003',
        title: 'Placa com logo em relevo',
        description: 'Placa para recepcao do escritorio.',
        quantity: 1,
        paidQuantity: 0,
        unitPriceCents: 5990,
        status: PortalProductStatus.finishing,
        paymentStatus: PortalProductPaymentStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ),
  ];

  final List<P3dClient> _clients = [
    const P3dClient(
      id: 'cli_001',
      name: 'Marina Alves',
      phone: '(65) 99912-8844',
      channel: 'Instagram',
      notes: 'Prefere retirada no fim da tarde.',
      currentStatus: 'Na fila',
      lastQuoteLabel: '#3D-1042 chaveiros PLA',
      portalCode: 'marina-a-printflow',
      companyName: 'Atelie Marina',
      employeeCount: 2,
    ),
    const P3dClient(
      id: 'cli_002',
      name: 'Studio Nimbo',
      phone: '(65) 98144-2210',
      channel: 'WhatsApp',
      notes: 'Cliente recorrente de brindes.',
      currentStatus: 'Aguardando aprovacao',
      lastQuoteLabel: '#3D-1046 imas personalizados',
      portalCode: 'nimbo-s-studionimbo',
      companyName: 'Studio Nimbo',
      employeeCount: 4,
    ),
    const P3dClient(
      id: 'cli_003',
      name: 'Rafael Correa',
      phone: '(65) 99600-7130',
      channel: 'Indicacao',
      notes: 'Pediu acabamento premium.',
      currentStatus: 'Pronto',
      lastQuoteLabel: '#3D-1039 keycaps',
    ),
  ];

  final List<Filament> _extraFilaments = [];

  late final List<CustomerOrder> _customerOrders = [
    CustomerOrder(
      id: 'req_3001',
      code: 'PED-3001',
      customerName: 'Marina Alves',
      email: 'marina@email.com',
      phone: '(65) 99912-8844',
      kind: CustomerKind.person,
      productTitle: 'Chaveiro personalizado',
      description: '50 chaveiros com nome da turma.',
      quantity: 50,
      hasReferenceImage: true,
      status: CustomerOrderStatus.production,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    CustomerOrder(
      id: 'req_3002',
      code: 'PED-3002',
      customerName: 'Studio Nimbo',
      email: 'contato@studionimbo.com',
      phone: '(65) 98144-2210',
      kind: CustomerKind.company,
      productTitle: 'Quadro ou placa',
      description: 'Logo em relevo para recepcao.',
      quantity: 1,
      hasReferenceImage: true,
      status: CustomerOrderStatus.reviewing,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<DashboardSummary> getDashboardSummary() async {
    final quotes = await getQuotes();
    final jobs = await getJobs();
    final filaments = await getFilaments();
    final orders = await getAllCustomerOrders();
    final now = DateTime.now();

    // Count active portal products across all clients
    int portalActive = 0;
    for (final entry in _portalProducts) {
      if (entry.product.status != PortalProductStatus.delivered) {
        portalActive++;
      }
    }

    return DashboardSummary(
      pendingQuotes: quotes
          .where(
            (quote) =>
                quote.status == QuoteStatus.draft ||
                quote.status == QuoteStatus.sent,
          )
          .length,
      inProduction: jobs
          .where(
            (job) =>
                job.status == JobStatus.queue ||
                job.status == JobStatus.printing,
          )
          .length,
      readyPickup: jobs
          .where((job) => job.status == JobStatus.readyPickup)
          .length,
      lowFilaments: filaments
          .where((filament) => filament.status != FilamentStatus.ok)
          .length,
      criticalDeadlines: jobs
          .where(
            (job) =>
                job.dueAt.difference(now).inHours <= 36 &&
                job.status != JobStatus.delivered,
          )
          .length,
      pendingOrders: orders
          .where(
            (o) =>
                o.status != CustomerOrderStatus.closed &&
                o.status != CustomerOrderStatus.ready,
          )
          .length,
      portalActiveProducts: portalActive,
    );
  }

  @override
  Future<List<Filament>> getFilaments() async => [
    const Filament(
      id: 'fil_pla_preto',
      brand: 'Voolt3D',
      material: 'PLA',
      finish: 'Fosco',
      colorName: 'Preto',
      colorHex: 0xFF222222,
      rollGrams: 1000,
      remainingGrams: 180,
      costCents: 8990,
      lowStockGrams: 220,
      lot: 'L2409-A',
    ),
    const Filament(
      id: 'fil_pla_verde',
      brand: '3D Fila',
      material: 'PLA',
      finish: 'Silk',
      colorName: 'Verde metalico',
      colorHex: 0xFF0E8F74,
      rollGrams: 1000,
      remainingGrams: 620,
      costCents: 11290,
      lowStockGrams: 180,
      lot: 'S2511-V',
    ),
    const Filament(
      id: 'fil_petg_trans',
      brand: 'Cliever',
      material: 'PETG',
      finish: 'Translucido',
      colorName: 'Cristal',
      colorHex: 0xFFB8D8E8,
      rollGrams: 1000,
      remainingGrams: 0,
      costCents: 12990,
      lowStockGrams: 150,
      lot: 'P2501-C',
    ),
    ..._extraFilaments,
  ];

  @override
  Future<List<SupplyItem>> getSupplies() async => const [
    SupplyItem(
      id: 'sup_keyring',
      title: 'Argola para chaveiro',
      category: 'Chaveiro',
      quantity: 84,
      minimumQuantity: 40,
      unitCostCents: 28,
    ),
    SupplyItem(
      id: 'sup_magnet',
      title: 'Ima 8x2mm',
      category: 'Ima',
      quantity: 22,
      minimumQuantity: 30,
      unitCostCents: 42,
    ),
    SupplyItem(
      id: 'sup_pack',
      title: 'Embalagem kraft pequena',
      category: 'Embalagem',
      quantity: 115,
      minimumQuantity: 50,
      unitCostCents: 55,
    ),
  ];

  @override
  Future<List<QuoteTemplate>> getTemplates() async => const [
    QuoteTemplate(
      id: 'tpl_keyring',
      title: 'Chaveiro personalizado',
      category: 'Brinde',
      basePriceCents: 1490,
      artFeeCents: 2500,
      gramsEstimate: 18,
      printMinutesEstimate: 36,
      defaultDeadlineDays: 3,
    ),
    QuoteTemplate(
      id: 'tpl_magnet',
      title: 'Ima personalizado',
      category: 'Decoracao',
      basePriceCents: 1190,
      artFeeCents: 2000,
      gramsEstimate: 14,
      printMinutesEstimate: 28,
      defaultDeadlineDays: 3,
    ),
    QuoteTemplate(
      id: 'tpl_keycap',
      title: 'Acessorio de teclado',
      category: 'Acessorio',
      basePriceCents: 2890,
      artFeeCents: 3500,
      gramsEstimate: 22,
      printMinutesEstimate: 58,
      defaultDeadlineDays: 5,
    ),
  ];

  @override
  Future<List<Quote>> getQuotes() async {
    final templates = await getTemplates();
    return [
      Quote(
        id: 'quo_1046',
        code: '3D-1046',
        client: _clients[1],
        status: QuoteStatus.sent,
        items: [
          QuoteItem(
            title: templates[1].title,
            quantity: 30,
            material: 'PLA',
            finish: 'Pintura simples',
            color: 'Branco',
            gramsEstimate: 420,
            printMinutesEstimate: 840,
            artFeeCents: templates[1].artFeeCents,
            unitPriceCents: 1390,
          ),
        ],
        discountCents: 0,
        deadlineDays: 4,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        notes: 'Enviar mockup antes da aprovacao.',
      ),
      Quote(
        id: 'quo_1042',
        code: '3D-1042',
        client: _clients[0],
        status: QuoteStatus.approved,
        items: [
          QuoteItem(
            title: templates[0].title,
            quantity: 50,
            material: 'PLA',
            finish: 'Fosco',
            color: 'Preto',
            gramsEstimate: 900,
            printMinutesEstimate: 1800,
            artFeeCents: templates[0].artFeeCents,
            unitPriceCents: 1290,
          ),
        ],
        discountCents: 2500,
        deadlineDays: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        approvedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Quote(
        id: 'quo_1045',
        code: '3D-1045',
        client: _clients[2],
        status: QuoteStatus.draft,
        items: [
          QuoteItem(
            title: templates[2].title,
            quantity: 6,
            material: 'PETG',
            finish: 'Lixado',
            color: 'Cristal',
            gramsEstimate: 132,
            printMinutesEstimate: 348,
            artFeeCents: templates[2].artFeeCents,
            unitPriceCents: 3290,
          ),
        ],
        discountCents: 0,
        deadlineDays: 5,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<ProductionJob>> getJobs() async {
    final jobs = [
      ProductionJob(
        id: 'job_1042',
        quoteCode: '3D-1042',
        client: _clients[0],
        title: '50 chaveiros personalizados',
        status: JobStatus.printing,
        priority: 3,
        queueOrder: 2,
        unitsTotal: 50,
        unitsDone: 18,
        unitsFailed: 2,
        dueAt: DateTime.now().add(const Duration(days: 1)),
        material: 'PLA preto fosco',
        startedAt: DateTime.now().subtract(const Duration(hours: 8)),
        updates: [
          JobUpdate(
            statusSnapshot: JobStatus.printing,
            unitsDone: 18,
            messageInternal: 'Primeira placa saiu com duas falhas.',
            messageClient:
                'Seu pedido entrou em impressao e ja temos 18 unidades prontas.',
            sentToClient: true,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
      ),
      ProductionJob(
        id: 'job_1039',
        quoteCode: '3D-1039',
        client: _clients[2],
        title: '6 keycaps translucidas',
        status: JobStatus.readyPickup,
        priority: 1,
        queueOrder: 1,
        unitsTotal: 6,
        unitsDone: 6,
        unitsFailed: 0,
        dueAt: DateTime.now(),
        material: 'PETG cristal',
        readyAt: DateTime.now().subtract(const Duration(hours: 3)),
        updates: [
          JobUpdate(
            statusSnapshot: JobStatus.readyPickup,
            unitsDone: 6,
            messageInternal: 'Acabamento conferido.',
            messageClient: 'Seu pedido esta pronto para retirada.',
            sentToClient: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      ProductionJob(
        id: 'job_1047',
        quoteCode: '3D-1047',
        client: _clients[1],
        title: '12 imas com logo',
        status: JobStatus.queue,
        priority: 2,
        queueOrder: 3,
        unitsTotal: 12,
        unitsDone: 0,
        unitsFailed: 0,
        dueAt: DateTime.now().add(const Duration(days: 3)),
        material: 'PLA branco',
        updates: const [],
      ),
    ];

    return buildQueueOrder(jobs);
  }

  @override
  Future<List<P3dClient>> getClients() async => List.unmodifiable(_clients);

  @override
  Future<List<CustomerProduct>> getCustomerProducts() async => const [
    CustomerProduct(
      id: 'cat_keyring',
      title: 'Chaveiros',
      description: 'Chaveiros personalizados com nome, logo ou personagem.',
      icon: 'key',
      examples: ['brinde', 'nome', 'logo', 'evento'],
      fromPriceCents: 1290,
      needsImage: false,
    ),
    CustomerProduct(
      id: 'cat_miniature',
      title: 'Miniaturas',
      description: 'Bonecos, personagens, figuras e pecas colecionaveis.',
      icon: 'miniature',
      examples: ['boneco', 'personagem', 'figura', 'RPG'],
      fromPriceCents: 3990,
      needsImage: true,
    ),
    CustomerProduct(
      id: 'cat_decor',
      title: 'Decoracao',
      description: 'Pecas para mesa, parede, festas, nichos e ambientes.',
      icon: 'decor',
      examples: ['vaso', 'mesa', 'festa', 'presente'],
      fromPriceCents: 3490,
      needsImage: false,
    ),
    CustomerProduct(
      id: 'cat_sign',
      title: 'Placas e letreiros',
      description: 'Placas com relevo, letreiros, logos e quadros decorativos.',
      icon: 'frame',
      examples: ['logo 3D', 'letreiro', 'placa', 'quadro'],
      fromPriceCents: 5990,
      needsImage: false,
    ),
    CustomerProduct(
      id: 'cat_lamp',
      title: 'Luminarias',
      description: 'Luminarias decorativas, abajures e caixas de luz.',
      icon: 'lamp',
      examples: ['abajur', 'litofane', 'caixa de luz', 'LED'],
      fromPriceCents: 4990,
      needsImage: false,
    ),
    CustomerProduct(
      id: 'cat_other',
      title: 'Outros',
      description:
          'Peca tecnica, reposicao, suporte, organizador ou ideia livre.',
      icon: 'other',
      examples: ['peca tecnica', 'suporte', 'organizador', 'prototipo'],
      fromPriceCents: 2990,
      needsImage: false,
    ),
  ];

  static const _catalogItems = [
    // Chaveiros
    CatalogItem(
      id: 'ci_01',
      categoryId: 'cat_keyring',
      title: 'Chaveiro com nome',
      description: 'Nome em relevo, ate 10 letras.',
      style: 'Moderno',
      priceCents: 1490,
      imageTag: 'key_name',
    ),
    CatalogItem(
      id: 'ci_02',
      categoryId: 'cat_keyring',
      title: 'Chaveiro com logo',
      description: 'Logo da empresa ou time.',
      style: 'Corporativo',
      priceCents: 1890,
      imageTag: 'key_logo',
    ),
    CatalogItem(
      id: 'ci_03',
      categoryId: 'cat_keyring',
      title: 'Chaveiro personagem',
      description: 'Personagem simples estilizado.',
      style: 'Divertido',
      priceCents: 2290,
      imageTag: 'key_char',
    ),
    // Miniaturas
    CatalogItem(
      id: 'ci_04',
      categoryId: 'cat_miniature',
      title: 'Miniatura de personagem',
      description: 'Boneco ate 15cm de altura.',
      style: 'Detalhado',
      priceCents: 5990,
      imageTag: 'mini_char',
    ),
    CatalogItem(
      id: 'ci_05',
      categoryId: 'cat_miniature',
      title: 'Peca de RPG/tabuleiro',
      description: 'Miniaturas para jogos.',
      style: 'Fantasia',
      priceCents: 3490,
      imageTag: 'mini_rpg',
    ),
    // Decoracao
    CatalogItem(
      id: 'ci_06',
      categoryId: 'cat_decor',
      title: 'Vaso geometrico',
      description: 'Vaso decorativo low-poly.',
      style: 'Geometrico',
      priceCents: 4990,
      imageTag: 'decor_vase',
    ),
    CatalogItem(
      id: 'ci_07',
      categoryId: 'cat_decor',
      title: 'Porta-retrato 3D',
      description: 'Moldura com relevo tematico.',
      style: 'Classico',
      priceCents: 3990,
      imageTag: 'decor_frame',
    ),
    // Placas e letreiros
    CatalogItem(
      id: 'ci_08',
      categoryId: 'cat_sign',
      title: 'Letreiro de parede',
      description: 'Nome ou frase em relevo.',
      style: 'Moderno',
      priceCents: 6990,
      imageTag: 'sign_wall',
    ),
    CatalogItem(
      id: 'ci_09',
      categoryId: 'cat_sign',
      title: 'Placa de porta',
      description: 'Placa com nome e icone.',
      style: 'Minimalista',
      priceCents: 3990,
      imageTag: 'sign_door',
    ),
    // Luminarias
    CatalogItem(
      id: 'ci_10',
      categoryId: 'cat_lamp',
      title: 'Luminaria litofane',
      description: 'Foto impressa em luz.',
      style: 'Personalizado',
      priceCents: 7990,
      imageTag: 'lamp_litho',
    ),
    CatalogItem(
      id: 'ci_11',
      categoryId: 'cat_lamp',
      title: 'Abajur geometrico',
      description: 'Abajur com padrao vazado.',
      style: 'Geometrico',
      priceCents: 5990,
      imageTag: 'lamp_geo',
    ),
  ];

  @override
  Future<List<CatalogItem>> getCatalogItems(String categoryId) async {
    return _catalogItems
        .where((item) => item.categoryId == categoryId)
        .toList();
  }

  @override
  Future<void> updateCustomerOrderStatus(
    String id,
    CustomerOrderStatus status,
  ) async {
    // In-memory: no-op (orders are immutable const objects).
  }

  @override
  Future<void> updateJobStatus(String id, JobStatus status) async {
    // In-memory: no-op.
  }

  @override
  Future<void> updateMaterial(String id, Map<String, dynamic> fields) async {
    // In-memory: no-op.
  }

  @override
  Future<List<CustomerOrder>> getCustomerOrdersByEmail(String email) async {
    final normalized = email.trim().toLowerCase();

    if (normalized.isEmpty) return _customerOrders.take(1).toList();

    return _customerOrders
        .where((order) => order.email.toLowerCase() == normalized)
        .toList();
  }

  @override
  Future<CustomerOrder> createCustomerOrder(
    CreateCustomerOrderInput input,
  ) async {
    final next = _customerOrders.length + 3001;
    final now = DateTime.now();
    final order = CustomerOrder(
      id: 'req_$next',
      code: 'PED-$next',
      customerName: input.customerName,
      email: input.email.trim().toLowerCase(),
      phone: input.phone,
      kind: input.kind,
      productTitle: input.productTitle,
      description: input.description,
      quantity: input.quantity,
      hasReferenceImage: input.hasReferenceImage,
      status: CustomerOrderStatus.received,
      createdAt: now,
      updatedAt: now,
    );
    _customerOrders.insert(0, order);
    return order;
  }

  @override
  Future<P3dClient> createClient({
    required String name,
    required String phone,
    required String channel,
    required String notes,
  }) async {
    final client = P3dClient(
      id: 'cli_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      phone: phone,
      channel: channel,
      notes: notes,
      currentStatus: 'Novo',
      lastQuoteLabel: 'Sem orcamento',
    );
    _clients.insert(0, client);
    return client;
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
    final filament = Filament(
      id: 'fil_${DateTime.now().microsecondsSinceEpoch}',
      brand: brand,
      material: material,
      finish: finish,
      colorName: colorName,
      colorHex: colorHex,
      rollGrams: rollGrams,
      remainingGrams: remainingGrams,
      costCents: costCents,
      lowStockGrams: lowStockGrams,
      lot: 'MANUAL',
    );
    _extraFilaments.insert(0, filament);
    return filament;
  }

  @override
  Future<List<GlobalSearchResult>> search(String query) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return const [];

    final clients = _clients
        .where(
          (client) => '${client.name} ${client.phone} ${client.channel}'
              .toLowerCase()
              .contains(term),
        )
        .map(
          (client) => GlobalSearchResult(
            title: client.name,
            subtitle: '${client.phone} • ${client.currentStatus}',
            type: 'Cliente',
            icon: 'client',
          ),
        );

    final orders = _customerOrders
        .where(
          (order) => '${order.code} ${order.customerName} ${order.productTitle}'
              .toLowerCase()
              .contains(term),
        )
        .map(
          (order) => GlobalSearchResult(
            title: '#${order.code} ${order.productTitle}',
            subtitle: '${order.customerName} • ${order.status.label}',
            type: 'Pedido',
            icon: 'order',
          ),
        );

    final materials = (await getFilaments())
        .where(
          (filament) =>
              '${filament.brand} ${filament.material} ${filament.colorName}'
                  .toLowerCase()
                  .contains(term),
        )
        .map(
          (filament) => GlobalSearchResult(
            title: '${filament.material} ${filament.colorName}',
            subtitle:
                '${filament.brand} • ${filament.remainingGrams}g restantes',
            type: 'Material',
            icon: 'material',
          ),
        );

    return [...clients, ...orders, ...materials].take(12).toList();
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    final jobs = await getJobs();
    final filaments = await getFilaments();
    return [
      for (final filament in filaments.where(
        (item) => item.status != FilamentStatus.ok,
      ))
        AppNotification(
          id: 'n_${filament.id}',
          title: 'Filamento baixo',
          message:
              '${filament.material} ${filament.colorName}: ${filament.remainingGrams}g restantes.',
          severity: filament.status == FilamentStatus.empty
              ? 'danger'
              : 'warning',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      for (final job in jobs.where(
        (item) => item.dueAt.difference(DateTime.now()).inHours <= 36,
      ))
        AppNotification(
          id: 'n_${job.id}',
          title: 'Prazo critico',
          message:
              '${job.title} vence em ${job.dueAt.day.toString().padLeft(2, '0')}/${job.dueAt.month.toString().padLeft(2, '0')}.',
          severity: 'danger',
          createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
        ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Portal do cliente
  // ---------------------------------------------------------------------------

  @override
  Future<P3dClient?> portalLogin(String code) async {
    final normalized = code.trim().toLowerCase();
    try {
      return _clients.firstWhere(
        (c) => c.portalCode.isNotEmpty && c.portalCode == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<P3dClient>> getPortalClients() async {
    return _clients.where((c) => c.hasPortalAccess).toList();
  }

  @override
  Future<List<PortalProduct>> getPortalProducts(String clientId) async {
    return _portalProducts
        .where((e) => e.clientId == clientId)
        .map((e) => e.product)
        .toList();
  }

  @override
  Future<P3dClient> createPortalClient({
    required String name,
    required String phone,
    required String channel,
    required String notes,
    required String portalCode,
    required String companyName,
    required int employeeCount,
  }) async {
    final client = P3dClient(
      id: 'cli_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      phone: phone,
      channel: channel,
      notes: notes,
      currentStatus: 'Novo',
      lastQuoteLabel: 'Sem orcamento',
      portalCode: portalCode.trim().toLowerCase(),
      companyName: companyName,
      employeeCount: employeeCount,
    );
    _clients.insert(0, client);
    return client;
  }

  @override
  Future<PortalProduct> createPortalOrderRequest(
    String clientId,
    PortalOrderRequest request,
  ) async {
    final now = DateTime.now();
    final product = PortalProduct(
      id: 'pp_${now.microsecondsSinceEpoch}',
      title: request.productTitle,
      description: request.description,
      quantity: request.quantity,
      paidQuantity: 0,
      unitPriceCents: request.sellPriceCents > 0
          ? request.sellPriceCents
          : 1490,
      costPriceCents: request.costPriceCents,
      imageUrl: request.imageUrl,
      status: PortalProductStatus.producing,
      paymentStatus: PortalProductPaymentStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    _portalProducts.insert(
      0,
      _PortalProductEntry(clientId: clientId, product: product),
    );
    return product;
  }

  @override
  Future<void> updatePortalProductStatus(
    String productId,
    PortalProductStatus status,
  ) async {
    final idx = _portalProducts.indexWhere((e) => e.product.id == productId);
    if (idx == -1) return;
    final old = _portalProducts[idx];
    _portalProducts[idx] = _PortalProductEntry(
      clientId: old.clientId,
      product: PortalProduct(
        id: old.product.id,
        title: old.product.title,
        description: old.product.description,
        quantity: old.product.quantity,
        paidQuantity: old.product.paidQuantity,
        unitPriceCents: old.product.unitPriceCents,
        costPriceCents: old.product.costPriceCents,
        imageUrl: old.product.imageUrl,
        status: status,
        paymentStatus: status == PortalProductStatus.delivered
            ? PortalProductPaymentStatus.paid
            : old.product.paymentStatus,
        createdAt: old.product.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updatePortalProductPayment(
    String productId,
    int paidQuantity,
  ) async {
    final idx = _portalProducts.indexWhere((e) => e.product.id == productId);
    if (idx == -1) return;
    final old = _portalProducts[idx];
    _portalProducts[idx] = _PortalProductEntry(
      clientId: old.clientId,
      product: PortalProduct(
        id: old.product.id,
        title: old.product.title,
        description: old.product.description,
        quantity: old.product.quantity,
        paidQuantity: paidQuantity.clamp(0, old.product.quantity),
        unitPriceCents: old.product.unitPriceCents,
        costPriceCents: old.product.costPriceCents,
        imageUrl: old.product.imageUrl,
        status: old.product.status,
        paymentStatus: paidQuantity >= old.product.quantity
            ? PortalProductPaymentStatus.paid
            : PortalProductPaymentStatus.pending,
        createdAt: old.product.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pedidos (admin)
  // ---------------------------------------------------------------------------

  @override
  Future<List<CustomerOrder>> getAllCustomerOrders() async {
    return List.unmodifiable(_customerOrders);
  }
}

// Helper to associate portal products with client codes in-memory.
class _PortalProductEntry {
  const _PortalProductEntry({required this.clientId, required this.product});

  final String clientId;
  final PortalProduct product;
}
