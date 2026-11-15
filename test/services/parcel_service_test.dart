import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/services/parcel_service.dart';

void main() {
  test('request ids are version 4 UUIDs, the format the API expects', () {
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    for (var i = 0; i < 100; i++) {
      expect(ParcelService.newRequestId(), matches(uuid));
    }
  });

  test('every booking gets its own request id', () {
    final ids = {for (var i = 0; i < 1000; i++) ParcelService.newRequestId()};

    expect(ids, hasLength(1000));
  });
}