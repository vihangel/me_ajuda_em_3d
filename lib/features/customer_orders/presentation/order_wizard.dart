import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';
import 'order_helpers.dart';

// ---------------------------------------------------------------------------
// Wizard — 3 steps: Categoria → Detalhes → Contato
// ---------------------------------------------------------------------------

class OrderWizard extends StatefulWidget {
  const OrderWizard({super.key, required this.repository});
  final OperationRepository repository;

  @override
  State<OrderWizard> createState() => _OrderWizardState();
}

class _OrderWizardState extends State<OrderWizard> {
  int _step = 0;

  // Step 0
  CustomerProduct? _category;
  List<CustomerProduct> _categories = [];

  // Step 1 (details + customize merged)
  final _descCtrl = TextEditingController();
  CatalogItem? _catalogItem;
  int _qty = 1;
  final _sizeCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  String _finish = 'Sem preferencia';
  bool _hasImage = false;

  // Step 2
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await widget.repository.getCustomerProducts();
    if (!mounted) return;
    setState(() { _categories = cats; _loading = false; });
  }

  @override
  void dispose() {
    _descCtrl.dispose(); _sizeCtrl.dispose(); _colorCtrl.dispose();
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  void _next() { if (_step < 2) setState(() => _step++); }
  void _back() { if (_step > 0) setState(() => _step--); }

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
      final order = await widget.repository.createCustomerOrder(
        CreateCustomerOrderInput(
          customerName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          kind: CustomerKind.person,
          productTitle: _catalogItem?.title ?? _category?.title ?? '',
          description: _buildDesc(),
          quantity: _qty,
          hasReferenceImage: _hasImage,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido ${order.code} enviado!')),
      );
      DefaultTabController.of(context).animateTo(1);
      _reset();
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

  void _reset() => setState(() {
    _step = 0; _category = null; _catalogItem = null;
    _descCtrl.clear(); _sizeCtrl.clear(); _colorCtrl.clear();
    _nameCtrl.clear(); _emailCtrl.clear(); _phoneCtrl.clear();
    _qty = 1; _finish = 'Sem preferencia'; _hasImage = false;
  });

  String _buildDesc() => [
    if (_catalogItem != null) 'Catalogo: ${_catalogItem!.title} (${_catalogItem!.style})',
    if (_descCtrl.text.trim().isNotEmpty) 'Descricao: ${_descCtrl.text.trim()}',
    if (_sizeCtrl.text.trim().isNotEmpty) 'Tamanho: ${_sizeCtrl.text.trim()}',
    if (_colorCtrl.text.trim().isNotEmpty) 'Cor: ${_colorCtrl.text.trim()}',
    'Acabamento: $_finish',
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingStateView();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: StepIndicator(current: _step,
              labels: const ['Categoria', 'Detalhes', 'Contato']),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildStep(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep() => switch (_step) {
    0 => StepCategory(key: const ValueKey(0), categories: _categories,
          selected: _category,
          onSelect: (c) { setState(() => _category = c); _next(); }),
    1 => StepDetails(key: const ValueKey(1), repository: widget.repository,
          category: _category!, descCtrl: _descCtrl,
          selectedItem: _catalogItem,
          onItemSelected: (i) => setState(() => _catalogItem = i),
          qty: _qty, sizeCtrl: _sizeCtrl, colorCtrl: _colorCtrl,
          finish: _finish, hasImage: _hasImage,
          onQtyChanged: (v) => setState(() => _qty = v),
          onFinishChanged: (v) => setState(() => _finish = v),
          onImageChanged: (v) => setState(() => _hasImage = v),
          onBack: _back, onNext: _next),
    2 => StepContact(key: const ValueKey(2), nameCtrl: _nameCtrl,
          emailCtrl: _emailCtrl, phoneCtrl: _phoneCtrl,
          submitting: _submitting, onBack: _back, onSubmit: _submit),
    _ => const SizedBox.shrink(),
  };
}

// ---------------------------------------------------------------------------
// Step indicator
// ---------------------------------------------------------------------------

class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.current, required this.labels});
  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(children: [
      for (var i = 0; i < labels.length; i++) ...[
        if (i > 0)
          Expanded(child: Container(height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: i <= current ? colors.primary : colors.outlineVariant.withValues(alpha: 0.35))),
        Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 14,
            backgroundColor: i <= current ? colors.primary : colors.outlineVariant.withValues(alpha: 0.25),
            child: i < current
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                    color: i == current ? Colors.white : colors.onSurfaceVariant))),
          const SizedBox(height: 4),
          Text(labels[i], style: TextStyle(fontSize: 11,
              fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
              color: i <= current ? colors.primary : colors.onSurfaceVariant)),
        ]),
      ],
    ]);
  }
}

