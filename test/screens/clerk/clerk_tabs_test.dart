import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/clerk_summary.dart';
import 'package:pakiti_app/models/parcel_filter.dart';
import 'package:pakiti_app/models/parcel_status.dart';
import 'package:pakiti_app/screens/account/profile_screen.dart';
import 'package:pakiti_app/screens/clerk/clerk_tabs.dart';
import 'package:pakiti_app/screens/clerk/parcels_screen.dart';

import '../../support/fakes.dart';

FakeClerkService nyeri() {
  return FakeClerkService(
    summary: const ClerkSummary(town: 'Nyeri', booked: 1, onTheWay: 0, arrived: 1, recent: []),
    lists: {
      ParcelFilter.all: [
        listed('PKT-512270'),
        listed('PKT-509134', status: ParcelStatus.booked, outgoing: true, name: 'Mary Achieng', town: 'Karatina'),
      ],
      ParcelFilter.arrived: [listed('PKT-512270')],
    },
  );
}

Future<void> openTabs(WidgetTester tester, FakeClerkService service) async {
  await tester.pumpWidget(
    MaterialApp(home: ClerkTabs(user: peter, service: service)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping Arrived on home opens Parcels on Arrived', (tester) async {
    final service = nyeri();
    await openTabs(tester, service);

    await tester.tap(find.text('Arrived'));
    await tester.pumpAndSettle();

    expect(find.byType(ParcelsScreen), findsOneWidget);
    expect(find.text('Waiting for collection at Nyeri office, oldest first'), findsOneWidget);
    expect(service.asked, ['arrived 0']);
  });

  testWidgets('See all opens every parcel', (tester) async {
    await openTabs(tester, nyeri());

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.text('2 parcels'), findsOneWidget);
    expect(find.text('Sent from or to Nyeri office, newest first'), findsOneWidget);
  });

  testWidgets('Scan says it is coming next', (tester) async {
    await openTabs(tester, nyeri());

    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    await tester.pump();

    expect(find.text('This part is coming next.'), findsOneWidget);
    expect(find.text('Habari, Peter'), findsOneWidget);
  });

  testWidgets('Profile shows who is logged in', (tester) async {
    await openTabs(tester, nyeri());

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Clerk, Nyeri office'), findsOneWidget);
  });
}