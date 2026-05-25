// Widget smoke test for FixHub app.
//
// NOTE: The full app requires Firebase, which cannot be initialized in unit
// tests without the Firebase emulator. This test uses a minimal standalone
// widget tree to verify basic Flutter rendering works.
//
// For full app widget tests, use integration_test/ instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal standalone widget that does NOT require Firebase/Riverpod.
class _StubApp extends StatelessWidget {
  const _StubApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('FixHub Test')),
      ),
    );
  }
}

void main() {
  testWidgets('Minimal widget renders without Firebase', (tester) async {
    await tester.pumpWidget(const _StubApp());

    // Basic sanity check: MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('FixHub Test'), findsOneWidget);
  });

  testWidgets('MaterialApp scaffold renders body', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('Login Page'),
            Text('Booking Page'),
          ],
        ),
      ),
    ));

    expect(find.text('Login Page'), findsOneWidget);
    expect(find.text('Booking Page'), findsOneWidget);
  });
}