// ---------------------------------------------------------------------------
// Step 0 — Category
// ---------------------------------------------------------------------------

class StepCategory extends StatelessWidget {
  const StepCategory({super.key, required this.categories, required this.selected, required this.onSelect});
  final List<CustomerProduct> categories;
  final CustomerProduct? selected;
  final ValueChanged<CustomerProduct> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const HeroBanner(),
      const SizedBox(height: 20),
      Text('O que voce quer criar?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('Escolha a categoria que mais combina com sua ideia.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 3 : 2,
          mainAxisExtent: 170, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemBuilder: (context, i) {
          final cat = categories[i];
          return CategoryTile(icon: categoryIcon(cat.icon), title: cat.title,
              subtitle: 'desde ${formatMoney(cat.fromPriceCents)}',
              accent: categoryAccent(cat.icon), selected: selected?.id == cat.id,
              onTap: () => onSelect(cat));
        },
      ),
    ]);
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4865F4), Color(0xFF8462F5)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF5964F2).withValues(alpha: 0.22), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Transforme sua ideia\nem peca 3D',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2)),
          const SizedBox(height: 8),
          Text('Pecas em PLA ate 25cm. Escolha, descreva e receba um orcamento.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
        ])),
        const SizedBox(width: 12),
        const CircleAvatar(radius: 28, backgroundColor: Colors.white24,
            child: Icon(Icons.view_in_ar_rounded, size: 30, color: Colors.white)),
      ]),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.icon, required this.title,
      required this.subtitle, required this.accent, required this.selected, required this.onTap});
  final IconData icon; final String title; final String subtitle;
  final Color accent; final bool selected; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.10) : colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? accent : colors.outlineVariant.withValues(alpha: 0.25), width: selected ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: accent, size: 24)),
          const Spacer(),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: selected ? accent : colors.onSurface)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
        ]),
      ),
    ));
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Details + Customize (merged)
// ---------------------------------------------------------------------------

class StepDetails extends StatefulWidget {
  const StepDetails({super.key, required this.repository, required this.category,
      required this.descCtrl, required this.selectedItem, required this.onItemSelected,
      required this.qty, required this.sizeCtrl, required this.colorCtrl,
      required this.finish, required this.hasImage,
      required this.onQtyChanged, required this.onFinishChanged, required this.onImageChanged,
      required this.onBack, required this.onNext});

  final OperationRepository repository;
  final CustomerProduct category;
  final TextEditingController descCtrl;
  final CatalogItem? selectedItem;
  final ValueChanged<CatalogItem?> onItemSelected;
  final int qty;
  final TextEditingController sizeCtrl;
  final TextEditingController colorCtrl;
  final String finish;
  final bool hasImage;
  final ValueChanged<int> onQtyChanged;
  final ValueChanged<String> onFinishChanged;
  final ValueChanged<bool> onImageChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<StepDetails> createState() => _StepDetailsState();
}

class _StepDetailsState extends State<StepDetails> {
  late Future<List<CatalogItem>> _catalogFuture;

