import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/parcel_service.dart';

import '../support/fakes.dart';

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

  test('a search sends what was typed, spaces and all', () async {
    late Uri asked;
    final api = ApiClient.withClient(MockClient((request) async {
      asked = request.url;
      return http.Response(
        '{"ok":true,"data":{"type":"phone","phone":"+254722418305",'
        '"name":"Esther Wambui","parcels":[]}}',
        200,
      );
    }));

    final result = await ParcelService(api: api).search('0722 418 305');

    expect(asked.path, endsWith('/parcels'));
    expect(asked.queryParameters['q'], '0722 418 305');
    expect(result.name, 'Esther Wambui');
  });

  test('a search the API cannot read gives back its message', () async {
    final api = ApiClient.withClient(MockClient((_) async {
      return http.Response(
        '{"ok":false,"error":"Type a tracking number like PKT-460048, '
        'or a phone number like 0712 345 678."}',
        422,
      );
    }));

    await expectLater(
      ParcelService(api: api).search('hello'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.message, 'message', startsWith('Type a tracking number')),
      ),
    );
  });

  test('details are asked for by tracking number, with the token', () async {
    late http.BaseRequest asked;
    final api = ApiClient.withClient(MockClient((request) async {
      asked = request;
      return http.Response(realDetailsReply, 200);
    }))..token = 'abc123';

    final details = await ParcelService(api: api).details('PKT-460048');

    expect(asked.url.path, endsWith('/parcels/PKT-460048'));
    expect(asked.headers['Authorization'], 'Bearer abc123');
    expect(details.booking.trackingNo, 'PKT-460048');
  });

  test('the photo is asked for with the token too', () {
    final api = ApiClient.withClient(MockClient((_) async => http.Response('', 404)))
      ..token = 'abc123';

    final photo = ParcelService(api: api).photo('PKT-460048') as NetworkImage;

    expect(photo.url, endsWith('/parcels/PKT-460048/photo'));
    expect(photo.headers, {'Authorization': 'Bearer abc123'});
  });
}