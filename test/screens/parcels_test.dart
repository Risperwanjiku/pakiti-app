import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/parcel_filter.dart';
import 'package:pakiti_app/models/parcel_page.dart';
import 'package:pakiti_app/models/parcel_status.dart';
import 'package:pakiti_app/screens/parcels.dart';
import 'package:pakiti_app/services/api_client.dart';

import '../support/fakes.dart';

Future<void> openParcels(
  WidgetTester tester,
  FakeClerkService service, {
  ParcelFilter filter = ParcelFilter.all,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ParcelsScreen(user: peter, filter: filter, service: service),
    ),
  );
  await tester.pumpAndSettle();
}

// the filter, not a status tag with the same word on one of the parcels
Finder filterNamed(String label) {
  return find.descendant(
    of: find.byType(SingleChildScrollView),
    matching: find.text(label),
  );
}

// the first try fails as if the network dropped, the next one works
class _FailsOnce extends FakeClerkService {
  _FailsOnce() : super(lists: {ParcelFilter.all: [listed('PKT-512270')]});

  var _tries = 0;

  @override
  Future<ParcelPage> fetchParcels(ParcelFilter filter, {int offset = 0}) async {
    _tries++;

    if (_tries == 1) {
      throw const ApiException("Can't reach the server. Check your connection and try again.");
    }

    return super.fetchParcels(filter, offset: offset);
  }
}

void main() {
  testWidgets('shows the parcels waiting for collection and how many there are', (tester) async {
    await openParcels(
      tester,
      FakeClerkService(lists: {
        ParcelFilter.arrived: [
          listed('PKT-512270'),
          listed('PKT-498815', name: 'Faith Njeri', town: 'Meru', ago: const Duration(hours: 3)),
        ],
      }),
      filter: ParcelFilter.arrived,
    );

    expect(find.text('2 parcels'), findsOneWidget);
    expect(find.text('Waiting for collection at Nyeri office, oldest first'), findsOneWidget);
    expect(find.text('From Dennis Mwangi, Nakuru'), findsOneWidget);
    expect(find.text('From Faith Njeri, Meru'), findsOneWidget);
  });

  testWidgets('choosing a filter loads its own list', (tester) async {
    final service = FakeClerkService(lists: {
      ParcelFilter.all: [
        listed('PKT-460048', status: ParcelStatus.inTransit, outgoing: true, name: 'Kevin Maina', town: 'Nairobi'),
      ],
      ParcelFilter.booked: [
        listed('PKT-509134', status: ParcelStatus.booked, outgoing: true, name: 'Mary Achieng', town: 'Karatina'),
      ],
    });

    await openParcels(tester, service);
    await tester.tap(filterNamed('Booked'));
    await tester.pumpAndSettle();

    expect(service.asked, ['all 0', 'booked 0']);
    expect(find.text('Waiting to be loaded at Nyeri office, oldest first'), findsOneWidget);
    expect(find.text('To Mary Achieng, Karatina'), findsOneWidget);
    expect(find.text('To Kevin Maina, Nairobi'), findsNothing);
  });

  testWidgets('says when nothing is waiting to be loaded, with a way to book one', (tester) async {
    await openParcels(tester, FakeClerkService(), filter: ParcelFilter.booked);

    expect(find.text('Nothing waiting to be loaded'), findsOneWidget);
    expect(find.text('Book a parcel'), findsOneWidget);
  });

  testWidgets('loads the next 30 when the list is scrolled to the end', (tester) async {
    final service = FakeClerkService(lists: {
      ParcelFilter.all: [
        for (var i = 0; i < 35; i++) listed('PKT-${500100 + i}', ago: Duration(minutes: i + 1)),
      ],
    });

    await openParcels(tester, service);

    expect(find.text('35 parcels'), findsOneWidget);
    expect(service.asked, ['all 0']);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(service.asked, ['all 0', 'all 30']);
    expect(find.text('PKT-500134'), findsOneWidget);
  });

  testWidgets('Try again loads the list after a failed try', (tester) async {
    await openParcels(tester, _FailsOnce());

    expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('1 parcel'), findsOneWidget);
    expect(find.text('From Dennis Mwangi, Nakuru'), findsOneWidget);
  });
}