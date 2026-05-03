import 'package:flutter/material.dart';

import '../data/api_operation_repository.dart';
import '../data/services/api_client.dart';
import '../data/services/auth_service.dart';
import '../data/services/token_service.dart';
import '../features/customer_orders/presentation/customer_order_page.dart';
import '../features/customer_portal/presentation/customer_portal_page.dart';
import '../features/landing/presentation/landing_page.dart';
import 'admin_gate.dart';

class P3dApp extends StatelessWidget {
  const P3dApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenService = TokenService();
    final apiClient = ApiClient(tokenService);
    final authService = AuthService(tokenService);
    final repository = ApiOperationRepository(client: apiClient);

    return MaterialApp(
      title: 'PrintFlow',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: '/',
      routes: {
        '/': (ctx) => LandingPage(
          onOpenAdmin: () => Navigator.of(ctx).pushNamed('/admin'),
          onOpenPortal: () => Navigator.of(ctx).pushNamed('/portal'),
        ),
        '/order': (_) => CustomerOrderPage(
          repository: repository,
          onOpenAdmin: (ctx) => Navigator.of(ctx).pushNamed('/admin'),
        ),
        '/portal': (_) => CustomerPortalPage(repository: repository),
        '/admin': (_) =>
            AdminGate(authService: authService, repository: repository),
      },
    );
  }

  static ThemeData _buildTheme() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F56E8),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F7FC),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Color(0xFFF5F7FC),
    ),
    cardTheme: const CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      dividerHeight: 0,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: const Color(0xFF5B5FEF),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
      ),
      labelColor: Colors.white,
      unselectedLabelColor: const Color(0xFF4A5568),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF5B5FEF), width: 1.2),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 72,
    ),
  );
}
