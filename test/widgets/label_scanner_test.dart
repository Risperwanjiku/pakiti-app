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

    expect(find.text('Point the camera at the QR code on the label'), findsOneWidget);

    await tester.tap(find.text('Type the number instead'));

    expect(typing, isTrue);
  });
}