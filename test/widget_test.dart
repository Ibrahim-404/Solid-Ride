// Part of solid_principles_demo by Ibrahim Abo El-Haggag

import 'package:flutter_test/flutter_test.dart';
import 'package:solid_principles_demo/main.dart';

void main() {
  testWidgets('SolidPrinciplesDemoApp loads cleanly and displays principle tabs', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SolidPrinciplesDemoApp());

    // Verify header title is rendered
    expect(find.text('SOLID Principles Demo'), findsOneWidget);

    // Verify principle acronym tabs exist
    expect(find.text('SRP'), findsWidgets);
    expect(find.text('OCP'), findsWidgets);
    expect(find.text('LSP'), findsWidgets);
    expect(find.text('ISP'), findsWidgets);
    expect(find.text('DIP'), findsWidgets);
  });
}
