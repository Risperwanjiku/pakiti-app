import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/booked_parcel.dart';
import 'package:pakiti_app/models/parcel_size.dart';
import 'package:pakiti_app/widgets/parcel/parcel_label.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  final parcel = BookedParcel(
    trackingNo: 'PKT-460048',
    from: 'Nyeri',
    to: 'Nairobi',
    senderName: 'Esther Wambui',
    senderPhone: '+254722418305',
    receiverName: 'Kevin Maina',
    receiverPhone: '+254745902117',
    contents: 'Maize flour and beans',
    value: 1800,
    size: ParcelSize.medium,
    fee: 350,
    bookedAt: DateTime(2026, 11, 12, 16, 41),
    bookedBy: 'Peter Mwangi',
  );

  Future<void> showLabel(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ParcelLabel(parcel: parcel)),
        ),
      ),
    );
  }

  testWidgets('shows where it goes, who collects it and the tracking number', (tester) async {
    await showLabel(tester);

    expect(find.text('Nairobi'), findsOneWidget);
    expect(find.text('Kevin Maina'), findsOneWidget);
    expect(find.text('PKT-460048'), findsOneWidget);
    expect(find.text('From Nyeri'), findsOneWidget);
    expect(find.text('12 Nov 2026, 4:41 pm'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('never shows the whole receiver phone number', (tester) async {
    await showLabel(tester);

    expect(find.text('0745 *** 117'), findsOneWidget);
    expect(find.textContaining('902'), findsNothing);
  });
}
