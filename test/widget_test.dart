import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App renders permission cards and title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PermissionDemoApp());
    await tester.pump();

    // Verify that the title and permission cards exist.
    expect(find.text('Android Permissions'), findsOneWidget);
    expect(find.text('Location Permission'), findsOneWidget);
    expect(find.text('Voice & Microphone Permission'), findsOneWidget);
  });
}
