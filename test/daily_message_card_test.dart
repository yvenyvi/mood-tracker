import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/widgets/daily_message_card.dart';

void main() {
  testWidgets('DailyMessageCard renders correctly', (
    WidgetTester tester,
  ) async {
    // Build the DailyMessageCard widget wrapped in a MaterialApp/Scaffold
    // to provide necessary Theme context.
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: const DailyMessageCard())),
    );

    // Verify that the icon is present
    expect(find.byIcon(Icons.emoji_emotions), findsOneWidget);

    // Verify that some text is present (the message itself changes daily,
    // so we just check if any text widget besides the icon exists)
    expect(find.byType(Text), findsOneWidget);
  });
}