  @override
  void initState() {
    super.initState();
    _catalogFuture = widget.repository.getCatalogItems(widget.category.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = categoryAccent(widget.category.icon);

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Category badge
      Row(children: [
        Icon(categoryIcon(widget.category.icon), color: accent, size: 22),
        const SizedBox(width: 8),
        Text(widget.category.title, style: TextStyle(fontWeight: FontWeight.w800, color: accent)),
      ]),
      const SizedBox(height: 16),

      // --- Catalog ---
      Text('Inspire-se no catalogo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('Escolha um modelo base ou descreva do zero.',
          style: TextStyle(color: colors.onSurfaceVariant)),
      const SizedBox(height: 12),
      _buildCatalog(colors, accent),
      const SizedBox(height: 20),

      // --- Description ---
      Text('Descreva sua ideia',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      SoftPanel(child: TextField(controller: widget.descCtrl, minLines: 3, maxLines: 5,
          decoration: InputDecoration(
            hintText: widget.category.needsImage
                ? 'Descreva o que quer e anexe uma foto abaixo...'
                : 'Ex: quero 30 chaveiros com o nome "Turma 2026" em PLA branco...',
            border: InputBorder.none))),
      const SizedBox(height: 20),

      // --- Customize ---
      Text('Personalizar',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      SoftPanel(child: Column(children: [
        // Quantity
        Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.numbers_rounded, color: colors.primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text('Quantidade',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
          IconButton.outlined(onPressed: widget.qty > 1 ? () => widget.onQtyChanged(widget.qty - 1) : null,
              icon: const Icon(Icons.remove, size: 18), visualDensity: VisualDensity.compact),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('${widget.qty}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
          IconButton.outlined(onPressed: () => widget.onQtyChanged(widget.qty + 1),
              icon: const Icon(Icons.add, size: 18), visualDensity: VisualDensity.compact),
        ]),
        const SizedBox(height: 16),
        TextField(controller: widget.sizeCtrl, decoration: const InputDecoration(
            labelText: 'Tamanho aproximado', hintText: 'Ex: 8cm de altura',
            prefixIcon: Icon(Icons.straighten_rounded), border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: widget.colorCtrl, decoration: const InputDecoration(
            labelText: 'Cor desejada', hintText: 'Ex: branco, preto, azul...',
            prefixIcon: Icon(Icons.palette_outlined), border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: widget.finish,
          decoration: const InputDecoration(labelText: 'Acabamento', prefixIcon: Icon(Icons.auto_fix_high_outlined)),
          items: const [
            DropdownMenuItem(value: 'Sem preferencia', child: Text('Sem preferencia')),
            DropdownMenuItem(value: 'Fosco', child: Text('Fosco')),
            DropdownMenuItem(value: 'Brilhante', child: Text('Brilhante')),
            DropdownMenuItem(value: 'Pintado', child: Text('Pintado')),
            DropdownMenuItem(value: 'Lixado', child: Text('Lixado')),
            DropdownMenuItem(value: 'Premium', child: Text('Premium')),
          ],
          onChanged: (v) => widget.onFinishChanged(v ?? 'Sem preferencia')),
      ])),
      const SizedBox(height: 16),

      // Image
      ImageAttachCard(required_: widget.category.needsImage, attached: widget.hasImage,
          onTap: () => widget.onImageChanged(!widget.hasImage)),
      const SizedBox(height: 24),

      WizardNav(onBack: widget.onBack, onNext: widget.onNext),
    ]);
  }

  Widget _buildCatalog(ColorScheme colors, Color accent) {
    return FutureBuilder<List<CatalogItem>>(
      future: _catalogFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Icon(Icons.info_outline, color: colors.outline), const SizedBox(width: 12),
              Expanded(child: Text('Sem exemplos nessa categoria ainda.',
                  style: TextStyle(color: colors.onSurfaceVariant))),
            ]));
        }
        return SizedBox(height: 155, child: ListView.separated(
          scrollDirection: Axis.horizontal, itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final item = items[i]; final sel = widget.selectedItem?.id == item.id;
            return CatalogCard(item: item, accent: accent, selected: sel,
                onTap: () => widget.onItemSelected(sel ? null : item));
          },
        ));
      },
    );
  }
}

