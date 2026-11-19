import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/widgets/label_scanner.dart';

void main() {
  testWidgets('says where to point the camera and offers to type the number', (tester) async {
    var typing = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabelScanner(
            camera: false,
            onScanned: (_) {},
            onTypeNumber: () => typing = true,
          ),
        ),
      ),
    );

    expect(find.text('Fit the QR code inside the frame'), findsOneWidget);

    // the hint sits on top of the button, so the two can't run into each other
    expect(
      tester.getBottomLeft(find.text('Fit the QR code inside the frame')).dy,
      lessThan(tester.getTopLeft(find.text('Type the number instead')).dy),
    );

    await tester.tap(find.text('Type the number instead'));

    expect(typing, isTrue);
  });
}