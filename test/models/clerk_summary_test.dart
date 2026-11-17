import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/clerk_summary.dart';

void main() {
  test('reads the three counts on home and the recent parcels', () {
    final summary = ClerkSummary.fromJson(jsonDecode(
      '{"office":{"office_id":2,"office_name":"Nyeri office","town":"Nyeri"},'
      '"counts":{"booked":3,"on_the_way":2,"arrived":8},"recent":['
      '{"tracking_no":"PKT-282420","status":"booked","is_late":false,"direction":"outgoing",'
      '"other_name":"Paul Kamau","other_town":"Nairobi","last_activity":"2026-11-15T20:24:26+03:00"}]}',
    ) as Map<String, dynamic>);

    expect(summary.town, 'Nyeri');
    expect(summary.booked, 3);
    expect(summary.onTheWay, 2);
    expect(summary.arrived, 8);
    expect(summary.recent.single.trackingNo, 'PKT-282420');
  });
}