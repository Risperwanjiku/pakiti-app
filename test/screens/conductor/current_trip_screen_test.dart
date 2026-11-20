import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/screens/conductor/conductor_tabs.dart';

import '../../support/fakes.dart';

Future<void> openTrip(WidgetTester tester, FakeTripService service) async {
  await tester.pumpWidget(
    MaterialApp(home: ConductorTabs(user: john, service: service, camera: false)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('on the way, it says when the vehicle should get there', (tester) async {
    await openTrip(tester, FakeTripService(current: onTheWayTrip()));

    expect(find.text('On the way'), findsOneWidget);
    expect(find.text('Expected in Nairobi about 5:15 pm'), findsOneWidget);
    expect(find.text('Left at 2:15 pm'), findsOneWidget);
    expect(find.text('About 3 hrs by road'), findsOneWidget);
    expect(find.text('KDG 117T, 3 parcels on board'), findsOneWidget);
    expect(find.text('PKT-461302'), findsOneWidget);
  });

  testWidgets('at the other end, it shows what has been scanned off', (tester) async {
    await openTrip(tester, FakeTripService(current: inNairobiTrip()));

    expect(find.text('In Nairobi'), findsOneWidget);
    expect(find.text('2 of 3 parcels scanned off'), findsOneWidget);
    expect(find.text('Arrived at 5:10 pm'), findsOneWidget);
    expect(find.text('KDG 117T, at Nairobi office'), findsOneWidget);
    expect(find.text('1 still on board'), findsOneWidget);
    expect(find.text('Still on board'), findsOneWidget);
    expect(find.text('Off at 5:12 pm'), findsOneWidget);
  });

  testWidgets('End trip with a parcel still on board asks first', (tester) async {
    final service = FakeTripService(current: inNairobiTrip());
    await openTrip(tester, service);

    await tester.tap(find.text('End trip'));
    await tester.pumpAndSettle();

    expect(find.text('1 parcel is still on the vehicle'), findsOneWidget);
    expect(find.text('School books, small'), findsOneWidget);

    await tester.tap(find.text("I'll hand it over"));
    await tester.pumpAndSettle();

    expect(find.text('1 parcel is still on the vehicle'), findsNothing);
    expect(service.calls, isNot(contains('end 7')));
    expect(service.calls, isNot(contains('end 7 anyway')));
  });

  testWidgets('End the trip anyway ends it and goes back to the start', (tester) async {
    final service = FakeTripService(current: inNairobiTrip(), choices: nyeriChoices());
    await openTrip(tester, service);

    await tester.tap(find.text('End trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End the trip anyway'));
    await tester.pumpAndSettle();

    expect(service.calls, contains('end 7 anyway'));
    expect(find.text('Trip ended.'), findsOneWidget);
    expect(find.text('Start loading'), findsOneWidget);
  });

  testWidgets('with everything scanned off, End trip just ends it', (tester) async {
    final service = FakeTripService(current: inNairobiTrip(allOff: true), choices: nyeriChoices());
    await openTrip(tester, service);

    expect(find.text('All scanned off'), findsOneWidget);

    await tester.tap(find.text('End trip'));
    await tester.pumpAndSettle();

    expect(service.calls, contains('end 7'));
    expect(find.text('Start loading'), findsOneWidget);
  });
}