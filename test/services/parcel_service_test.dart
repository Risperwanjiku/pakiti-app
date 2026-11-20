import 'dart:convert';

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

    final details = await ParcelService(api: api).fetchDetails('PKT-460048');

    expect(asked.url.path, endsWith('/parcels/PKT-460048'));
    expect(asked.headers['Authorization'], 'Bearer abc123');
    expect(details.booking.trackingNo, 'PKT-460048');
  });

  test('the photo is asked for with the token too', () {
    final api = ApiClient.withClient(MockClient((_) async => http.Response('', 404)))
      ..token = 'abc123';

    final photo = ParcelService(api: api).photoOf('PKT-460048') as NetworkImage;

    expect(photo.url, endsWith('/parcels/PKT-460048/photo'));
    expect(photo.headers, {'Authorization': 'Bearer abc123'});
  });

  test('the handover photo has its own address', () {
    final api = ApiClient.withClient(MockClient((_) async => http.Response('', 404)))
      ..token = 'abc123';

    final photo = ParcelService(api: api).handoverPhotoOf('PKT-460048') as NetworkImage;

    expect(photo.url, endsWith('/parcels/PKT-460048/handover-photo'));
    expect(photo.headers, {'Authorization': 'Bearer abc123'});
  });

  test('a hand-over sends the code and the photo together', () async {
    late http.Request asked;
    final api = ApiClient.withClient(MockClient((request) async {
      asked = request;
      return http.Response(
        '{"ok":true,"data":{"parcel":{"tracking_no":"PKT-460048","receiver_name":"Kevin Maina"},'
        '"collected_at":"2026-11-20T10:42:00+03:00","by":"Mercy Njoroge","office":"Nairobi office"}}',
        200,
      );
    }));

    final result = await ParcelService(api: api).handOver(
      'PKT-460048',
      code: '481207',
      photoPath: photoFile(),
    );
    final body = latin1.decode(asked.bodyBytes);

    expect(asked.method, 'POST');
    expect(asked.url.path, endsWith('/parcels/PKT-460048/collection'));
    expect(asked.headers['content-type'], startsWith('multipart/form-data'));
    expect(body, contains('name="code"\r\n\r\n481207\r\n'));
    expect(body, contains('name="photo"'));
    expect(result.receiverName, 'Kevin Maina');
    expect(result.handedOverBy, 'Mercy Njoroge');
    expect(result.office, 'Nairobi office');
    expect(result.collectedAt.toUtc(), DateTime.utc(2026, 11, 20, 7, 42));
  });

  test('a wrong code comes back as a message for the code box', () async {
    final api = ApiClient.withClient(MockClient((_) async {
      return http.Response(
        '{"ok":false,"error":"Some details need checking.",'
        '"errors":{"code":"That code is wrong. 4 tries left."}}',
        422,
      );
    }));

    await expectLater(
      ParcelService(api: api).handOver('PKT-460048', code: '481270', photoPath: photoFile()),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.fieldErrors['code'], 'code', 'That code is wrong. 4 tries left.'),
      ),
    );
  });

  test('a new code is asked for by tracking number', () async {
    late http.Request asked;
    final api = ApiClient.withClient(MockClient((request) async {
      asked = request;
      return http.Response('{"ok":true,"data":{"sent_to":"+254745902117"}}', 200);
    }));

    await ParcelService(api: api).sendNewCode('PKT-460048');

    expect(asked.method, 'POST');
    expect(asked.url.path, endsWith('/parcels/PKT-460048/code'));
  });
}