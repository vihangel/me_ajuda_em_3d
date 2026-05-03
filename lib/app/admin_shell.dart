import 'package:flutter/material.dart';

import '../core/ui_components.dart';
import '../data/operation_repository.dart';
import '../features/calculator/presentation/calculator_page.dart';
import '../features/clients/presentation/clients_page.dart';
import '../features/customer_orders/presentation/admin_orders_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/jobs/presentation/production_page.dart';
import '../features/materials/presentation/materials_page.dart';
import '../features/portal_management/presentation/portal_management_page.dart';
import '../features/quotes/presentation/quotes_page.dart';
import '../features/settings/presentation/settings_page.dart';
import 'admin_dialogs.dart';

// ---------------------------------------------------------------------------
// Shell — sidebar (desktop) / bottom nav (mobile)
// ---------------------------------------------------------------------------

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
      AdminOrdersPage(repository: widget.repository),
      MaterialsPage(repository: widget.repository),
      QuotesPage(repository: widget.repository),
      ProductionPage(repository: widget.repository),
      ClientsPage(repository: widget.repository),
      PortalManagementPage(repository: widget.repository),
      const CalculatorPage(),
      const SettingsPage(),
    ];

    final wide = MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  AdminSidebar(
                    index: _index,
                    destinations: destinations,
                    onChanged: (v) => setState(() => _index = v),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        AdminTopBar(
                          title: destinations[_index].title,
                          subtitle: destinations[_index].subtitle,
                          action: adminAction(
                            context,
                            _index,
                            widget.repository,
                            () => setState(() {}),
                          ),
                          onSearch: (q) =>
                              showSearchSheet(context, widget.repository, q),
                          onNotifications: () => showNotificationsSheet(
                            context,
                            widget.repository,
                          ),
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
                    action: adminAction(
                      context,
                      _index,
                      widget.repository,
                      () => setState(() {}),
                    ),
                    onSearch: (q) =>
                        showSearchSheet(context, widget.repository, q),
                    onNotifications: () =>
                        showNotificationsSheet(context, widget.repository),
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
              onDestinationSelected: (v) => setState(() => _index = v),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Destinations
// ---------------------------------------------------------------------------

class ShellDestination {
  const ShellDestination({
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

const destinations = [
  ShellDestination(
    icon: Icons.dashboard_customize_outlined,
    selectedIcon: Icons.dashboard_customize_rounded,
    label: 'Home',
    title: 'Cockpit 3D',
    subtitle: 'Resumo de pedidos, estoque e producao',
  ),
  ShellDestination(
    icon: Icons.shopping_bag_outlined,
    selectedIcon: Icons.shopping_bag_rounded,
    label: 'Pedidos',
    title: 'Pedidos',
    subtitle: 'Todos os pedidos de clientes e seus status',
  ),
  ShellDestination(
    icon: Icons.shelves,
    selectedIcon: Icons.shelves,
    label: 'Materiais',
    title: 'Materiais',
    subtitle: 'Filamentos, insumos e baixo estoque',
  ),
  ShellDestination(
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
    label: 'Orc.',
    title: 'Orcamentos',
    subtitle: 'Rascunhos, enviados, aprovados e recusados',
  ),
  ShellDestination(
    icon: Icons.auto_mode_outlined,
    selectedIcon: Icons.auto_mode_rounded,
    label: 'Producao',
    title: 'Producao',
    subtitle: 'Fila, impressao, acabamento e retirada',
  ),
  ShellDestination(
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum_rounded,
    label: 'Clientes',
    title: 'Clientes',
    subtitle: 'Historico comercial e pedidos em andamento',
  ),
  ShellDestination(
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront_rounded,
    label: 'Portal',
    title: 'Portal do Cliente',
    subtitle: 'Clientes recorrentes, produtos e pagamentos',
  ),
  ShellDestination(
    icon: Icons.calculate_outlined,
    selectedIcon: Icons.calculate_rounded,
    label: 'Calc.',
    title: 'Calculadora 3D',
    subtitle: 'Simule custos e precos de impressao',
  ),
  ShellDestination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    label: 'Config.',
    title: 'Configuracoes',
    subtitle: 'Parametros de custo, margem e prazos',
  ),
];

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.index,
    required this.destinations,
    required this.onChanged,
  });
  final int index;
  final List<ShellDestination> destinations;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2A4A), Color(0xFF16213A)],
        ),
      ),
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
  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? const Color(0xFF4865F4).withValues(alpha: 0.22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: selected
                      ? const Color(0xFF9DA5FF)
                      : Colors.white.withValues(alpha: 0.7),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  destination.label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (selected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF9DA5FF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
