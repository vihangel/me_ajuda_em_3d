import 'package:flutter/material.dart';

import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';
import 'order_lookup.dart';
import 'order_wizard.dart';

class CustomerOrderPage extends StatefulWidget {
  const CustomerOrderPage({
    super.key,
    required this.repository,
    this.onOpenAdmin,
  });

  final OperationRepository repository;
  final void Function(BuildContext context)? onOpenAdmin;

  @override
  State<CustomerOrderPage> createState() => _CustomerOrderPageState();
}

class _CustomerOrderPageState extends State<CustomerOrderPage> {
  final _emailLookupCtrl = TextEditingController(text: 'marina@email.com');

  @override
  void dispose() {
    _emailLookupCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (ctx) => PublicShell(
          onOpenAdmin: widget.onOpenAdmin == null
              ? null
              : () => widget.onOpenAdmin!(ctx),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SoftPanel(
                  padding: EdgeInsets.all(4),
                  child: TabBar(tabs: [
                    Tab(text: 'Novo pedido'),
                    Tab(text: 'Meus pedidos'),
                  ]),
                ),
              ),
              Expanded(
                child: TabBarView(children: [
                  OrderWizard(repository: widget.repository),
                  OrderLookupView(
                    repository: widget.repository,
                    controller: _emailLookupCtrl,
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PublicShell extends StatelessWidget {
  const PublicShell({super.key, required this.child, this.onOpenAdmin});
  final Widget child;
  final VoidCallback? onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onOpenAdmin: onOpenAdmin),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 860 : double.infinity),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.onOpenAdmin});
  final VoidCallback? onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          const BrandMark(),
          const Spacer(),
          IconButton.filledTonal(
            tooltip: 'Admin',
            onPressed: onOpenAdmin,
            icon: const Icon(Icons.shield_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}
