import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/screens/conductor_tabs.dart';

import '../support/fakes.dart';

// through the conductor's tabs, which keep the trip the loading screen shows
Future<void> openLoading(WidgetTester tester, FakeTripService service) async {
  await tester.pumpWidget(
    MaterialApp(home: ConductorTabs(user: john, service: service, camera: false)),
  );
  await tester.pumpAndSettle();
}

Future<void> typeNumber(WidgetTester tester, String number) async {
  await tester.tap(find.text('Type the number instead'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), number);
  await tester.tap(find.text('Load parcel'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows what is on board and what is still at the office', (tester) async {
    await openLoading(
      tester,
      FakeTripService(current: loadingTrip(onBoard: ['PKT-461302'], waiting: ['PKT-461388'])),
    );

    expect(find.text('Loading for Nairobi'), findsOneWidget);
    expect(find.text('PKT-461302'), findsOneWidget);
    expect(find.text('For Brian Ochieng'), findsOneWidget);
    expect(find.text('Just now'), findsOneWidget);
    expect(find.text('Still at Nyeri'), findsOneWidget);
    expect(find.text('PKT-461388'), findsOneWidget);
    expect(find.text('Depart with 1 parcel'), findsOneWidget);
  });

  testWidgets('a parcel goes on and moves up to On board', (tester) async {
    final service = FakeTripService(
      current: loadingTrip(waiting: ['PKT-461302', 'PKT-461388']),
      scans: {
        'PKT-461302': scanResult(
          'loaded',
          'PKT-461302',
          loadingTrip(onBoard: ['PKT-461302'], waiting: ['PKT-461388']),
          status: 'loaded',
          vehicle: 'KDG 117T',
        ),
      },
    );
    await openLoading(tester, service);

    expect(find.text('Nothing on board yet. Scan a label to load the parcel.'), findsOneWidget);

    await typeNumber(tester, '461302');

    expect(service.calls, contains('load PKT-461302'));
    expect(find.text('Nothing on board yet. Scan a label to load the parcel.'), findsNothing);
    expect(find.text('Just now'), findsOneWidget);
    expect(find.text('Depart with 1 parcel'), findsOneWidget);
  });

  testWidgets('a parcel for another town is kept off, with the reason', (tester) async {
    await openLoading(
      tester,
      FakeTripService(
        current: loadingTrip(),
        scans: {'PKT-461144': scanResult('wrong_route', 'PKT-461144', loadingTrip(), to: 'Nakuru')},
      ),
    );

    await typeNumber(tester, '461144');

    expect(find.text('Keep this one off'), findsOneWidget);
    expect(find.text('This parcel goes to'), findsOneWidget);
    expect(find.text('Nakuru'), findsOneWidget);
    expect(find.text('This vehicle goes to'), findsOneWidget);
    expect(
      find.textContaining('back to the clerk at Nyeri so it goes on a Nakuru vehicle.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Carry on scanning'));
    await tester.pumpAndSettle();

    expect(find.text('Keep this one off'), findsNothing);
  });

  testWidgets('a parcel booked at another office goes to the clerk here', (tester) async {
    await openLoading(
      tester,
      FakeTripService(
        current: loadingTrip(),
        scans: {
          'PKT-459730': scanResult('wrong_route', 'PKT-459730', loadingTrip(), from: 'Embu', to: 'Nyeri'),
        },
      ),
    );

    await typeNumber(tester, '459730');

    expect(find.text('This parcel is from'), findsOneWidget);
    expect(find.text('Embu'), findsOneWidget);
    expect(find.text('This vehicle is at'), findsOneWidget);
    expect(find.textContaining('to the clerk at Nyeri to sort out.'), findsOneWidget);
    expect(find.textContaining('back to the clerk'), findsNothing);
  });

  testWidgets('a number that is not a parcel says so', (tester) async {
    await openLoading(tester, FakeTripService(current: loadingTrip()));

    await typeNumber(tester, '000001');

    expect(find.text('No parcel with that tracking number.'), findsOneWidget);
  });

  testWidgets('a typed number needs all six numbers', (tester) async {
    final service = FakeTripService(current: loadingTrip());
    await openLoading(tester, service);

    await typeNumber(tester, '4613');

    expect(find.text('Type the 6 numbers after PKT-'), findsOneWidget);
    expect(service.calls, isNot(contains('load PKT-4613')));
  });

  testWidgets('Back drops a trip with nothing on it', (tester) async {
    final service = FakeTripService(current: loadingTrip(), choices: nyeriChoices());
    await openLoading(tester, service);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(service.calls, contains('cancel 7'));
    expect(find.text('Start loading'), findsOneWidget);
  });

  testWidgets('with nothing loaded or waiting, it just says so', (tester) async {
    await openLoading(tester, FakeTripService(current: loadingTrip(waiting: [])));

    expect(find.text('Nothing is waiting at Nyeri for Nairobi.'), findsOneWidget);
    expect(find.text('0 parcels'), findsNothing);
  });

  testWidgets('Depart with nothing on board says to scan a parcel first', (tester) async {
    final service = FakeTripService(current: loadingTrip());
    await openLoading(tester, service);

    await tester.tap(find.text('Depart'));
    await tester.pumpAndSettle();

    expect(find.text('Scan at least one parcel onto the vehicle before you depart.'), findsOneWidget);
    expect(service.calls, isNot(contains('depart 7')));
  });

  testWidgets('once a parcel is on, there is no going back, only Depart', (tester) async {
    await openLoading(tester, FakeTripService(current: loadingTrip(onBoard: ['PKT-461302'])));

    expect(find.byTooltip('Back'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Depart sends the trip on its way', (tester) async {
    final service = FakeTripService(
      current: loadingTrip(onBoard: ['PKT-460048', 'PKT-461215', 'PKT-461302']),
      departed: onTheWayTrip(),
    );
    await openLoading(tester, service);

    await tester.tap(find.text('Depart with 3 parcels'));
    await tester.pumpAndSettle();

    expect(service.calls, contains('depart 7'));
    expect(find.text('Expected in Nairobi about 5:15 pm'), findsOneWidget);
  });
}