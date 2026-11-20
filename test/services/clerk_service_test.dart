import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pakiti_app/models/arrival.dart';
import 'package:pakiti_app/models/parcel_filter.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/clerk_service.dart';

void main() {
  test('asks for the chosen filter, starting where the page starts', () async {
    late Uri asked;
    final api = ApiClient.withClient(
      MockClient((request) async {
        asked = request.url;
        return http.Response(
          '{"ok":true,"data":{"show":"on_the_way","total":31,"parcels":[],"next_offset":null}}',
          200,
        );
      }),
    );

    final page = await ClerkService(api: api).fetchParcels(ParcelFilter.onTheWay, offset: 30);

    expect(asked.path, endsWith('/clerk/parcels'));
    expect(asked.queryParameters, {'show': 'on_the_way', 'offset': '30'});
    expect(page.total, 31);
    expect(page.nextOffset, isNull);
  });

  test('checks a scanned parcel without marking it', () async {
    late http.Request sent;
    final api = ApiClient.withClient(
      MockClient((request) async {
        sent = request;
        return http.Response(
          '{"ok":true,"data":{"verdict":"not_here","here":"Nairobi",'
          '"parcel":{"tracking_no":"PKT-461144","to":"Nakuru"}}}',
          200,
        );
      }),
    );

    final check = await ClerkService(api: api).checkArrival('PKT-461144');

    expect(sent.method, 'GET');
    expect(sent.url.path, endsWith('/parcels/PKT-461144/arrival'));
    expect(check.verdict, ArrivalVerdict.notHere);
  });

  test('marks a parcel as arrived and gets the new list back', () async {
    late http.Request sent;
    final api = ApiClient.withClient(
      MockClient((request) async {
        sent = request;
        return http.Response(
          '{"ok":true,"data":{"parcel":{"tracking_no":"PKT-460048","receiver_name":"Kevin Maina"},'
          '"arrivals":[{"tracking_no":"PKT-460048","from":"Nyeri","vehicle":"KDG 117T",'
          '"at":"2026-11-19T17:12:00+03:00"}]}}',
          200,
        );
      }),
    );

    final result = await ClerkService(api: api).markArrived('PKT-460048');

    expect(sent.method, 'POST');
    expect(sent.url.path, endsWith('/parcels/PKT-460048/arrival'));
    expect(result.receiverName, 'Kevin Maina');
    expect(result.arrivals.single.trackingNo, 'PKT-460048');
  });

  test("asks for what came in at the clerk's office today", () async {
    late Uri asked;
    final api = ApiClient.withClient(
      MockClient((request) async {
        asked = request.url;
        return http.Response('{"ok":true,"data":{"arrivals":[]}}', 200);
      }),
    );

    final arrivals = await ClerkService(api: api).fetchArrivals();

    expect(asked.path, endsWith('/clerk/arrivals'));
    expect(arrivals, isEmpty);
  });
}
