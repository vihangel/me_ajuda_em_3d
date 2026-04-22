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
  Future<List<CustomerOrder>> getCustomerOrdersByEmail(String email);
  Future<CustomerOrder> createCustomerOrder(CreateCustomerOrderInput input);
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
}

class InMemoryOperationRepository implements OperationRepository {
  InMemoryOperationRepository();

  final List<P3dClient> _clients = [
    const P3dClient(
      id: 'cli_001',
      name: 'Marina Alves',
      phone: '(65) 99912-8844',
      channel: 'Instagram',
      notes: 'Prefere retirada no fim da tarde.',
      currentStatus: 'Na fila',
      lastQuoteLabel: '#3D-1042 chaveiros PLA',
    ),
    const P3dClient(
      id: 'cli_002',
      name: 'Studio Nimbo',
      phone: '(65) 98144-2210',
      channel: 'WhatsApp',
      notes: 'Cliente recorrente de brindes.',
      currentStatus: 'Aguardando aprovacao',
      lastQuoteLabel: '#3D-1046 imas personalizados',
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
    final now = DateTime.now();

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
      id: 'customer_keyring',
      title: 'Chaveiro personalizado',
      description: 'Nome, logo, personagem simples ou lembrancinha em lote.',
      icon: 'key',
      examples: ['brinde', 'nome', 'logo', 'evento'],
      fromPriceCents: 1290,
      needsImage: false,
    ),
    CustomerProduct(
      id: 'customer_decor',
      title: 'Encomenda decoracao',
      description: 'Pecas para mesa, parede, festas, nichos e ambientes.',
      icon: 'decor',
      examples: ['mesa', 'festa', 'parede', 'presente'],
      fromPriceCents: 3490,
      needsImage: false,
    ),
    CustomerProduct(
      id: 'customer_frame',
      title: 'Quadro ou placa',
      description: 'Placas com relevo, letreiros, logos e quadros decorativos.',
      icon: 'frame',
      examples: ['logo 3D', 'letreiro', 'placa', 'quadro'],
      fromPriceCents: 5990,
      needsImage: false,
    ),
    CustomerProduct(
      id: 'customer_image',
      title: 'Pedido com base em imagem',
      description: 'Envie uma foto ou referencia para avaliarmos a modelagem.',
      icon: 'image',
      examples: ['foto', 'desenho', 'referencia', 'print'],
      fromPriceCents: 4590,
      needsImage: true,
    ),
    CustomerProduct(
      id: 'customer_other',
      title: 'Outros',
      description:
          'Conte sua ideia em aberto: peca tecnica, reposicao ou presente.',
      icon: 'other',
      examples: ['peca tecnica', 'suporte', 'miniatura', 'prototipo'],
      fromPriceCents: 2990,
      needsImage: false,
    ),
  ];

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
}
