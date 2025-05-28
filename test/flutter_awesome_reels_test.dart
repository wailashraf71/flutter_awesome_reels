import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:flutter_awesome_reels/flutter_awesome_reels.dart';

void main() {
  testWidgets('AwesomeReels widget can be created',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AwesomeReels(
          reels: [],
        ),
      ),
    ));
    expect(find.byType(AwesomeReels), findsOneWidget);
  });
}
