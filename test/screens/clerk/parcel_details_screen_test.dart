import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/screens/clerk/handover_screen.dart';
import 'package:pakiti_app/screens/clerk/parcel_details_screen.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/utils/format.dart';

import '../../support/fakes.dart';

// the first try fails as if the network dropped, the next one works
class _FailsOnce extends FakeParcelService {
  _FailsOnce() : super(parcel: onTheWay());

  var _tries = 0;

  @override
  Future<ParcelDetails> fetchDetails(String trackingNo) async {
    _tries++;

    if (_tries == 1) {
      throw const ApiException("Can't reach the server. Check your connection and try again.");
    }

    return super.fetchDetails(trackingNo);
  }
}

Future<void> openParcel(WidgetTester tester, ParcelDetails details) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ParcelDetailsScreen(
        trackingNo: details.booking.trackingNo,
        service: FakeParcelService(parcel: details),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // the fake parcels are from 12 Nov 2026, so the trip shows the day, like
  // "Left on 12 Nov", instead of the time

  testWidgets('shows where the parcel is and which vehicle has it', (tester) async {
    await openParcel(tester, onTheWay());

    expect(find.text('On the way'), findsOneWidget);
    expect(find.text('Expected in Nairobi about ${timeWithDay(DateTime(2026, 11, 12, 20, 30))}'), findsOneWidget);
    expect(find.text('Left on 12 Nov'), findsOneWidget);
    expect(find.text('3 hrs by road'), findsOneWidget);
    expect(find.text('KDG 117T, conductor John Otieno'), findsOneWidget);
  });

  testWidgets('shows phone numbers the way people say them, each with a call button', (tester) async {
    await openParcel(tester, onTheWay());

    expect(find.text('0722 418 305'), findsOneWidget);
    expect(find.text('0745 902 117'), findsOneWidget);
    expect(find.byTooltip('Call Esther Wambui'), findsOneWidget);
    expect(find.byTooltip('Call Kevin Maina'), findsOneWidget);
    expect(find.byTooltip('Call John Otieno, the conductor'), findsOneWidget);
  });

  testWidgets("shows what's inside and what was paid", (tester) async {
    await openParcel(tester, onTheWay());

    expect(find.text('Maize flour and beans'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('KSh 1,800'), findsOneWidget);
    expect(find.text('KSh 350'), findsOneWidget);
    expect(find.text('Photo at booking'), findsOneWidget);
    expect(find.text('12 Nov, 4:41 pm'), findsOneWidget);
  });

  testWidgets('says the custody record was checked', (tester) async {
    await openParcel(tester, onTheWay());

    expect(find.textContaining('Custody record checked.'), findsOneWidget);
    expect(find.text('This record has changed'), findsNothing);
  });

  testWidgets('warns at the top when the custody record was changed', (tester) async {
    await openParcel(tester, onTheWay(recordChecked: false));

    expect(find.text('This record has changed'), findsOneWidget);
    expect(find.textContaining('Custody record checked.'), findsNothing);
  });

  testWidgets('a parcel still at the office has no vehicle yet', (tester) async {
    await openParcel(tester, justBooked());

    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Waiting at Nyeri office'), findsOneWidget);
    expect(find.text('Booked on 12 Nov'), findsOneWidget);
    expect(find.textContaining('conductor'), findsNothing);
  });

  testWidgets('Try again loads the parcel after a failed try', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParcelDetailsScreen(trackingNo: 'PKT-460048', service: _FailsOnce()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Expected in Nairobi about ${timeWithDay(DateTime(2026, 11, 12, 20, 30))}'), findsOneWidget);
  });

  testWidgets('a collected parcel says when it arrived', (tester) async {
    await openParcel(tester, collectedNextDay());

    expect(find.text('Collected'), findsOneWidget);
    expect(find.text('Arrived on 12 Nov'), findsOneWidget);
    expect(find.text('Collected by Kevin Maina'), findsNWidgets(2));
  });

  testWidgets('a parcel waiting here has Hand over, which opens the form', (tester) async {
    await openParcel(tester, waitingHere());

    expect(find.text('Ready for collection at Nairobi office'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Hand over'));
    await tester.pumpAndSettle();

    expect(find.byType(HandoverScreen), findsOneWidget);
    expect(find.text('Ask Kevin for the 6 numbers.'), findsOneWidget);
  });

  testWidgets('a locked parcel says why instead of opening the form', (tester) async {
    await openParcel(tester, waitingHere(triesLeft: 0));

    await tester.tap(find.widgetWithText(FilledButton, 'Hand over'));
    await tester.pumpAndSettle();

    expect(find.text('This parcel is locked'), findsOneWidget);
    expect(find.byType(HandoverScreen), findsNothing);
  });

  testWidgets('only a parcel waiting at this office can be handed over', (tester) async {
    await openParcel(tester, onTheWay());

    expect(find.widgetWithText(FilledButton, 'Hand over'), findsNothing);
  });

  testWidgets('a collected parcel shows the photo taken at the counter', (tester) async {
    await openParcel(tester, handedOverWithPhoto());

    expect(find.text('Photo at booking'), findsOneWidget);
    expect(find.text('Photo at handover'), findsOneWidget);
    expect(find.text('13 Nov, 10:42 am'), findsNWidgets(2));
    expect(find.text('Handed over by Mercy Njoroge, clerk. Photo taken.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Hand over'), findsNothing);
  });

  testWidgets('tells the list it came from when the parcel changes', (tester) async {
    var changed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ParcelDetailsScreen(
          trackingNo: 'PKT-460048',
          service: FakeParcelService(
            parcel: waitingHere(triesLeft: 1),
            newCodeError: const ApiException(
              "The code was wrong 5 times, so PKT-460048 can't be handed over for now. "
              'Ask the admin to unlock it.',
              statusCode: 423,
            ),
          ),
          onChanged: () => changed++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Hand over'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send a new code'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to the parcel'));
    await tester.pumpAndSettle();

    expect(changed, 1);
    expect(find.byType(HandoverScreen), findsNothing);
  });
}