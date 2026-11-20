import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/destination.dart';
import 'package:pakiti_app/models/parcel_size.dart';
import 'package:pakiti_app/screens/clerk/book_parcel_screen.dart';
import 'package:pakiti_app/services/api_client.dart';

import '../../support/fakes.dart';

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

Future<void> openForm(WidgetTester tester, {FakeParcelService? service}) {
  final photo = photoFile();

  return tester.pumpWidget(
    MaterialApp(
      home: BookParcelScreen(destination: nairobi, service: service, takePhoto: () async => photo),
    ),
  );
}

// fills in every detail and opens the sheet that asks the clerk to check them
Future<void> fillInAndCheck(WidgetTester tester) async {
  await tester.tap(find.text('Medium'));
  await tester.enterText(field(0), 'Maize flour and beans');
  await tester.enterText(field(1), '1800');
  await tester.enterText(field(2), 'Esther Wambui');
  await tester.enterText(field(3), '722418305');
  await tester.enterText(field(4), 'Kevin Maina');
  await tester.enterText(field(5), '745902117');
  await tester.ensureVisible(find.text('Take a photo'));
  await tester.tap(find.text('Take a photo'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Book parcel'));
  await tester.pumpAndSettle();
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

  testWidgets('a detail the API turns back shows under its field, and typing clears it', (
    tester,
  ) async {
    final service = FakeParcelService(
      bookError: const ApiException(
        'Some details need checking.',
        statusCode: 422,
        fieldErrors: {'receiver_phone': 'Check the phone number.'},
      ),
    );
    await openForm(tester, service: service);
    await fillInAndCheck(tester);

    await tester.tap(find.text('Confirm and book'));
    await tester.pumpAndSettle();

    expect(service.calls, ['book Maize flour and beans for Kevin Maina']);
    expect(find.text('Confirm and book'), findsNothing);
    expect(find.text('Check the phone number.'), findsOneWidget);

    await tester.enterText(field(5), '745902118');
    await tester.pumpAndSettle();

    expect(find.text('Check the phone number.'), findsNothing);
  });

  testWidgets('any other problem stays on the sheet, with Try again', (tester) async {
    final service = FakeParcelService(
      bookError: const ApiException("Can't reach the server. Check your connection and try again."),
    );
    await openForm(tester, service: service);
    await fillInAndCheck(tester);

    await tester.tap(find.text('Confirm and book'));
    await tester.pumpAndSettle();

    expect(
      find.text("Can't reach the server. Check your connection and try again."),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });
}
