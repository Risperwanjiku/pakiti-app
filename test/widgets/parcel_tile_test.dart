import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/parcel_card.dart';
import 'package:pakiti_app/models/parcel_status.dart';
import 'package:pakiti_app/widgets/parcel_tile.dart';

ParcelCard card({
  ParcelStatus status = ParcelStatus.inTransit,
  bool isLate = false,
  bool isOutgoing = true,
}) {
  return ParcelCard(
    trackingNo: 'PKT-460048',
    status: status,
    isLate: isLate,
    isOutgoing: isOutgoing,
    otherName: isOutgoing ? 'Kevin Maina' : 'Dennis Mwangi',
    otherTown: isOutgoing ? 'Nairobi' : 'Nakuru',
    lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
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

  testWidgets('tapping it opens the parcel', (tester) async {
    var taps = 0;
    await showTile(tester, card(), onTap: () => taps++);

    await tester.tap(find.text('PKT-460048'));

    expect(taps, 1);
  });
}