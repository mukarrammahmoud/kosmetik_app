import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/prosenj_gate_screen.dart';
import 'package:flutter_application_1/welcome_screen.dart';

/// Asset keys are relative to the pubspec.yaml location, NOT to the directory
/// that was declared. Declaring `lib/images/` yields the key `lib/images/logo.png`.
const String kLogoAsset = 'lib/images/logo.png';

/// Forces the logo to resolve so a missing/renamed asset throws instead of
/// silently rendering the errorBuilder fallback.
Future<void> _expectLogoResolves(WidgetTester tester, String screen) async {
  await tester.pump();

  await tester.runAsync(() async {
    final image = AssetImage(kLogoAsset);
    await precacheImage(image, tester.element(find.byType(Image).first));
    // A wrong key resolves to an empty stream / throws; assert real bytes.
    final key = await image.obtainKey(const ImageConfiguration());
    expect(key.name, kLogoAsset);
  });

  expect(
    find.byIcon(Icons.image_not_supported_rounded),
    findsNothing,
    reason: '$screen: logo asset failed to load (errorBuilder fallback shown)',
  );
  expect(
    find.byIcon(Icons.spa_rounded),
    findsNothing,
    reason: '$screen: logo asset failed to load (errorBuilder fallback shown)',
  );
}

void main() {
  test('logo file exists on disk', () {
    expect(File(kLogoAsset).existsSync(), isTrue, reason: '$kLogoAsset missing');
  });

  testWidgets('App renders permission screen title', (WidgetTester tester) async {
    await tester.pumpWidget(const PermissionDemoApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('أذونات الجوال'), findsOneWidget);
  });

  testWidgets('Gate screen renders the real logo image', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProsenjGateScreen(grantedCount: 23, totalCount: 23)),
    );
    await _expectLogoResolves(tester, 'ProsenjGateScreen');
  });

  testWidgets('Welcome screen renders the real logo image', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WelcomeScreen(grantedCount: 23, totalCount: 23)),
    );
    await _expectLogoResolves(tester, 'WelcomeScreen');
  });

  testWidgets('Gate screen shows prompt and yes navigates to welcome', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProsenjGateScreen(grantedCount: 29, totalCount: 29),
      ),
    );
    await tester.pump();

    expect(find.text('للدخول الى عالم التجميل الاجراحي برستج اضغط نعم'), findsOneWidget);
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
