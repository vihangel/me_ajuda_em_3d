import 'package:flutter/material.dart';

import '../../../core/ui_components.dart';
import '../../customer_orders/presentation/order_helpers.dart';

// ---------------------------------------------------------------------------
// Landing Page
// ---------------------------------------------------------------------------

class LandingPage extends StatelessWidget {
  const LandingPage({super.key, this.onOpenAdmin, this.onOpenPortal});
  final VoidCallback? onOpenAdmin;
  final VoidCallback? onOpenPortal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _LandingTopBar(
              onOpenAdmin: onOpenAdmin,
              onOpenPortal: onOpenPortal,
            ),
            Expanded(
              child: _LandingBody(
                onStartOrder: () => Navigator.of(context).pushNamed('/order'),
                onTrackOrder: () =>
                    Navigator.of(context).pushNamed('/order', arguments: 1),
                onOpenPortal: onOpenPortal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _LandingTopBar extends StatelessWidget {
  const _LandingTopBar({this.onOpenAdmin, this.onOpenPortal});
  final VoidCallback? onOpenAdmin;
  final VoidCallback? onOpenPortal;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
          if (onOpenPortal != null)
            TextButton.icon(
              onPressed: onOpenPortal,
              icon: const Icon(Icons.storefront_outlined, size: 18),
              label: const Text('Portal do Cliente'),
            ),
          if (onOpenPortal != null) const SizedBox(width: 8),
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

// ---------------------------------------------------------------------------
// Body — full-width scroll, content constrained inside each section
// ---------------------------------------------------------------------------

class _LandingBody extends StatelessWidget {
  const _LandingBody({
    required this.onStartOrder,
    required this.onTrackOrder,
    this.onOpenPortal,
  });
  final VoidCallback onStartOrder;
  final VoidCallback onTrackOrder;
  final VoidCallback? onOpenPortal;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 24),
        _Constrained(child: _HeroSection(onStart: onStartOrder)),
        const SizedBox(height: 40),
        _Constrained(child: _HowItWorksSection()),
        const SizedBox(height: 40),
        _Constrained(child: _CategoriesShowcase(onExplore: onStartOrder)),
        const SizedBox(height: 40),
        _Constrained(
          child: _CtaFooter(
            onStart: onStartOrder,
            onTrack: onTrackOrder,
            onPortal: onOpenPortal,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Wraps content with horizontal padding and a max width so it looks
/// good on both mobile and desktop without constraining the scroll area.
class _Constrained extends StatelessWidget {
  const _Constrained({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Hero section
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4558F0), Color(0xFF7C5CF5), Color(0xFF9B6DFA)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5964F2).withValues(alpha: 0.28),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.amber.shade200,
                ),
                const SizedBox(width: 6),
                Text(
                  'Producao sob medida',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Tire suas ideias\ndo papel',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Subtitle
          Text(
            'Crie brindes, miniaturas e pecas unicas\ncom o seu toque pessoal.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // CTA buttons — Wrap so they stack on narrow screens
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _HeroCta(
                label: 'Comecar agora',
                icon: Icons.arrow_forward_rounded,
                onTap: onStart,
              ),
              _HeroSecondary(label: 'Ver categorias', onTap: onStart),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCta extends StatelessWidget {
  const _HeroCta({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF4558F0),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: const Color(0xFF4558F0), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSecondary extends StatelessWidget {
  const _HeroSecondary({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Como funciona — responsive: Row on wide, Column on narrow
// ---------------------------------------------------------------------------

class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final narrow = MediaQuery.sizeOf(context).width < 520;

    final cards = [
      _StepCard(
        number: '1',
        icon: Icons.edit_note_rounded,
        title: 'Descreva',
        desc: 'Conte sua ideia e escolha o tipo de peca',
        color: const Color(0xFF4558F0),
      ),
      _StepCard(
        number: '2',
        icon: Icons.calculate_outlined,
        title: 'Receba o orcamento',
        desc: 'Avaliamos e enviamos o valor',
        color: const Color(0xFF7C5CF5),
      ),
      _StepCard(
        number: '3',
        icon: Icons.local_shipping_outlined,
        title: 'Retirada disponivel',
        desc: 'Produzimos e esta pronto para retirada',
        color: const Color(0xFF9B6DFA),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'COMO FUNCIONA'),
        const SizedBox(height: 8),
        Text(
          'Simples assim',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Do pedido a entrega, rapidinho ta mao.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 20),
        if (narrow)
          // Stack vertically on small screens
          Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                cards[i],
              ],
            ],
          )
        else
          // Side by side on wider screens
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: cards[i]),
              ],
            ],
          ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
  final String number;
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Categorias — responsive grid
// ---------------------------------------------------------------------------

class _CategoriesShowcase extends StatelessWidget {
  const _CategoriesShowcase({required this.onExplore});
  final VoidCallback onExplore;

  static const _items = [
    _CategoryPreview(
      icon: 'key',
      title: 'Chaveiros',
      desc: 'Pecas pequenas e personalizadas',
    ),
    _CategoryPreview(
      icon: 'miniature',
      title: 'Miniaturas',
      desc: 'Personagens e modelos detalhados',
    ),
    _CategoryPreview(
      icon: 'decor',
      title: 'Objetos decorativos',
      desc: 'Vasos, enfeites e pecas unicas',
    ),
    _CategoryPreview(
      icon: 'frame',
      title: 'Placas e letreiros',
      desc: 'Sinalizacao com estilo',
    ),
    _CategoryPreview(
      icon: 'lamp',
      title: 'Luminarias',
      desc: 'Litofanias e abajures criativos',
    ),
    _CategoryPreview(
      icon: 'image',
      title: 'A partir de foto',
      desc: 'Transforme imagens em pecas',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 700 ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'O QUE CRIAMOS'),
        const SizedBox(height: 8),
        Text(
          'Feito do seu jeito',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Brindes, presentes, decoracao... voce imagina, a gente produz.',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 130,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, i) {
            final item = _items[i];
            return _CategoryShowcardTile(
              icon: categoryIcon(item.icon),
              accent: categoryAccent(item.icon),
              title: item.title,
              desc: item.desc,
              onTap: onExplore,
            );
          },
        ),
      ],
    );
  }
}

class _CategoryPreview {
  const _CategoryPreview({
    required this.icon,
    required this.title,
    required this.desc,
  });
  final String icon;
  final String title;
  final String desc;
}

class _CategoryShowcardTile extends StatelessWidget {
  const _CategoryShowcardTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.desc,
    required this.onTap,
  });
  final IconData icon;
  final Color accent;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                  height: 1.3,
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
// 4. CTA footer
// ---------------------------------------------------------------------------

class _CtaFooter extends StatelessWidget {
  const _CtaFooter({
    required this.onStart,
    required this.onTrack,
    this.onPortal,
  });
  final VoidCallback onStart;
  final VoidCallback onTrack;
  final VoidCallback? onPortal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(
            'Pronto para comecar?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Descreva o que precisa e receba um orcamento rapido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              icon: Icons.rocket_launch_rounded,
              label: 'Criar pedido',
              onPressed: onStart,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onTrack,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Ja fez um pedido? Acompanhe aqui'),
          ),
          if (onPortal != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onPortal,
              icon: const Icon(Icons.storefront_outlined, size: 18),
              label: const Text('Cliente recorrente? Acesse o portal'),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared — section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
