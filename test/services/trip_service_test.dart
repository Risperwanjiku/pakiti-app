import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pakiti_app/models/load_result.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/trip_service.dart';

import '../support/fakes.dart';

void main() {
  test('a conductor with no trip open gets none back', () async {
    late Uri asked;
    final api = ApiClient.withClient(MockClient((request) async {
      asked = request.url;
      return http.Response('{"ok":true,"data":{"trip":null}}', 200);
    }));

    final trip = await TripService(api: api).fetchCurrent();

    expect(asked.path, endsWith('/conductor/trip'));
    expect(trip, isNull);
  });

  test('starts a trip on the chosen route and vehicle', () async {
    late http.Request sent;
    final api = ApiClient.withClient(MockClient((request) async {
      sent = request;
      final reply = jsonDecode(realLoadReply) as Map<String, dynamic>;
      final trip = (reply['data'] as Map<String, dynamic>)['trip'];

      return http.Response(jsonEncode({'ok': true, 'data': {'trip': trip}}), 201);
    }));

    final trip = await TripService(api: api).start(1, 1);

    expect(sent.method, 'POST');
    expect(sent.url.path, endsWith('/trips'));
    expect(jsonDecode(sent.body), {'route_id': 1, 'vehicle_id': 1});
    expect(trip.id, 3);
  });

  test('scans a parcel onto the trip by its tracking number', () async {
    late http.Request sent;
    final api = ApiClient.withClient(MockClient((request) async {
      sent = request;
      return http.Response(realLoadReply, 200);
    }));

    final result = await TripService(api: api).load(3, 'PKT-282420');

    expect(sent.url.path, endsWith('/trips/3/parcels'));
    expect(jsonDecode(sent.body), {'tracking_no': 'PKT-282420'});
    expect(result.outcome, LoadOutcome.loaded);
  });

  test('only ends a trip with parcels on board when told to', () async {
    final sent = <http.Request>[];
    final api = ApiClient.withClient(MockClient((request) async {
      sent.add(request);
      return http.Response('{"ok":true,"data":{"not_offloaded":0}}', 200);
    }));
    final service = TripService(api: api);

    await service.end(3);
    await service.end(3, anyway: true);

    expect(sent.first.url.path, endsWith('/trips/3/end'));
    expect(jsonDecode(sent.first.body), {'anyway': false});
    expect(jsonDecode(sent.last.body), {'anyway': true});
  });
}