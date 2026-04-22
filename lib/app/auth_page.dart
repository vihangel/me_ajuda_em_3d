import 'package:flutter/material.dart';

import '../core/ui_components.dart';
import '../data/services/auth_service.dart';

/// Login / Register gate shown before the admin panel.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.authService, required this.onAuthenticated});
  final AuthService authService;
  final VoidCallback onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Preencha email e senha.');
      return;
    }
    if (!_isLogin && _nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Preencha seu nome.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await widget.authService.login(email: email, password: pass);
      } else {
        await widget.authService.register(
          name: _nameCtrl.text.trim(), email: email, password: pass);
      }
      widget.onAuthenticated();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro de conexao. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(),
                  const SizedBox(height: 32),
                  Text(
                    _isLogin ? 'Entrar no painel' : 'Criar conta admin',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin
                        ? 'Use suas credenciais para acessar o admin.'
                        : 'Crie uma conta para gerenciar o painel.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SoftPanel(
                    child: Column(children: [
                      if (!_isLogin) ...[
                        TextField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ]),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!,
                          style: TextStyle(color: colors.onErrorContainer)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : GradientButton(
                            icon: _isLogin ? Icons.login_rounded : Icons.person_add_rounded,
                            label: _isLogin ? 'Entrar' : 'Criar conta',
                            onPressed: _submit,
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() {
                      _isLogin = !_isLogin;
                      _error = null;
                    }),
                    child: Text(_isLogin
                        ? 'Nao tem conta? Criar agora'
                        : 'Ja tem conta? Entrar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Voltar para pedidos'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
