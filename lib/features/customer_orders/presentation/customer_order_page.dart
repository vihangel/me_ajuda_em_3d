import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';

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
  final _emailLookupController = TextEditingController(
    text: 'marina@email.com',
  );
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _detailsController = TextEditingController();
  final _otherController = TextEditingController();
  final _useController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _budgetController = TextEditingController();
  CustomerKind _kind = CustomerKind.person;
  CustomerProduct? _selectedProduct;
  bool _hasReferenceImage = false;
  int _quantity = 1;
  String _finishPreference = 'Sem preferencia';
  String _deliveryPreference = 'Retirada';

  @override
  void dispose() {
    _emailLookupController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _detailsController.dispose();
    _otherController.dispose();
    _useController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _deadlineController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          return _PublicOrderShell(
            title: 'Fazer pedido',
            subtitle: 'Pedido simples para cliente, sem login',
            onOpenAdmin: widget.onOpenAdmin == null
                ? null
                : () => widget.onOpenAdmin!(context),
            actions: [
              ActionPill(
                icon: Icons.history_rounded,
                label: 'Ver pedidos abertos',
                onPressed: () => DefaultTabController.of(context).animateTo(1),
              ),
            ],
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SoftPanel(
                    padding: EdgeInsets.all(4),
                    child: TabBar(
                      tabs: [
                        Tab(text: 'Criar pedido'),
                        Tab(text: 'Ver abertos'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _CreateOrderView(
                        repository: widget.repository,
                        selectedProduct: _selectedProduct,
                        kind: _kind,
                        hasReferenceImage: _hasReferenceImage,
                        quantity: _quantity,
                        nameController: _nameController,
                        emailController: _emailController,
                        phoneController: _phoneController,
                        detailsController: _detailsController,
                        otherController: _otherController,
                        useController: _useController,
                        sizeController: _sizeController,
                        colorController: _colorController,
                        deadlineController: _deadlineController,
                        budgetController: _budgetController,
                        finishPreference: _finishPreference,
                        deliveryPreference: _deliveryPreference,
                        onProductChanged: (value) =>
                            setState(() => _selectedProduct = value),
                        onKindChanged: (value) => setState(() => _kind = value),
                        onImageChanged: (value) =>
                            setState(() => _hasReferenceImage = value),
                        onQuantityChanged: (value) =>
                            setState(() => _quantity = value),
                        onFinishChanged: (value) =>
                            setState(() => _finishPreference = value),
                        onDeliveryChanged: (value) =>
                            setState(() => _deliveryPreference = value),
                      ),
                      _LookupOrdersView(
                        repository: widget.repository,
                        controller: _emailLookupController,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PublicOrderShell extends StatelessWidget {
  const _PublicOrderShell({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.actions,
    this.onOpenAdmin,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (wide) ...[const SizedBox(width: 12), ...actions],
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(height: MediaQuery.sizeOf(context).height - 174, child: child),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _PublicTopBar(onOpenAdmin: onOpenAdmin),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wide ? 1180 : double.infinity,
                  ),
                  child: body,
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
    final wide = MediaQuery.sizeOf(context).width >= 980;

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 28),
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
          const BrandMark(),
          const Spacer(),
          if (wide)
            FilledButton.tonalIcon(
              onPressed: () => showComingSoon(context, 'Modo rapido'),
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Modo rapido'),
            ),
          const SizedBox(width: 12),
          if (wide) const SizedBox(width: 360, child: AppSearchField()),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Notificacoes',
            onPressed: () => showComingSoon(context, 'Notificacoes'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton.filledTonal(
            tooltip: 'Admin',
            onPressed: onOpenAdmin,
            icon: const Icon(Icons.shield_outlined),
          ),
        ],
      ),
    );
  }
}

class _CreateOrderView extends StatelessWidget {
  const _CreateOrderView({
    required this.repository,
    required this.selectedProduct,
    required this.kind,
    required this.hasReferenceImage,
    required this.quantity,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.detailsController,
    required this.otherController,
    required this.useController,
    required this.sizeController,
    required this.colorController,
    required this.deadlineController,
    required this.budgetController,
    required this.finishPreference,
    required this.deliveryPreference,
    required this.onProductChanged,
    required this.onKindChanged,
    required this.onImageChanged,
    required this.onQuantityChanged,
    required this.onFinishChanged,
    required this.onDeliveryChanged,
  });

  final OperationRepository repository;
  final CustomerProduct? selectedProduct;
  final CustomerKind kind;
  final bool hasReferenceImage;
  final int quantity;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController detailsController;
  final TextEditingController otherController;
  final TextEditingController useController;
  final TextEditingController sizeController;
  final TextEditingController colorController;
  final TextEditingController deadlineController;
  final TextEditingController budgetController;
  final String finishPreference;
  final String deliveryPreference;
  final ValueChanged<CustomerProduct> onProductChanged;
  final ValueChanged<CustomerKind> onKindChanged;
  final ValueChanged<bool> onImageChanged;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> onFinishChanged;
  final ValueChanged<String> onDeliveryChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final twoColumns = width > 900;

    return FutureBuilder<List<CustomerProduct>>(
      future: repository.getCustomerProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingStateView();
        }
        if (snapshot.hasError) {
          return ErrorStateView(
            message: 'Nao foi possivel carregar os produtos.',
            onRetry: () {},
          );
        }

        final products = snapshot.data ?? [];
        final activeProduct =
            selectedProduct ?? (products.isNotEmpty ? products.first : null);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ClientHero(onStart: () {}),
            const SizedBox(height: 16),
            if (twoColumns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _ProductPicker(
                      products: products,
                      selected: activeProduct,
                      onChanged: onProductChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: _OrderForm(
                      repository: repository,
                      selectedProduct: activeProduct,
                      kind: kind,
                      hasReferenceImage: hasReferenceImage,
                      quantity: quantity,
                      nameController: nameController,
                      emailController: emailController,
                      phoneController: phoneController,
                      detailsController: detailsController,
                      otherController: otherController,
                      useController: useController,
                      sizeController: sizeController,
                      colorController: colorController,
                      deadlineController: deadlineController,
                      budgetController: budgetController,
                      finishPreference: finishPreference,
                      deliveryPreference: deliveryPreference,
                      onKindChanged: onKindChanged,
                      onImageChanged: onImageChanged,
                      onQuantityChanged: onQuantityChanged,
                      onFinishChanged: onFinishChanged,
                      onDeliveryChanged: onDeliveryChanged,
                    ),
                  ),
                ],
              )
            else ...[
              _ProductPicker(
                products: products,
                selected: activeProduct,
                onChanged: onProductChanged,
              ),
              const SizedBox(height: 16),
              _OrderForm(
                repository: repository,
                selectedProduct: activeProduct,
                kind: kind,
                hasReferenceImage: hasReferenceImage,
                quantity: quantity,
                nameController: nameController,
                emailController: emailController,
                phoneController: phoneController,
                detailsController: detailsController,
                otherController: otherController,
                useController: useController,
                sizeController: sizeController,
                colorController: colorController,
                deadlineController: deadlineController,
                budgetController: budgetController,
                finishPreference: finishPreference,
                deliveryPreference: deliveryPreference,
                onKindChanged: onKindChanged,
                onImageChanged: onImageChanged,
                onQuantityChanged: onQuantityChanged,
                onFinishChanged: onFinishChanged,
                onDeliveryChanged: onDeliveryChanged,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ClientHero extends StatelessWidget {
  const _ClientHero({required this.onStart});

  final VoidCallback onStart;

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
            color: const Color(0xFF5964F2).withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transforme uma ideia em peca 3D',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Escolha um produto base, descreva a ideia e deixe email e telefone. A resposta vira orcamento antes de entrar na fila.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            child: Icon(Icons.add_rounded, size: 36, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ProductPicker extends StatelessWidget {
  const _ProductPicker({
    required this.products,
    required this.selected,
    required this.onChanged,
  });

  final List<CustomerProduct> products;
  final CustomerProduct? selected;
  final ValueChanged<CustomerProduct> onChanged;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const EmptyStateView(
        title: 'Sem produtos base',
        message: 'Cadastre produtos comuns para o cliente escolher.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Produtos comuns'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 2 : 1,
            mainAxisExtent: 326,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return _CustomerProductCard(
              product: product,
              selected: selected?.id == product.id,
              onTap: () => onChanged(product),
            );
          },
        ),
      ],
    );
  }
}

class _CustomerProductCard extends StatelessWidget {
  const _CustomerProductCard({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final CustomerProduct product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : _productAccent(product.icon);

    return SoftPanel(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 70,
                  height: 62,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(_productIcon(product.icon), color: color),
                ),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: selected ? colors.primary : colors.outline,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              product.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'desde ${formatMoney(product.fromPriceCents)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final example in product.examples.take(3))
                  AppStatusChip(label: example, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderForm extends StatelessWidget {
  const _OrderForm({
    required this.repository,
    required this.selectedProduct,
    required this.kind,
    required this.hasReferenceImage,
    required this.quantity,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.detailsController,
    required this.otherController,
    required this.useController,
    required this.sizeController,
    required this.colorController,
    required this.deadlineController,
    required this.budgetController,
    required this.finishPreference,
    required this.deliveryPreference,
    required this.onKindChanged,
    required this.onImageChanged,
    required this.onQuantityChanged,
    required this.onFinishChanged,
    required this.onDeliveryChanged,
  });

  final OperationRepository repository;
  final CustomerProduct? selectedProduct;
  final CustomerKind kind;
  final bool hasReferenceImage;
  final int quantity;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController detailsController;
  final TextEditingController otherController;
  final TextEditingController useController;
  final TextEditingController sizeController;
  final TextEditingController colorController;
  final TextEditingController deadlineController;
  final TextEditingController budgetController;
  final String finishPreference;
  final String deliveryPreference;
  final ValueChanged<CustomerKind> onKindChanged;
  final ValueChanged<bool> onImageChanged;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> onFinishChanged;
  final ValueChanged<String> onDeliveryChanged;

  @override
  Widget build(BuildContext context) {
    final isOther = selectedProduct?.id == 'customer_other';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Detalhes do pedido'),
        SoftPanel(
          child: Column(
            children: [
              SegmentedButton<CustomerKind>(
                segments: [
                  for (final value in CustomerKind.values)
                    ButtonSegment(value: value, label: Text(value.label)),
                ],
                selected: {kind},
                onSelectionChanged: (value) => onKindChanged(value.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: kind == CustomerKind.company
                      ? 'Nome da empresa'
                      : 'Seu nome',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email para consultar depois',
                  prefixIcon: Icon(Icons.mail_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone ou WhatsApp',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              if (isOther) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: otherController,
                  decoration: const InputDecoration(
                    labelText: 'O que voce quer pedir?',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _SelectedProductSummary(product: selectedProduct),
              const SizedBox(height: 12),
              TextField(
                controller: useController,
                decoration: const InputDecoration(
                  labelText: 'Onde ou como a peca sera usada?',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sizeController,
                      decoration: const InputDecoration(
                        labelText: 'Tamanho aproximado',
                        prefixIcon: Icon(Icons.straighten_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: colorController,
                      decoration: const InputDecoration(
                        labelText: 'Cor desejada',
                        prefixIcon: Icon(Icons.palette_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: finishPreference,
                decoration: const InputDecoration(
                  labelText: 'Acabamento desejado',
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
                  DropdownMenuItem(value: 'Premium', child: Text('Premium')),
                ],
                onChanged: (value) =>
                    onFinishChanged(value ?? 'Sem preferencia'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Conte detalhes importantes',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quantidade',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Diminuir',
                    onPressed: quantity > 1
                        ? () => onQuantityChanged(quantity - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '$quantity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    tooltip: 'Aumentar',
                    onPressed: () => onQuantityChanged(quantity + 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: deliveryPreference == 'Entrega',
                onChanged: (value) =>
                    onDeliveryChanged(value ? 'Entrega' : 'Retirada'),
                title: const Text('Prefiro entrega'),
                subtitle: Text(
                  deliveryPreference == 'Entrega'
                      ? 'Vamos combinar endereco e frete depois.'
                      : 'Retirada no local quando estiver pronto.',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: deadlineController,
                      decoration: const InputDecoration(
                        labelText: 'Prazo desejado',
                        prefixIcon: Icon(Icons.event_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: budgetController,
                      decoration: const InputDecoration(
                        labelText: 'Orcamento previsto',
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ReferenceAttachmentCard(
                requiredByProduct: selectedProduct?.needsImage ?? false,
                attached:
                    hasReferenceImage || (selectedProduct?.needsImage ?? false),
                onTap: () => onImageChanged(true),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  icon: Icons.send_rounded,
                  label: 'Enviar pedido',
                  onPressed: () async {
                    final order = await repository.createCustomerOrder(
                      CreateCustomerOrderInput(
                        customerName: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        kind: kind,
                        productTitle:
                            selectedProduct?.title ?? otherController.text,
                        description: _buildBriefingDescription(
                          details: detailsController.text,
                          use: useController.text,
                          size: sizeController.text,
                          color: colorController.text,
                          finish: finishPreference,
                          deadline: deadlineController.text,
                          budget: budgetController.text,
                          delivery: deliveryPreference,
                        ),
                        quantity: quantity,
                        hasReferenceImage:
                            hasReferenceImage ||
                            (selectedProduct?.needsImage ?? false),
                      ),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Pedido ${order.code} criado.')),
                    );
                    DefaultTabController.of(context).animateTo(1);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectedProductSummary extends StatelessWidget {
  const _SelectedProductSummary({required this.product});

  final CustomerProduct? product;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              product == null
                  ? 'Escolha um produto base para iniciar o briefing.'
                  : 'Pedido baseado em: ${product!.title}. O material ideal sera definido pela equipe 3D.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceAttachmentCard extends StatelessWidget {
  const _ReferenceAttachmentCard({
    required this.requiredByProduct,
    required this.attached,
    required this.onTap,
  });

  final bool requiredByProduct;
  final bool attached;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: attached
              ? colors.primary.withValues(alpha: 0.08)
              : colors.surfaceContainerHighest.withValues(alpha: 0.55),
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
                        : 'Anexar imagem ou referencia',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    requiredByProduct
                        ? 'Esse tipo de pedido precisa de foto, desenho ou print.'
                        : 'Foto, print, desenho ou imagem parecida ajudam muito.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.upload_file_rounded, color: colors.primary),
          ],
        ),
      ),
    );
  }
}

String _buildBriefingDescription({
  required String details,
  required String use,
  required String size,
  required String color,
  required String finish,
  required String deadline,
  required String budget,
  required String delivery,
}) {
  return [
    if (use.trim().isNotEmpty) 'Uso: $use',
    if (size.trim().isNotEmpty) 'Tamanho: $size',
    if (color.trim().isNotEmpty) 'Cor: $color',
    'Acabamento: $finish',
    if (deadline.trim().isNotEmpty) 'Prazo desejado: $deadline',
    if (budget.trim().isNotEmpty) 'Orcamento previsto: $budget',
    'Entrega/retirada: $delivery',
    if (details.trim().isNotEmpty) 'Detalhes: $details',
  ].join('\n');
}

class _LookupOrdersView extends StatefulWidget {
  const _LookupOrdersView({required this.repository, required this.controller});

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
          Text(order.description),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
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

IconData _productIcon(String icon) {
  return switch (icon) {
    'key' => Icons.vpn_key_outlined,
    'decor' => Icons.weekend_outlined,
    'frame' => Icons.crop_original_outlined,
    'image' => Icons.image_outlined,
    _ => Icons.category_outlined,
  };
}

Color _productAccent(String icon) {
  return switch (icon) {
    'key' => const Color(0xFF6B5CF6),
    'decor' => const Color(0xFFC76A28),
    'frame' => const Color(0xFF2D9B7F),
    'image' => const Color(0xFF4B7BE5),
    _ => const Color(0xFF5B677A),
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
