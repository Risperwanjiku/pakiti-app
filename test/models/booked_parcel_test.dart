import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/booked_parcel.dart';
import 'package:pakiti_app/models/parcel_size.dart';

// the reply the API gave for a real booking
const reply =
    '{"ok":true,"data":{"parcel":{"tracking_no":"PKT-460048","status":"booked",'
    '"from":"Nyeri","to":"Nairobi","sender":{"name":"Esther Wambui","phone":"+254722418305",'
    '"email":null},"receiver":{"name":"Kevin Maina","phone":"+254745902117"},'
    '"contents":"Maize flour and beans","declared_value":1800,"size":"medium","fee":350,'
    '"booked_at":"2026-11-12T23:12:37+03:00","booked_by":"Peter Mwangi"}}}';

BookedParcel readReply() {
  final body = jsonDecode(reply) as Map<String, dynamic>;
  final data = body['data'] as Map<String, dynamic>;

  return BookedParcel.fromJson(data['parcel'] as Map<String, dynamic>);
}

void main() {
  test('reads a booking from the API', () {
    final parcel = readReply();

    expect(parcel.trackingNo, 'PKT-460048');
    expect(parcel.from, 'Nyeri');
    expect(parcel.to, 'Nairobi');
    expect(parcel.senderEmail, isNull);
    expect(parcel.receiverPhone, '+254745902117');
    expect(parcel.size, ParcelSize.medium);
    expect(parcel.value, 1800);
    expect(parcel.fee, 350);
    expect(parcel.bookedBy, 'Peter Mwangi');
  });

  test('keeps the exact booking time, whatever time zone the phone is in', () {
    expect(readReply().bookedAt.toUtc(), DateTime.utc(2026, 11, 12, 20, 12, 37));
  });
}