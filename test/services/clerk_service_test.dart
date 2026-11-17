import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pakiti_app/models/parcel_filter.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/clerk_service.dart';

void main() {
  test('asks for the chosen filter, starting where the page starts', () async {
    late Uri asked;
    final api = ApiClient.withClient(MockClient((request) async {
      asked = request.url;
      return http.Response(
        '{"ok":true,"data":{"show":"on_the_way","total":31,"parcels":[],"next_offset":null}}',
        200,
      );
    }));

    final page = await ClerkService(api: api).fetchParcels(ParcelFilter.onTheWay, offset: 30);

    expect(asked.path, endsWith('/clerk/parcels'));
    expect(asked.queryParameters, {'show': 'on_the_way', 'offset': '30'});
    expect(page.total, 31);
    expect(page.nextOffset, isNull);
  });
}