class CatalogCard extends StatelessWidget {
  const CatalogCard({super.key, required this.item, required this.accent, required this.selected, required this.onTap});
  final CatalogItem item; final Color accent; final bool selected; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 200), width: 180, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: 0.10) : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? accent : colors.outlineVariant.withValues(alpha: 0.25), width: selected ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
            child: Icon(catalogIcon(item.imageTag), color: accent, size: 20)),
          const Spacer(),
          if (selected) Icon(Icons.check_circle, color: accent, size: 22),
        ]),
        const Spacer(),
        Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 2),
        Text(item.style, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(formatMoney(item.priceCents), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: accent)),
      ]),
    ));
  }
}

class ImageAttachCard extends StatelessWidget {
  const ImageAttachCard({super.key, required bool required_, required this.attached, required this.onTap}) : isRequired = required_;
  final bool isRequired; final bool attached; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: attached ? colors.primary.withValues(alpha: 0.08) : colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: attached ? colors.primary.withValues(alpha: 0.35) : colors.outlineVariant)),
        child: Row(children: [
          CircleAvatar(backgroundColor: colors.primary.withValues(alpha: 0.12),
              child: Icon(attached ? Icons.image_rounded : Icons.add_photo_alternate_outlined, color: colors.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(attached ? 'Referencia adicionada' : 'Anexar foto ou referencia', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(isRequired ? 'Esse tipo de pedido precisa de uma imagem.' : 'Opcional, mas ajuda muito no orcamento.',
                style: TextStyle(color: colors.onSurfaceVariant)),
          ])),
          Icon(attached ? Icons.check_circle : Icons.upload_file_rounded, color: colors.primary),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Contact
// ---------------------------------------------------------------------------

class StepContact extends StatelessWidget {
  const StepContact({super.key, required this.nameCtrl, required this.emailCtrl,
      required this.phoneCtrl, required this.submitting, required this.onBack, required this.onSubmit});
  final TextEditingController nameCtrl; final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl; final bool submitting;
  final VoidCallback onBack; final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Quase la!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('Deixe seu contato para recebermos o pedido e enviarmos o orcamento.',
          style: TextStyle(color: colors.onSurfaceVariant)),
      const SizedBox(height: 20),
      SoftPanel(child: Column(children: [
        TextField(controller: nameCtrl, textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Seu nome', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', hintText: 'Para consultar o pedido depois',
                prefixIcon: Icon(Icons.mail_outline), border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'WhatsApp ou telefone',
                prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder())),
      ])),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: colors.primaryContainer.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(Icons.lock_outline, size: 18, color: colors.primary), const SizedBox(width: 10),
          Expanded(child: Text('Seus dados sao usados apenas para contato sobre este pedido.',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant))),
        ])),
      const SizedBox(height: 24),
      Row(children: [
        TextButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded), label: const Text('Voltar')),
        const Spacer(),
        SizedBox(height: 48, child: submitting
            ? const SizedBox(width: 48, child: Center(child: CircularProgressIndicator()))
            : GradientButton(icon: Icons.send_rounded, label: 'Enviar pedido', onPressed: onSubmit)),
      ]),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Shared nav
// ---------------------------------------------------------------------------

class WizardNav extends StatelessWidget {
  const WizardNav({super.key, required this.onBack, required this.onNext});
  final VoidCallback onBack; final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(children: [
    TextButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded), label: const Text('Voltar')),
    const Spacer(),
    GradientButton(icon: Icons.arrow_forward_rounded, label: 'Continuar', onPressed: onNext, compact: true),
  ]);
}
