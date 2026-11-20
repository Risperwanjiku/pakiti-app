import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/destination.dart';
import 'package:pakiti_app/models/parcel_size.dart';

Destination read(String json) {
  return Destination.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

void main() {
  test('reads a town and its fees from the API', () {
    final destination = read(
      '{"route_id":1,"town":"Nairobi","county":"Nairobi","minutes":180,'
      '"fees":{"small":200,"medium":350,"large":500}}',
    );

    expect(destination.routeId, 1);
    expect(destination.town, 'Nairobi');
    expect(destination.county, 'Nairobi');
    expect(destination.travelMinutes, 180);
    expect(destination.fees, {
      ParcelSize.small: 200,
      ParcelSize.medium: 350,
      ParcelSize.large: 500,
    });
  });

  test('accepts fees with cents', () {
    final destination = read(
      '{"route_id":11,"town":"Embu","county":"Embu","minutes":120,'
      '"fees":{"small":200.5,"medium":300,"large":450}}',
    );

    expect(destination.fees[ParcelSize.small], 200.5);
  });
}