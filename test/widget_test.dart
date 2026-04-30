import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Just verify Flutter itself works
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Tic Tac Toe'),
          ),
        ),
      ),
    );

    expect(find.text('Tic Tac Toe'), findsOneWidget);
  });
}