import 'package:flutter_test/flutter_test.dart';

import 'package:tic/main.dart';

void main() {
  testWidgets('App launches and shows game board', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const TicTacToeApp());

    // Verify scoreboard labels are present
    expect(find.text('PLAYER (X)'), findsOneWidget);
    expect(find.text('AI (O)'), findsOneWidget);
    expect(find.text('DRAW'), findsOneWidget);

    // Verify initial status message
    expect(find.text('YOUR MOVE — SELECT A CELL'), findsOneWidget);
  });
}
