import 'package:flutter/material.dart';

import '../core/p3d_models.dart';
import '../data/operation_repository.dart';
import '../core/ui_components.dart';
import '../features/clients/presentation/clients_page.dart';
import '../features/customer_orders/presentation/customer_order_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/jobs/presentation/production_page.dart';
import '../features/materials/presentation/materials_page.dart';
import '../features/quotes/presentation/quotes_page.dart';

class P3dApp extends StatelessWidget {
  const P3dApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = InMemoryOperationRepository();

    return MaterialApp(
      title: 'Me Ajuda em 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F56E8),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFFF5F7FC),
        ),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
        tabBarTheme: TabBarThemeData(
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: Color(0xFF5B5FEF),
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF4A5568),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF5B5FEF), width: 1.2),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 72,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => CustomerOrderPage(
          repository: repository,
          onOpenAdmin: (context) => Navigator.of(context).pushNamed('/admin'),
        ),
        '/admin': (_) => AppShell(repository: repository),
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.repository});

  final OperationRepository repository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(repository: widget.repository),
      MaterialsPage(repository: widget.repository),
      QuotesPage(repository: widget.repository),
      ProductionPage(repository: widget.repository),
      ClientsPage(repository: widget.repository),
    ];

    final destinations = const [
      _ShellDestination(
        icon: Icons.dashboard_customize_outlined,
        selectedIcon: Icons.dashboard_customize_rounded,
        label: 'Home',
        title: 'Cockpit 3D',
        subtitle: 'Resumo de pedidos, estoque e producao',
      ),
      _ShellDestination(
        icon: Icons.shelves,
        selectedIcon: Icons.shelves,
        label: 'Materiais',
        title: 'Materiais',
        subtitle: 'Filamentos, insumos e baixo estoque',
      ),
      _ShellDestination(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: 'Orc.',
        title: 'Orcamentos',
        subtitle: 'Rascunhos, enviados, aprovados e recusados',
      ),
      _ShellDestination(
        icon: Icons.auto_mode_outlined,
        selectedIcon: Icons.auto_mode_rounded,
        label: 'Producao',
        title: 'Producao',
        subtitle: 'Fila, impressao, acabamento e retirada',
      ),
      _ShellDestination(
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum_rounded,
        label: 'Clientes',
        title: 'Clientes',
        subtitle: 'Historico comercial e pedidos em andamento',
      ),
    ];

    final wide = MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  _AdminSidebar(
                    index: _index,
                    destinations: destinations,
                    onChanged: (value) => setState(() => _index = value),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        AdminTopBar(
                          title: destinations[_index].title,
                          subtitle: destinations[_index].subtitle,
                          action: _adminAction(context, _index),
                          onSearch: _showSearch,
                          onNotifications: _showNotifications,
                        ),
                        Expanded(
                          child: IndexedStack(index: _index, children: pages),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  AdminTopBar(
                    title: destinations[_index].title,
                    subtitle: destinations[_index].subtitle,
                    action: _adminAction(context, _index),
                    onSearch: _showSearch,
                    onNotifications: _showNotifications,
                  ),
                  Expanded(
                    child: IndexedStack(index: _index, children: pages),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }

  Widget? _adminAction(BuildContext context, int index) {
    return switch (index) {
      0 => ActionPill(
        icon: Icons.add_rounded,
        label: 'Novo pedido',
        onPressed: () => _showCreateOrder(context),
      ),
      1 => ActionPill(
        icon: Icons.add_rounded,
        label: 'Cadastrar',
        onPressed: () => _showCreateMaterial(context),
      ),
      2 => ActionPill(
        icon: Icons.add_rounded,
        label: 'Novo orcamento',
        onPressed: () => showQuoteEditorPreview(context),
      ),
      3 => ActionPill(
        icon: Icons.swap_vert_rounded,
        label: 'Reordenar',
        onPressed: () => showComingSoon(context, 'Reordenacao da fila'),
      ),
      4 => ActionPill(
        icon: Icons.person_add_alt_rounded,
        label: 'Novo cliente',
        onPressed: () => _showCreateClient(context),
      ),
      _ => null,
    };
  }

  Future<void> _showSearch(String query) async {
    final results = await widget.repository.search(query);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Busca global', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (results.isEmpty)
              const EmptyStateView(
                title: 'Nada encontrado',
                message: 'Tente buscar por cliente, pedido ou material.',
              )
            else
              for (final result in results)
                ListTile(
                  leading: CircleAvatar(child: Icon(_searchIcon(result.icon))),
                  title: Text(result.title),
                  subtitle: Text('${result.type} • ${result.subtitle}'),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNotifications() async {
    final notifications = await widget.repository.getNotifications();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notificacoes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (notifications.isEmpty)
              const EmptyStateView(
                title: 'Tudo certo',
                message: 'Nenhum alerta operacional agora.',
              )
            else
              for (final item in notifications)
                ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      item.severity == 'danger'
                          ? Icons.priority_high_rounded
                          : Icons.warning_amber_rounded,
                    ),
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.message),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateOrder(BuildContext context) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final description = TextEditingController();
    var kind = CustomerKind.person;
    var quantity = 1;
    var productTitle = 'Chaveiro personalizado';
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo pedido'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<CustomerKind>(
                    segments: [
                      for (final value in CustomerKind.values)
                        ButtonSegment(value: value, label: Text(value.label)),
                    ],
                    selected: {kind},
                    onSelectionChanged: (value) =>
                        setDialogState(() => kind = value.first),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: productTitle,
                    items: const [
                      DropdownMenuItem(
                        value: 'Chaveiro personalizado',
                        child: Text('Chaveiro personalizado'),
                      ),
                      DropdownMenuItem(
                        value: 'Encomenda decoracao',
                        child: Text('Encomenda decoracao'),
                      ),
                      DropdownMenuItem(
                        value: 'Quadro ou placa',
                        child: Text('Quadro ou placa'),
                      ),
                      DropdownMenuItem(
                        value: 'Pedido com base em imagem',
                        child: Text('Pedido com base em imagem'),
                      ),
                      DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                    ],
                    onChanged: (value) => setDialogState(
                      () => productTitle = value ?? productTitle,
                    ),
                    decoration: const InputDecoration(labelText: 'Produto'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Detalhes'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(child: Text('Quantidade')),
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setDialogState(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$quantity'),
                      IconButton(
                        onPressed: () => setDialogState(() => quantity++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            GradientButton(
              label: 'Criar',
              onPressed: () async {
                await widget.repository.createCustomerOrder(
                  CreateCustomerOrderInput(
                    customerName: name.text,
                    email: email.text,
                    phone: phone.text,
                    kind: kind,
                    productTitle: productTitle,
                    description: description.text,
                    quantity: quantity,
                    hasReferenceImage: false,
                  ),
                );
                if (context.mounted) Navigator.pop(context);
                if (mounted) setState(() {});
              },
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateMaterial(BuildContext context) async {
    final brand = TextEditingController(text: '3D Fila');
    final material = TextEditingController(text: 'PLA');
    final color = TextEditingController(text: 'Azul marinho');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cadastrar filamento'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: brand,
                decoration: const InputDecoration(labelText: 'Marca'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: material,
                decoration: const InputDecoration(labelText: 'Material'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: color,
                decoration: const InputDecoration(labelText: 'Cor'),
              ),
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
              await widget.repository.createFilament(
                brand: brand.text,
                material: material.text,
                finish: 'Fosco',
                colorName: color.text,
                colorHex: 0xFF14213D,
                rollGrams: 1000,
                remainingGrams: 1000,
                costCents: 9990,
                lowStockGrams: 180,
              );
              if (context.mounted) Navigator.pop(context);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateClient(BuildContext context) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final channel = TextEditingController(text: 'WhatsApp');
    final notes = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo cliente'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: channel,
                decoration: const InputDecoration(labelText: 'Canal'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Observacoes'),
              ),
            ],
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
            onPressed: () async {
              await widget.repository.createClient(
                name: name.text,
                phone: phone.text,
                channel: channel.text,
                notes: notes.text,
              );
              if (context.mounted) Navigator.pop(context);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

IconData _searchIcon(String icon) {
  return switch (icon) {
    'client' => Icons.person_outline_rounded,
    'order' => Icons.shopping_bag_outlined,
    'material' => Icons.shelves,
    _ => Icons.search_rounded,
  };
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.index,
    required this.destinations,
    required this.onChanged,
  });

  final int index;
  final List<_ShellDestination> destinations;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: const Color(0xFF0C1A35),
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: BrandMark(dark: true),
          ),
          const SizedBox(height: 28),
          for (var i = 0; i < destinations.length; i++)
            _SidebarButton(
              destination: destinations[i],
              selected: i == index,
              onTap: () => onChanged(i),
            ),
          const SizedBox(height: 20),
          _SidebarSection(
            title: 'Estoque',
            items: const [
              'Filamentos',
              'Acessorios',
              'Resinas e Tintas',
              'Acabamentos',
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFEFF2FF),
                  child: Icon(Icons.storefront_rounded, size: 18),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Print3D Studio\ncontato@print3d.com',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                Icon(Icons.expand_more_rounded, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  destination.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.50),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                item,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String title;
  final String subtitle;
}
