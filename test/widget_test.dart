import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pagobus/main.dart';

void main() {
  testWidgets('PagoBus app starts and shows the bottom navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PagoBusApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
