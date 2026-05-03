import 'package:flutter/material.dart';

import '../../../core/p3d_models.dart';
import '../../../core/ui_components.dart';
import '../../../data/operation_repository.dart';

/// Tela de login do portal do cliente.
/// O cliente digita seu código (ex: luiz-a-banca) e acessa o dashboard.
class PortalLoginPage extends StatefulWidget {
  const PortalLoginPage({
    super.key,
    required this.repository,
    required this.onAuthenticated,
  });

  final OperationRepository repository;
  final void Function(P3dClient client) onAuthenticated;

  @override
  State<PortalLoginPage> createState() => _PortalLoginPageState();
}

class _PortalLoginPageState extends State<PortalLoginPage> {
  final _codeCtrl = TextEditingController(text: 'luiz-a-banca');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Digite seu codigo de acesso.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = await widget.repository.portalLogin(code);
      if (!mounted) return;

      if (client == null) {
        setState(() {
          _loading = false;
          _error = 'Codigo nao encontrado. Verifique e tente novamente.';
        });
      } else {
        setState(() => _loading = false);
        widget.onAuthenticated(client);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erro ao conectar. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const BrandMark(),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Voltar'),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: wide ? 440 : double.infinity,
                    ),
                    child: SoftPanel(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: colors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Portal do Cliente',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Acesse com seu codigo para ver seus produtos, '
                            'pagamentos e solicitar novos pedidos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 28),

                          // Code input
                          TextField(
                            controller: _codeCtrl,
                            textInputAction: TextInputAction.go,
                            onSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Codigo de acesso',
                              hintText: 'nome-inicial-empresa',
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                size: 20,
                              ),
                              errorText: _error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Ex: luiz-a-banca',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.outline),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            child: _loading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : GradientButton(
                                    icon: Icons.login_rounded,
                                    label: 'Entrar',
                                    onPressed: _login,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
