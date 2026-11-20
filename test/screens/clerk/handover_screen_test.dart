import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/screens/clerk/handover_screen.dart';
import 'package:pakiti_app/services/api_client.dart';

import '../../support/fakes.dart';

// Opens the Hand over screen from a plain page, the way the parcel's page does,
// and gives back what the screen closed with.
class OpenedHandover {
  bool? result;
}

Future<OpenedHandover> openHandover(
  WidgetTester tester,
  FakeParcelService service, {
  ParcelDetails? details,
}) async {
  final opened = OpenedHandover();
  final photo = photoFile();

  // a phone-tall screen, so the photo button is in view without scrolling
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            opened.result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => HandoverScreen(
                  details: details ?? waitingHere(),
                  photo: pixel,
                  service: service,
                  takePhoto: () async => photo,
                ),
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  return opened;
}

Future<void> fillIn(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.tap(find.text('Take a photo'));
  await tester.pumpAndSettle();
}

Future<void> tapHandOver(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Hand over'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows who should collect it and what to check first', (tester) async {
    await openHandover(tester, FakeParcelService());

    expect(find.text('Hand over PKT-460048'), findsOneWidget);
    expect(find.text('Kevin Maina'), findsOneWidget);
    expect(find.text('0745 902 117'), findsOneWidget);
    expect(find.text('Check that their ID shows this name.'), findsOneWidget);
    expect(find.text('Ask Kevin for the 6 numbers.'), findsOneWidget);
    expect(find.text('Maize flour and beans'), findsOneWidget);
    expect(find.text('Medium. Let Kevin check it matches this photo.'), findsOneWidget);
    expect(find.text('Proof of its condition at handover'), findsOneWidget);
  });

  testWidgets('asks for the code and a photo before sending anything', (tester) async {
    final service = FakeParcelService();
    await openHandover(tester, service);

    await tapHandOver(tester);

    expect(find.text('Type the 6 numbers of the code.'), findsOneWidget);
    expect(find.text('Take a photo of the parcel before you hand it over.'), findsOneWidget);
    expect(service.calls, isEmpty);
  });

  testWidgets('a wrong code says how many tries are left and keeps the photo', (tester) async {
    final service = FakeParcelService(
      handOverError: const ApiException(
        'Some details need checking.',
        statusCode: 422,
        fieldErrors: {'code': 'That code is wrong. 4 tries left.'},
      ),
    );
    await openHandover(tester, service);

    await fillIn(tester, '481270');
    await tapHandOver(tester);

    expect(service.calls, ['hand over PKT-460048 481270']);
    expect(find.text('That code is wrong. 4 tries left.'), findsOneWidget);
    expect(find.text('Photo added'), findsOneWidget);

    // typing again clears the message
    await tester.enterText(find.byType(TextField), '48120');
    // the message fades out rather than going at once
    await tester.pumpAndSettle();

    expect(find.text('That code is wrong. 4 tries left.'), findsNothing);
  });

  testWidgets('the fifth wrong code locks the parcel and goes back to it', (tester) async {
    final opened = await openHandover(
      tester,
      FakeParcelService(
        handOverError: const ApiException(
          "The code was wrong 5 times, so PKT-460048 can't be handed over for now. "
          'Ask the admin to unlock it.',
          statusCode: 423,
        ),
      ),
    );

    await fillIn(tester, '481270');
    await tapHandOver(tester);

    expect(find.text('This parcel is locked'), findsOneWidget);
    expect(find.textContaining('Ask the admin to unlock it.'), findsOneWidget);

    await tester.tap(find.text('Back to the parcel'));
    await tester.pumpAndSettle();

    expect(opened.result, isTrue);
    expect(find.byType(HandoverScreen), findsNothing);
  });

  testWidgets('a new code clears the box and says where it went', (tester) async {
    final service = FakeParcelService();
    await openHandover(tester, service);

    await tester.enterText(find.byType(TextField), '111111');
    await tester.tap(find.text('Send a new code'));
    await tester.pumpAndSettle();

    expect(service.calls, ['new code PKT-460048']);
    expect(find.text("New code sent to 0745 902 117. The old one won't work now."), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('a code sent a moment ago is not sent again', (tester) async {
    await openHandover(
      tester,
      FakeParcelService(
        newCodeError: const ApiException(
          'A code was sent less than a minute ago. Give it a moment to arrive.',
          statusCode: 429,
        ),
      ),
    );

    await tester.tap(find.text('Send a new code'));
    await tester.pumpAndSettle();

    expect(
      find.text('A code was sent less than a minute ago. Give it a moment to arrive.'),
      findsOneWidget,
    );
    expect(find.text('Ask Kevin for the 6 numbers.'), findsOneWidget);
  });

  testWidgets('a parcel that came in before codes were sent needs one first', (tester) async {
    final service = FakeParcelService();
    await openHandover(tester, service, details: waitingHere(codeSent: false));

    expect(find.text('No code has been sent to Kevin yet.'), findsOneWidget);

    await fillIn(tester, '481207');
    await tapHandOver(tester);

    expect(find.text('Send Kevin a code first.'), findsOneWidget);
    expect(service.calls, isEmpty);

    await tester.tap(find.text('Send a code'));
    await tester.pumpAndSettle();

    expect(find.text('Code sent to 0745 902 117.'), findsOneWidget);
    expect(find.text('Send a new code'), findsOneWidget);
  });

  testWidgets('once handed over, it shows the record and closes with true', (tester) async {
    final service = FakeParcelService();
    final opened = await openHandover(tester, service);

    await fillIn(tester, '481207');
    await tapHandOver(tester);

    expect(service.calls, ['hand over PKT-460048 481207']);
    expect(opened.result, isTrue);
    expect(find.text('Parcel handed over'), findsOneWidget);
    expect(find.text('Kevin Maina collected PKT-460048 at 10:42 am.'), findsOneWidget);
    expect(find.text('Photo at handover'), findsOneWidget);
    expect(
      find.text(
        "Handed over by Mercy Njoroge at Nairobi office. It's now in the parcel's history.",
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Parcel handed over'), findsNothing);
  });
}
