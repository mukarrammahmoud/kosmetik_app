import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/prosenj_gate_screen.dart';

void main() {
  testWidgets('App renders permission screen title', (WidgetTester tester) async {
    await tester.pumpWidget(const PermissionDemoApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('أذونات الجوال'), findsOneWidget);
  });

  testWidgets('Gate screen shows prompt and yes navigates to welcome', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProsenjGateScreen(grantedCount: 29, totalCount: 29),
      ),
    );
    await tester.pump();

    expect(find.text('للدخول الى عالم التجميل الاجراحي برسنج اضغط نعم'), findsOneWidget);
    expect(find.text('نعم'), findsOneWidget);
    expect(find.text('لا'), findsOneWidget);

    await tester.tap(find.text('نعم'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('الأذونات مفعّلة!'), findsOneWidget);
  });

  testWidgets('Gate screen no button goes back', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProsenjGateScreen(grantedCount: 29, totalCount: 29),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('لا'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('للدخول الى عالم التجميل الاجراحي برسنج اضغط نعم'), findsNothing);
  });
}
