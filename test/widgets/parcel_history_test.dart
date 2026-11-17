import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/widgets/parcel_history.dart';

import '../support/fakes.dart';

Future<void> showHistory(WidgetTester tester, ParcelDetails details) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: ParcelHistory(details: details)),
      ),
    ),
  );
}

void main() {
  testWidgets('lists each hand-off with its time and who did it', (tester) async {
    await showHistory(tester, onTheWay());

    expect(find.text('12 Nov 2026'), findsOneWidget);
    expect(find.text('Booked at Nyeri office'), findsOneWidget);
    expect(find.text('4:41 pm'), findsOneWidget);
    expect(find.text('Peter Mwangi, clerk. Photo taken.'), findsOneWidget);
    expect(find.text('Loaded onto KDG 117T'), findsOneWidget);
    expect(find.text('John Otieno, conductor'), findsOneWidget);
    expect(find.text('Left Nyeri'), findsOneWidget);
    expect(find.text('On KDG 117T with John Otieno'), findsOneWidget);
  });

  testWidgets('then the steps still to come', (tester) async {
    await showHistory(tester, onTheWay());

    expect(find.text('Arrives at Nairobi office'), findsOneWidget);
    expect(find.text('Expected about 8:30 pm'), findsOneWidget);
    expect(find.text('Collected by Kevin Maina'), findsOneWidget);
  });

  testWidgets('a parcel still at the office has every step ahead of it', (tester) async {
    await showHistory(tester, justBooked());

    expect(find.text('Loaded onto a vehicle'), findsOneWidget);
    expect(find.text('Leaves Nyeri'), findsOneWidget);
    expect(find.text('Arrives at Nairobi office'), findsOneWidget);
    expect(find.text('About 3 hrs on the road'), findsOneWidget);
  });

  testWidgets('a hand-off on a later day shows its date', (tester) async {
    await showHistory(tester, collectedNextDay());

    expect(find.text('8:20 pm'), findsOneWidget);
    expect(find.text('13 Nov, 9:05 am'), findsOneWidget);
    expect(find.text('Handed over by Samuel Kiprop, clerk'), findsOneWidget);
    expect(find.text('Arrives at Nairobi office'), findsNothing);
  });
}