import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/trip.dart';
import 'package:pakiti_app/models/trip_choices.dart';
import 'package:pakiti_app/screens/conductor/start_trip_screen.dart';

import '../../support/fakes.dart';

Future<void> openStart(
  WidgetTester tester,
  FakeTripService service, {
  ValueChanged<Trip>? onStarted,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: StartTripScreen(user: john, service: service, onStarted: onStarted ?? (_) {}),
    ),
  );
  await tester.pumpAndSettle();
}

FakeTripService nyeri({TripChoices? choices}) {
  return FakeTripService(choices: choices ?? nyeriChoices(), started: loadingTrip());
}

void main() {
  testWidgets('starts on the way back and the vehicle from the last trip', (tester) async {
    await openStart(tester, nyeri());

    expect(find.text('Habari, John'), findsOneWidget);
    expect(find.text('Nyeri to Nairobi'), findsOneWidget);
    expect(find.text('About 3 hrs by road'), findsOneWidget);
    expect(find.text('KDG 117T'), findsOneWidget);
    expect(find.text('The one from your last trip'), findsOneWidget);
    expect(find.text('2 parcels are waiting at Nyeri for Nairobi.'), findsOneWidget);
  });

  testWidgets('another route can be chosen, under the town it leaves from', (tester) async {
    await openStart(tester, nyeri());

    await tester.tap(find.text('Change').first);
    await tester.pumpAndSettle();

    expect(find.text('Choose the route'), findsOneWidget);
    expect(find.text('From Nairobi'), findsOneWidget);
    expect(find.text('From Nyeri'), findsOneWidget);

    await tester.tap(find.text('To Nakuru'));
    await tester.pumpAndSettle();

    expect(find.text('Choose the route'), findsNothing);
    expect(find.text('Nyeri to Nakuru'), findsOneWidget);
    expect(find.text('1 parcel is waiting at Nyeri for Nakuru.'), findsOneWidget);
  });

  testWidgets('routes with parcels waiting come first', (tester) async {
    await openStart(tester, nyeri());

    await tester.tap(find.text('Change').first);
    await tester.pumpAndSettle();

    // Nairobi is first in the list the API gives, but nothing is waiting there
    expect(
      tester.getTopLeft(find.text('From Nyeri')).dy,
      lessThan(tester.getTopLeft(find.text('From Nairobi')).dy),
    );
    expect(find.text('2 parcels waiting'), findsOneWidget);
  });

  testWidgets('a vehicle out on another trip cannot be chosen', (tester) async {
    await openStart(tester, nyeri());

    await tester.tap(find.text('Change').last);
    await tester.pumpAndSettle();

    expect(find.text('On another trip'), findsOneWidget);

    await tester.tap(find.text('KDA 482M'));
    await tester.pumpAndSettle();

    expect(find.text('Choose the vehicle'), findsOneWidget);

    await tester.tap(find.text('KCX 903P'));
    await tester.pumpAndSettle();

    expect(find.text('Choose the vehicle'), findsNothing);
    expect(find.text('KCX 903P'), findsOneWidget);
    expect(find.text('Fleet number 078'), findsOneWidget);
  });

  testWidgets('Start loading starts the trip on what was chosen', (tester) async {
    final service = nyeri();
    Trip? started;
    await openStart(tester, service, onStarted: (trip) => started = trip);

    await tester.tap(find.text('Start loading'));
    // one pump, since the button keeps spinning until the tabs swap in the loading screen
    await tester.pump();

    expect(service.calls, contains('start 1 1'));
    expect(started!.status, TripStatus.loading);
  });

  testWidgets('before a first trip, Start loading asks for the route and then the vehicle', (
    tester,
  ) async {
    final service = nyeri(choices: nyeriChoices(suggestedRouteId: null, suggestedVehicleId: null));
    await openStart(tester, service);

    expect(find.text('Not chosen yet'), findsNWidgets(2));

    await tester.tap(find.text('Start loading'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('To Nairobi'));
    await tester.pumpAndSettle();

    expect(find.text('Choose the vehicle'), findsOneWidget);

    await tester.tap(find.text('KDG 117T'));
    await tester.pumpAndSettle();

    expect(find.text('Nyeri to Nairobi'), findsOneWidget);
    expect(find.text('KDG 117T'), findsOneWidget);
    // the trip only starts on the next tap, once the conductor has seen both
    expect(service.calls, isNot(contains('start 1 1')));
  });
}
