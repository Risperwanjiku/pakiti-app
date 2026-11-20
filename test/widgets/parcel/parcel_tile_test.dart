import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/parcel_card.dart';
import 'package:pakiti_app/models/parcel_status.dart';
import 'package:pakiti_app/widgets/parcel/parcel_tile.dart';

ParcelCard card({
  ParcelStatus status = ParcelStatus.inTransit,
  bool isLate = false,
  bool isOutgoing = true,
  Duration ago = const Duration(hours: 1),
}) {
  return ParcelCard(
    trackingNo: 'PKT-460048',
    status: status,
    isLate: isLate,
    isOutgoing: isOutgoing,
    otherName: isOutgoing ? 'Kevin Maina' : 'Dennis Mwangi',
    otherTown: isOutgoing ? 'Nairobi' : 'Nakuru',
    lastActivity: DateTime.now().subtract(ago),
  );
}

Future<void> showTile(WidgetTester tester, ParcelCard parcel, {VoidCallback? onTap}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ParcelTile(parcel: parcel, onTap: onTap ?? () {})),
    ),
  );
}

void main() {
  testWidgets('says where a parcel going out is headed and who gets it', (tester) async {
    await showTile(tester, card());

    expect(find.text('PKT-460048'), findsOneWidget);
    expect(find.text('On the way'), findsOneWidget);
    expect(find.text('To Kevin Maina, Nairobi'), findsOneWidget);
    expect(find.text('1 hr ago'), findsOneWidget);
  });

  testWidgets('says who sent a parcel coming in', (tester) async {
    await showTile(tester, card(status: ParcelStatus.collected, isOutgoing: false));

    expect(find.text('From Dennis Mwangi, Nakuru'), findsOneWidget);
    expect(find.text('Collected'), findsOneWidget);
  });

  testWidgets('a late parcel says Late instead of its status', (tester) async {
    await showTile(tester, card(isLate: true));

    expect(find.text('Late'), findsOneWidget);
    expect(find.text('On the way'), findsNothing);
  });

  testWidgets('a parcel left here 2 days or more says how long it has waited', (tester) async {
    await showTile(
      tester,
      card(status: ParcelStatus.arrived, isOutgoing: false, ago: const Duration(days: 3, hours: 2)),
    );

    expect(find.text('Waiting 3 days'), findsOneWidget);
    expect(find.text('3 days ago'), findsNothing);
  });

  testWidgets('one that only came in yesterday does not', (tester) async {
    await showTile(
      tester,
      card(status: ParcelStatus.arrived, isOutgoing: false, ago: const Duration(days: 1, hours: 2)),
    );

    expect(find.text('Yesterday'), findsOneWidget);
  });

  testWidgets('nor does one waiting at the other office', (tester) async {
    await showTile(tester, card(status: ParcelStatus.arrived, ago: const Duration(days: 3, hours: 2)));

    expect(find.text('3 days ago'), findsOneWidget);
  });

  testWidgets('a parcel booked here and not loaded for 2 days or more says so too', (tester) async {
    await showTile(tester, card(status: ParcelStatus.booked, ago: const Duration(days: 4, hours: 1)));

    expect(find.text('Waiting 4 days'), findsOneWidget);
  });

  testWidgets('but not one booked at another office and coming here', (tester) async {
    await showTile(
      tester,
      card(status: ParcelStatus.booked, isOutgoing: false, ago: const Duration(days: 4, hours: 1)),
    );

    expect(find.text('4 days ago'), findsOneWidget);
  });

  testWidgets('tapping it opens the parcel', (tester) async {
    var taps = 0;
    await showTile(tester, card(), onTap: () => taps++);

    await tester.tap(find.text('PKT-460048'));

    expect(taps, 1);
  });
}