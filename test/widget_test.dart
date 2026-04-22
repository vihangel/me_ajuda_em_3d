import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:me_ajuda_em_3d/app/app.dart';

void main() {
  testWidgets('renders public order entry and opens admin route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const P3dApp());

    await tester.pumpAndSettle();

    expect(find.text('Fazer pedido'), findsOneWidget);
    expect(find.text('Chaveiro personalizado'), findsOneWidget);
    expect(find.text('Ver abertos'), findsOneWidget);
    expect(find.text('Home'), findsNothing);

    await tester.tap(find.byIcon(Icons.shield_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Cockpit 3D'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
