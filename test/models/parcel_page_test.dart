import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/parcel_page.dart';
import 'package:pakiti_app/models/parcel_status.dart';

ParcelPage read(String json) {
  return ParcelPage.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

void main() {
  test('reads a page that has more parcels after it', () {
    final page = read(
      '{"show":"booked","total":45,"parcels":[{"tracking_no":"PKT-282420","status":"booked",'
      '"is_late":false,"direction":"outgoing","other_name":"Paul Kamau","other_town":"Nairobi",'
      '"last_activity":"2026-11-15T20:24:26+03:00"}],"next_offset":30}',
    );

    expect(page.total, 45);
    expect(page.nextOffset, 30);
    expect(page.parcels.single.trackingNo, 'PKT-282420');
    expect(page.parcels.single.status, ParcelStatus.booked);
  });

  test('the last page has nowhere to go next', () {
    final page = read('{"show":"arrived","total":0,"parcels":[],"next_offset":null}');

    expect(page.total, 0);
    expect(page.parcels, isEmpty);
    expect(page.nextOffset, isNull);
  });
}
