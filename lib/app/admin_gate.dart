import 'package:flutter/material.dart';

import '../data/operation_repository.dart';
import '../data/services/auth_service.dart';
import 'admin_shell.dart';
import 'auth_page.dart';

/// Shows [AuthPage] if not logged in, [AppShell] if authenticated.
class AdminGate extends StatefulWidget {
  const AdminGate({
    super.key,
    required this.authService,
    required this.repository,
  });

  final AuthService authService;
  final OperationRepository repository;

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late bool _authenticated;

  @override
  void initState() {
    super.initState();
    _authenticated = widget.authService.isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    if (!_authenticated) {
      return AuthPage(
        authService: widget.authService,
        onAuthenticated: () => setState(() => _authenticated = true),
      );
    }
    return AppShell(repository: widget.repository);
  }
}
