import 'package:flutter/material.dart';

import '../../../core/p3d_models.dart';
import '../../../data/operation_repository.dart';
import 'portal_dashboard_page.dart';
import 'portal_login_page.dart';

/// Pagina principal do portal do cliente.
/// Gerencia o estado de autenticacao: mostra login ou dashboard.
class CustomerPortalPage extends StatefulWidget {
  const CustomerPortalPage({super.key, required this.repository});

  final OperationRepository repository;

  @override
  State<CustomerPortalPage> createState() => _CustomerPortalPageState();
}

class _CustomerPortalPageState extends State<CustomerPortalPage> {
  P3dClient? _client;

  void _onAuthenticated(P3dClient client) {
    setState(() => _client = client);
  }

  void _onLogout() {
    setState(() => _client = null);
  }

  @override
  Widget build(BuildContext context) {
    final client = _client;

    if (client == null) {
      return PortalLoginPage(
        repository: widget.repository,
        onAuthenticated: _onAuthenticated,
      );
    }

    return PortalDashboardPage(
      client: client,
      repository: widget.repository,
      onLogout: _onLogout,
    );
  }
}
