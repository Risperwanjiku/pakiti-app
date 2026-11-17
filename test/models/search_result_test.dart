import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/parcel_status.dart';
import 'package:pakiti_app/models/search_result.dart';

SearchResult read(String json) {
  return SearchResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

void main() {
  test('reads a search by phone number, with the name used on the parcels', () {
    final result = read(
      '{"type":"phone","phone":"+254722418305","name":"Esther Wambui","parcels":['
      '{"tracking_no":"PKT-460048","status":"booked","is_late":false,"direction":"outgoing",'
      '"other_name":"Kevin Maina","other_town":"Nairobi","last_activity":"2026-11-12T23:12:37+03:00"}]}',
    );

    expect(result.byPhone, isTrue);
    expect(result.searchedFor, '+254722418305');
    expect(result.name, 'Esther Wambui');

    final parcel = result.parcels.single;

    expect(parcel.trackingNo, 'PKT-460048');
    expect(parcel.status, ParcelStatus.booked);
    expect(parcel.isLate, isFalse);
    expect(parcel.isOutgoing, isTrue);
    expect(parcel.otherName, 'Kevin Maina');
    expect(parcel.otherTown, 'Nairobi');
  });

  test('reads a search by tracking number that found nothing', () {
    final result = read('{"type":"tracking_no","tracking_no":"PKT-123456","parcels":[]}');

    expect(result.byPhone, isFalse);
    expect(result.searchedFor, 'PKT-123456');
    expect(result.name, isNull);
    expect(result.parcels, isEmpty);
  });
}