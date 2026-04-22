import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';

// ---------------------------------------------------------------------------
// Entry point — tabs between wizard and order lookup
// ---------------------------------------------------------------------------

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
        builder: (ctx) => _PublicShell(
          onOpenAdmin: widget.onOpenAdmin == null
              ? null
              : () => widget.onOpenAdmin!(ctx),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SoftPanel(
                  padding: const EdgeInsets.all(4),
                  child: TabBar(tabs: const [
                    Tab(text: 'Novo pedido'),
                    Tab(text: 'Meus pedidos'),
                  ]),
                ),
              ),
              Expanded(
                child: TabBarView(children: [
                  _OrderWizard(repository: widget.repository),
                  _LookupOrdersView(
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

// ---------------------------------------------------------------------------
// Public shell — top bar + constrained width
// ---------------------------------------------------------------------------

class _PublicShell extends StatelessWidget {
  const _PublicShell({required this.child, this.onOpenAdmin});

  final Widget child;
  final VoidCallback? onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _PublicTopBar(onOpenAdmin: onOpenAdmin),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wide ? 860 : double.infinity,
                  ),
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

class _PublicTopBar extends StatelessWidget {
  const _PublicTopBar({this.onOpenAdmin});

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
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.35),
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

// ---------------------------------------------------------------------------
// Wizard — 4 steps: Category → Details + Catalog → Customize → Contact
// ---------------------------------------------------------------------------

class _OrderWizard extends StatefulWidget {
  const _OrderWizard({required this.repository});

  final OperationRepository repository;

  @override
  State<_OrderWizard> createState() => _OrderWizardState();
}

class _OrderWizardState extends State<_OrderWizard> {
  int _step = 0; // 0=category, 1=details+catalog, 2=customize, 3=contact

  // Step 0
  CustomerProduct? _category;
  List<CustomerProduct> _categories = [];

  // Step 1
  final _descriptionCtrl = TextEditingController();
  CatalogItem? _selectedCatalogItem;

  // Step 2
  int _quantity = 1;
  final _sizeCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String _finish = 'Sem preferencia';
  bool _hasImage = false;

  // Step 3
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await widget.repository.getCustomerProducts();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _sizeCtrl.dispose();
    _colorCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, email e telefone.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final desc = _buildDescription();
      final order = await widget.repository.createCustomerOrder(
        CreateCustomerOrderInput(
          customerName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          kind: CustomerKind.person,
          productTitle: _selectedCatalogItem?.title ?? _category?.title ?? '',
          description: desc,
          quantity: _quantity,
          hasReferenceImage: _hasImage,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido ${order.code} enviado com sucesso!')),
      );
      DefaultTabController.of(context).animateTo(1);
      setState(() {
        _step = 0;
        _category = null;
        _selectedCatalogItem = null;
        _descriptionCtrl.clear();
        _sizeCtrl.clear();
        _colorCtrl.clear();
        _nameCtrl.clear();
        _emailCtrl.clear();
        _phoneCtrl.clear();
        _quantity = 1;
        _finish = 'Sem preferencia';
        _hasImage = false;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar pedido.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _buildDescription() {
    return [
      if (_selectedCatalogItem != null)
        'Catalogo: ${_selectedCatalogItem!.title} (${_selectedCatalogItem!.style})',
      if (_descriptionCtrl.text.trim().isNotEmpty)
        'Descricao: ${_descriptionCtrl.text.trim()}',
      if (_sizeCtrl.text.trim().isNotEmpty)
        'Tamanho: ${_sizeCtrl.text.trim()}',
      if (_colorCtrl.text.trim().isNotEmpty)
        'Cor: ${_colorCtrl.text.trim()}',
      'Acabamento: $_finish',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingStateView();

    final stepLabels = ['Categoria', 'Detalhes', 'Personalizar', 'Contato'];

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _StepIndicator(current: _step, labels: stepLabels),
        ),
        // Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildStep(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _StepCategory(
          key: const ValueKey(0),
          categories: _categories,
          selected: _category,
          onSelect: (cat) {
            setState(() => _category = cat);
            _next();
          },
        ),
      1 => _StepDetails(
          key: const ValueKey(1),
          repository: widget.repository,
          category: _category!,
          descriptionCtrl: _descriptionCtrl,
          selectedItem: _selectedCatalogItem,
          onItemSelected: (item) =>
              setState(() => _selectedCatalogItem = item),
          onBack: _back,
          onNext: _next,
        ),
      2 => _StepCustomize(
          key: const ValueKey(2),
          category: _category!,
          quantity: _quantity,
          sizeCtrl: _sizeCtrl,
          colorCtrl: _colorCtrl,
          finish: _finish,
          hasImage: _hasImage,
          onQuantityChanged: (v) => setState(() => _quantity = v),
          onFinishChanged: (v) => setState(() => _finish = v),
          onImageChanged: (v) => setState(() => _hasImage = v),
          onBack: _back,
          onNext: _next,
        ),
      3 => _StepContact(
          key: const ValueKey(3),
          nameCtrl: _nameCtrl,
          emailCtrl: _emailCtrl,
          phoneCtrl: _phoneCtrl,
          submitting: _submitting,
          onBack: _back,
          onSubmit: _submit,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ---------------------------------------------------------------------------
// Step indicator
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.labels});

  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: i <= current
                    ? colors.primary
                    : colors.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: i <= current
                    ? colors.primary
                    : colors.outlineVariant.withValues(alpha: 0.25),
                child: i < current
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: i == current
                              ? Colors.white
                              : colors.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                  color: i <= current
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 0 — Category picker
// ---------------------------------------------------------------------------

class _StepCategory extends StatelessWidget {
  const _StepCategory({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<CustomerProduct> categories;
  final CustomerProduct? selected;
  final ValueChanged<CustomerProduct> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroBanner(),
        const SizedBox(height: 20),
        Text(
          'O que voce quer criar?',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Escolha a categoria que mais combina com sua ideia.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 3 : 2,
            mainAxisExtent: 170,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, i) {
            final cat = categories[i];
            final isSelected = selected?.id == cat.id;
            final accent = _categoryAccent(cat.icon);

            return _CategoryTile(
              icon: _categoryIcon(cat.icon),
              title: cat.title,
              subtitle: 'desde ${formatMoney(cat.fromPriceCents)}',
              accent: accent,
              selected: isSelected,
              onTap: () => onSelect(cat),
            );
          },
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4865F4), Color(0xFF8462F5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5964F2).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transforme sua ideia\nem peca 3D',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pecas em PLA ate 25cm. Escolha, descreva e receba um orcamento.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: const Icon(
              Icons.view_in_ar_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.10)
                : colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? accent
                  : colors.outlineVariant.withValues(alpha: 0.25),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: selected ? accent : colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accent,
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
// Step 1 — Details + Catalog
// ---------------------------------------------------------------------------

class _StepDetails extends StatefulWidget {
  const _StepDetails({
    super.key,
    required this.repository,
    required this.category,
    required this.descriptionCtrl,
    required this.selectedItem,
    required this.onItemSelected,
    required this.onBack,
    required this.onNext,
  });

  final OperationRepository repository;
  final CustomerProduct category;
  final TextEditingController descriptionCtrl;
  final CatalogItem? selectedItem;
  final ValueChanged<CatalogItem?> onItemSelected;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<_StepDetails> createState() => _StepDetailsState();
}

class _StepDetailsState extends State<_StepDetails> {
  late Future<List<CatalogItem>> _catalogFuture;

  @override
  void initState() {
    super.initState();
    _catalogFuture =
        widget.repository.getCatalogItems(widget.category.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Category badge
        Row(
          children: [
            Icon(
              _categoryIcon(widget.category.icon),
              color: _categoryAccent(widget.category.icon),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              widget.category.title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _categoryAccent(widget.category.icon),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Catalog section
        Text(
          'Inspire-se no catalogo',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Escolha um modelo base ou descreva sua ideia do zero.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),

        FutureBuilder<List<CatalogItem>>(
          future: _catalogFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colors.outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sem exemplos nessa categoria ainda. Descreva sua ideia abaixo.',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 155,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final sel = widget.selectedItem?.id == item.id;
                  final accent =
                      _categoryAccent(widget.category.icon);

                  return _CatalogCard(
                    item: item,
                    accent: accent,
                    selected: sel,
                    onTap: () => widget.onItemSelected(
                      sel ? null : item,
                    ),
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // Description
        Text(
          'Descreva sua ideia',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SoftPanel(
          child: TextField(
            controller: widget.descriptionCtrl,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: widget.category.needsImage
                  ? 'Descreva o que quer e envie uma foto na proxima etapa...'
                  : 'Ex: quero 30 chaveiros com o nome "Turma 2026" em PLA branco...',
              border: InputBorder.none,
            ),
          ),
        ),

        const SizedBox(height: 24),
        _WizardNav(onBack: widget.onBack, onNext: widget.onNext),
      ],
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.item,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final CatalogItem item;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.10)
              : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accent
                : colors.outlineVariant.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _catalogIcon(item.imageTag),
                    color: accent,
                    size: 20,
                  ),
                ),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_circle, color: accent, size: 22),
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.style,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatMoney(item.priceCents),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Customize (size, color, finish, quantity, image)
// ---------------------------------------------------------------------------

class _StepCustomize extends StatelessWidget {
  const _StepCustomize({
    super.key,
    required this.category,
    required this.quantity,
    required this.sizeCtrl,
    required this.colorCtrl,
    required this.finish,
    required this.hasImage,
    required this.onQuantityChanged,
    required this.onFinishChanged,
    required this.onImageChanged,
    required this.onBack,
    required this.onNext,
  });

  final CustomerProduct category;
  final int quantity;
  final TextEditingController sizeCtrl;
  final TextEditingController colorCtrl;
  final String finish;
  final bool hasImage;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> onFinishChanged;
  final ValueChanged<bool> onImageChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Personalize sua peca',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Ajuste os detalhes para o orcamento ficar mais preciso.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 20),

        SoftPanel(
          child: Column(
            children: [
              // Quantity
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.numbers_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Quantidade',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: quantity > 1
                        ? () => onQuantityChanged(quantity - 1)
                        : null,
                    icon: const Icon(Icons.remove, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '$quantity',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: () => onQuantityChanged(quantity + 1),
                    icon: const Icon(Icons.add, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Size
              TextField(
                controller: sizeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tamanho aproximado',
                  hintText: 'Ex: 8cm de altura',
                  prefixIcon: Icon(Icons.straighten_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Color
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cor desejada',
                  hintText: 'Ex: branco, preto, azul...',
                  prefixIcon: Icon(Icons.palette_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Finish
              DropdownButtonFormField<String>(
                value: finish,
                decoration: const InputDecoration(
                  labelText: 'Acabamento',
                  prefixIcon: Icon(Icons.auto_fix_high_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Sem preferencia',
                    child: Text('Sem preferencia'),
                  ),
                  DropdownMenuItem(value: 'Fosco', child: Text('Fosco')),
                  DropdownMenuItem(
                    value: 'Brilhante',
                    child: Text('Brilhante'),
                  ),
                  DropdownMenuItem(value: 'Pintado', child: Text('Pintado')),
                  DropdownMenuItem(value: 'Lixado', child: Text('Lixado')),
                  DropdownMenuItem(value: 'Premium', child: Text('Premium')),
                ],
                onChanged: (v) => onFinishChanged(v ?? 'Sem preferencia'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Image attachment
        _ImageAttachCard(
          required_: category.needsImage,
          attached: hasImage,
          onTap: () => onImageChanged(!hasImage),
        ),

        const SizedBox(height: 24),
        _WizardNav(onBack: onBack, onNext: onNext),
      ],
    );
  }
}

class _ImageAttachCard extends StatelessWidget {
  const _ImageAttachCard({
    required bool required_,
    required this.attached,
    required this.onTap,
  }) : isRequired = required_;

  final bool isRequired;
  final bool attached;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: attached
              ? colors.primary.withValues(alpha: 0.08)
              : colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: attached
                ? colors.primary.withValues(alpha: 0.35)
                : colors.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colors.primary.withValues(alpha: 0.12),
              child: Icon(
                attached
                    ? Icons.image_rounded
                    : Icons.add_photo_alternate_outlined,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attached
                        ? 'Referencia adicionada'
                        : 'Anexar foto ou referencia',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isRequired
                        ? 'Esse tipo de pedido precisa de uma imagem.'
                        : 'Opcional, mas ajuda muito no orcamento.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(
              attached ? Icons.check_circle : Icons.upload_file_rounded,
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Contact info + submit
// ---------------------------------------------------------------------------

class _StepContact extends StatelessWidget {
  const _StepContact({
    super.key,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.submitting,
    required this.onBack,
    required this.onSubmit,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Quase la!',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Deixe seu contato para recebermos o pedido e enviarmos o orcamento.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 20),

        SoftPanel(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Seu nome',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Para consultar o pedido depois',
                  prefixIcon: Icon(Icons.mail_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp ou telefone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Privacy note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Seus dados sao usados apenas para contato sobre este pedido.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Voltar'),
            ),
            const Spacer(),
            SizedBox(
              height: 48,
              child: submitting
                  ? const SizedBox(
                      width: 48,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : GradientButton(
                      icon: Icons.send_rounded,
                      label: 'Enviar pedido',
                      onPressed: onSubmit,
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared wizard navigation
// ---------------------------------------------------------------------------

class _WizardNav extends StatelessWidget {
  const _WizardNav({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Voltar'),
        ),
        const Spacer(),
        GradientButton(
          icon: Icons.arrow_forward_rounded,
          label: 'Continuar',
          onPressed: onNext,
          compact: true,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Lookup orders view (tab 2)
// ---------------------------------------------------------------------------

class _LookupOrdersView extends StatefulWidget {
  const _LookupOrdersView({
    required this.repository,
    required this.controller,
  });

  final OperationRepository repository;
  final TextEditingController controller;

  @override
  State<_LookupOrdersView> createState() => _LookupOrdersViewState();
}

class _LookupOrdersViewState extends State<_LookupOrdersView> {
  late Future<List<CustomerOrder>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getCustomerOrdersByEmail(
      widget.controller.text,
    );
  }

  void _search() {
    setState(() {
      _future = widget.repository.getCustomerOrdersByEmail(
        widget.controller.text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SoftPanel(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email usado no pedido',
                    prefixIcon: Icon(Icons.mail_outline),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Buscar pedidos',
                onPressed: _search,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<CustomerOrder>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(height: 280, child: LoadingStateView());
            }
            if (snapshot.hasError) {
              return ErrorStateView(
                message: 'Nao foi possivel buscar pedidos.',
                onRetry: _search,
              );
            }
            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return const EmptyStateView(
                title: 'Nenhum pedido aberto',
                message:
                    'Confira se o email e o mesmo usado ao fazer o pedido.',
              );
            }

            return Column(
              children: [
                for (final order in orders) ...[
                  _CustomerOrderCard(order: order),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CustomerOrderCard extends StatelessWidget {
  const _CustomerOrderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = _orderStatusColor(order.status, colors);

    return SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order.code} • ${order.productTitle}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              AppStatusChip(label: order.status.label, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(child: Text(order.kind.label)),
              Text('Qtd. ${order.quantity}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.update, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Atualizado em ${formatDate(order.updatedAt)}'),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

IconData _categoryIcon(String icon) {
  return switch (icon) {
    'key' => Icons.vpn_key_outlined,
    'miniature' => Icons.smart_toy_outlined,
    'decor' => Icons.weekend_outlined,
    'frame' => Icons.crop_original_outlined,
    'lamp' => Icons.lightbulb_outlined,
    'image' => Icons.image_outlined,
    _ => Icons.category_outlined,
  };
}

Color _categoryAccent(String icon) {
  return switch (icon) {
    'key' => const Color(0xFF6B5CF6),
    'miniature' => const Color(0xFFE05297),
    'decor' => const Color(0xFFC76A28),
    'frame' => const Color(0xFF2D9B7F),
    'lamp' => const Color(0xFFD4A017),
    'image' => const Color(0xFF4B7BE5),
    _ => const Color(0xFF5B677A),
  };
}

IconData _catalogIcon(String imageTag) {
  return switch (imageTag) {
    'key_name' => Icons.abc_rounded,
    'key_logo' => Icons.business_rounded,
    'key_char' => Icons.face_rounded,
    'mini_char' => Icons.smart_toy_rounded,
    'mini_rpg' => Icons.casino_rounded,
    'decor_vase' => Icons.local_florist_rounded,
    'decor_frame' => Icons.crop_original_rounded,
    'sign_wall' => Icons.text_fields_rounded,
    'sign_door' => Icons.meeting_room_outlined,
    'lamp_litho' => Icons.photo_rounded,
    'lamp_geo' => Icons.lightbulb_rounded,
    _ => Icons.view_in_ar_rounded,
  };
}

Color _orderStatusColor(CustomerOrderStatus status, ColorScheme colors) {
  return switch (status) {
    CustomerOrderStatus.received => colors.primary,
    CustomerOrderStatus.reviewing => Colors.amber.shade800,
    CustomerOrderStatus.quoted => Colors.indigo.shade600,
    CustomerOrderStatus.approved => Colors.teal.shade700,
    CustomerOrderStatus.production => Colors.deepOrange.shade600,
    CustomerOrderStatus.ready => Colors.green.shade700,
    CustomerOrderStatus.closed => colors.outline,
  };
}
