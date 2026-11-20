import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/screens/clerk/scan_screen.dart';

import '../../support/fakes.dart';

Future<void> openScan(
  WidgetTester tester,
  FakeClerkService service, {
  VoidCallback? onSeeAll,
}) async {
  // a phone-tall screen, so the list under the camera is in view
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ScanScreen(
        onSeeAll: onSeeAll ?? () {},
        service: service,
        parcelService: FakeParcelService(),
        camera: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> typeNumber(WidgetTester tester, String number) async {
  await tester.tap(find.text('Type the number instead'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), number);
  await tester.tap(find.text('Find parcel'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists what was marked as arrived today, newest first', (tester) async {
    var seeAll = false;
    await openScan(
      tester,
      FakeClerkService(arrivals: arrivedToday()),
      onSeeAll: () => seeAll = true,
    );

    expect(find.text('Fit the QR code inside the frame'), findsOneWidget);
    expect(find.text('From Nakuru on KCY 482B'), findsOneWidget);
    expect(find.text('11:40 am'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('PKT-458871')).dy,
      lessThan(tester.getTopLeft(find.text('PKT-457203')).dy),
    );

    await tester.tap(find.text('See all'));

    expect(seeAll, isTrue);
  });

  testWidgets('with nothing in yet today, it says so', (tester) async {
    await openScan(tester, FakeClerkService());

    expect(find.text('Nothing marked as arrived yet today.'), findsOneWidget);
  });

  testWidgets('a parcel coming in is checked against its photo, then marked', (tester) async {
    final service = FakeClerkService(checks: {'PKT-460048': comingIn()}, arrivals: arrivedToday());
    await openScan(tester, service);

    await typeNumber(tester, '460048');

    expect(find.text('On the way'), findsOneWidget);
    expect(find.text('Left Nyeri at 2:15 pm'), findsOneWidget);
    expect(find.text('From Nyeri on KDG 117T'), findsOneWidget);
    expect(find.text('Medium. Check it matches the photo.'), findsOneWidget);
    expect(find.text('Kevin Maina'), findsOneWidget);
    expect(find.text('0745 902 117'), findsOneWidget);

    await tester.tap(find.text('Mark as arrived'));
    await tester.pumpAndSettle();

    expect(service.calls, contains('arrive PKT-460048'));
    expect(find.text('PKT-460048 is in'), findsOneWidget);
    expect(find.text('Ready for Kevin Maina to collect.'), findsOneWidget);

    // the card takes the hint's place, just above Type the number instead
    expect(find.text('Fit the QR code inside the frame'), findsNothing);
    expect(
      tester.getBottomLeft(find.text('Ready for Kevin Maina to collect.')).dy,
      lessThan(tester.getTopLeft(find.text('Type the number instead')).dy),
    );

    expect(
      tester.getTopLeft(find.text('PKT-460048')).dy,
      lessThan(tester.getTopLeft(find.text('PKT-458871')).dy),
    );
  });

  testWidgets('Cancel leaves the parcel as it was', (tester) async {
    final service = FakeClerkService(checks: {'PKT-460048': comingIn()});
    await openScan(tester, service);

    await typeNumber(tester, '460048');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Mark as arrived'), findsNothing);
    expect(service.calls, isNot(contains('arrive PKT-460048')));
  });

  testWidgets('the card goes once the next label is scanned', (tester) async {
    await openScan(
      tester,
      FakeClerkService(checks: {'PKT-460048': comingIn(), 'PKT-461144': forNakuru()}),
    );

    await typeNumber(tester, '460048');
    await tester.tap(find.text('Mark as arrived'));
    await tester.pumpAndSettle();
    await typeNumber(tester, '461144');

    expect(find.text('PKT-460048 is in'), findsNothing);
  });

  testWidgets('a parcel for another office goes back to the conductor', (tester) async {
    await openScan(tester, FakeClerkService(checks: {'PKT-461144': forNakuru()}));

    await typeNumber(tester, '461144');

    expect(find.text('Not for this office'), findsOneWidget);
    expect(find.text('This parcel goes to'), findsOneWidget);
    expect(find.text('Nakuru'), findsOneWidget);
    expect(find.text("You're at"), findsOneWidget);
    expect(find.text('Nairobi'), findsOneWidget);
    expect(
      find.textContaining('back to the conductor so it carries on to Nakuru.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Scan the next parcel'));
    await tester.pumpAndSettle();

    expect(find.text('Not for this office'), findsNothing);
  });

  testWidgets('a parcel already marked as arrived says so', (tester) async {
    await openScan(
      tester,
      FakeClerkService(
        checks: {'PKT-460048': comingIn(verdict: 'arrived', status: 'arrived')},
      ),
    );

    await typeNumber(tester, '460048');

    expect(find.text('PKT-460048 was already marked as arrived.'), findsOneWidget);
    expect(find.text('Mark as arrived'), findsNothing);
  });

  testWidgets('a number that is not a parcel says so', (tester) async {
    await openScan(tester, FakeClerkService());

    await typeNumber(tester, '000001');

    expect(find.text('No parcel with that tracking number.'), findsOneWidget);
  });
}
