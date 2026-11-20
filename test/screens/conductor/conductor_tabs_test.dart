import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/screens/account/profile_screen.dart';
import 'package:pakiti_app/screens/conductor/conductor_tabs.dart';
import 'package:pakiti_app/services/api_client.dart';

import '../../support/fakes.dart';

Future<void> openTabs(WidgetTester tester, FakeTripService service) async {
  await tester.pumpWidget(
    MaterialApp(home: ConductorTabs(user: john, service: service, camera: false)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with no trip open, the Trip tab starts one', (tester) async {
    await openTabs(tester, FakeTripService(choices: nyeriChoices()));

    expect(find.text('Habari, John'), findsOneWidget);
    expect(find.text('Start loading'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a trip that is still loading opens on the loading screen', (tester) async {
    await openTabs(tester, FakeTripService(current: loadingTrip()));

    expect(find.text('Loading for Nairobi'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Start loading opens the loading screen', (tester) async {
    await openTabs(
      tester,
      FakeTripService(choices: nyeriChoices(), started: loadingTrip()),
    );

    await tester.tap(find.text('Start loading'));
    await tester.pumpAndSettle();

    expect(find.text('Loading for Nairobi'), findsOneWidget);
  });

  testWidgets('Profile shows the conductor', (tester) async {
    await openTabs(tester, FakeTripService(choices: nyeriChoices()));

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Conductor'), findsOneWidget);
  });

  testWidgets('when the trip cannot be checked, Try again asks again', (tester) async {
    final service = FakeTripService(
      error: const ApiException("Can't reach the server. Check your connection and try again."),
    );
    await openTabs(tester, service);

    expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(service.calls, ['current', 'current']);
  });
}