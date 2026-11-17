import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/screens/parcel_details.dart';
import 'package:pakiti_app/screens/search.dart';
import 'package:pakiti_app/services/api_client.dart';

import '../support/fakes.dart';

Future<void> openSearch(
  WidgetTester tester,
  FakeParcelService service, {
  String query = '',
}) async {
  await tester.pumpWidget(
    MaterialApp(home: SearchScreen(query: query, service: service)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a phone number shows the parcels sent or received with it', (tester) async {
    await openSearch(tester, FakeParcelService(found: estherParcels()), query: '0722418305');

    expect(find.text('3 parcels'), findsOneWidget);
    expect(find.text('Sent or received by Esther Wambui, 0722 418 305'), findsOneWidget);
    expect(find.text('To Kevin Maina, Nairobi'), findsOneWidget);
    expect(find.text('To John Kariuki, Embu'), findsOneWidget);
    expect(find.text('From Dennis Mwangi, Nakuru'), findsOneWidget);
  });

  testWidgets('says so when a number has no parcels at this office', (tester) async {
    await openSearch(
      tester,
      FakeParcelService(found: nothingFor('+254799000111')),
      query: '0799 000 111',
    );

    expect(find.text('No parcels for 0799 000 111'), findsOneWidget);
    expect(find.text('Only parcels sent from or to your office show up here.'), findsOneWidget);
  });

  testWidgets('a tracking number opens that parcel straight away', (tester) async {
    final service = FakeParcelService(found: trackingNumberFound(), parcel: onTheWay());

    await openSearch(tester, service, query: 'pkt460048');

    expect(find.byType(ParcelDetailsScreen), findsOneWidget);
    expect(find.text('Expected in Nairobi about 8:30 pm'), findsOneWidget);
  });

  testWidgets('shows the message from the API when it cannot read the search', (tester) async {
    const message = 'Type a tracking number like PKT-460048, or a phone number like 0712 345 678.';

    await openSearch(
      tester,
      FakeParcelService(error: const ApiException(message, statusCode: 422)),
      query: 'hello',
    );

    expect(find.text(message), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('searches for what is typed in the box', (tester) async {
    final service = FakeParcelService(found: estherParcels());

    await openSearch(tester, service);
    await tester.enterText(find.byType(TextField), '0722 418 305');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(service.searches, ['0722 418 305']);
    expect(find.text('3 parcels'), findsOneWidget);
  });
}