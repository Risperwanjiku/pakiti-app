import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/destination.dart';
import 'package:pakiti_app/models/parcel_size.dart';
import 'package:pakiti_app/screens/clerk/book_parcel_screen.dart';

const nairobi = Destination(
  routeId: 1,
  town: 'Nairobi',
  county: 'Nairobi',
  travelMinutes: 180,
  fees: {ParcelSize.small: 200, ParcelSize.medium: 350, ParcelSize.large: 500},
);

// the text boxes from top to bottom: what's inside, value, sender's name,
// sender's phone, receiver's name, receiver's phone
Finder field(int index) => find.byType(TextField).at(index);

Future<void> openForm(WidgetTester tester) {
  return tester.pumpWidget(
    const MaterialApp(home: BookParcelScreen(destination: nairobi)),
  );
}

void main() {
  testWidgets('shows a message under each missing detail', (tester) async {
    await openForm(tester);
    await tester.tap(find.text('Book parcel'));
    await tester.pumpAndSettle();

    for (final message in [
      'Choose the size of the parcel.',
      "Say what's inside the parcel.",
      'Enter the value in shillings.',
      "Enter the sender's name.",
      "Enter the sender's phone number.",
      "Enter the receiver's name.",
      "Enter the receiver's phone number.",
      'Take a photo of the parcel before booking.',
    ]) {
      expect(find.text(message), findsOneWidget, reason: message);
    }
  });

  testWidgets('shows the fee once a size is picked', (tester) async {
    await openForm(tester);

    expect(find.text('Fee'), findsNothing);

    await tester.tap(find.text('Medium'));
    await tester.pump();

    expect(find.text('Fee'), findsOneWidget);
    expect(find.text('KSh 350'), findsNWidgets(2));
  });

  testWidgets('tidies phone numbers and values while they are typed', (tester) async {
    await openForm(tester);

    await tester.enterText(field(1), '50000');
    await tester.enterText(field(3), '0722418305');
    await tester.pump();

    expect(find.text('50,000'), findsOneWidget);
    expect(find.text('722 418 305'), findsOneWidget);
  });

  testWidgets('a message goes away once that detail is filled in', (tester) async {
    await openForm(tester);
    await tester.tap(find.text('Book parcel'));
    await tester.pumpAndSettle();

    await tester.enterText(field(2), 'Esther Wambui');
    await tester.pump();

    expect(find.text("Enter the sender's name."), findsNothing);
    expect(find.text("Enter the receiver's name."), findsOneWidget);
  });
}