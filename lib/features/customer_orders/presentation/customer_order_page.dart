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
  int? _initialTab;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read route arguments only once
    _initialTab ??= ModalRoute.of(context)?.settings.arguments as int? ?? 0;
  }

  @override
  void dispose() {
    _emailLookupCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: _initialTab ?? 0,
      child: Builder(
        builder: (ctx) => _OrderShell(
          onOpenAdmin: widget.onOpenAdmin == null
              ? null
              : () => widget.onOpenAdmin!(ctx),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SoftPanel(
                  padding: EdgeInsets.all(4),
                  child: TabBar(
                    tabs: [
                      Tab(text: 'Criar pedido'),
                      Tab(text: 'Acompanhar pedidos'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    OrderWizard(repository: widget.repository),
                    OrderLookupView(
                      repository: widget.repository,
                      controller: _emailLookupCtrl,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shell — full-width scaffold, content constrained per-section
// ---------------------------------------------------------------------------

class _OrderShell extends StatelessWidget {
  const _OrderShell({required this.child, this.onOpenAdmin});
  final Widget child;
  final VoidCallback? onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onOpenAdmin: onOpenAdmin),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
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

// ---------------------------------------------------------------------------
// Top bar — with back navigation to landing
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({this.onOpenAdmin});
  final VoidCallback? onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          if (canPop) ...[
            IconButton(
              tooltip: 'Voltar',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
          ],
          const BrandMark(),
          const Spacer(),
          if (onOpenAdmin != null)
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
