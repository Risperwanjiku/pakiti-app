import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sends the current and the new password, with the token', () async {
    late http.Request sent;
    final api = ApiClient.withClient(
      MockClient((request) async {
        sent = request;
        return http.Response('{"ok":true,"data":{}}', 200);
      }),
    )..token = 'a1b2c3';

    await AuthService(api: api).changePassword('nyeri office morning', 'kahawa tamu asubuhi');

    expect(sent.method, 'POST');
    expect(sent.url.path, endsWith('/auth/password'));
    expect(sent.headers['Authorization'], 'Bearer a1b2c3');
    expect(jsonDecode(sent.body), {
      'current_password': 'nyeri office morning',
      'new_password': 'kahawa tamu asubuhi',
    });
  });

  test('a wrong current password comes back as an error on that field', () async {
    final api = ApiClient.withClient(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'ok': false,
            'error': 'Check the passwords and try again.',
            'errors': {'current_password': "That's not your current password."},
          }),
          422,
        );
      }),
    );

    await expectLater(
      AuthService(api: api).changePassword('not it', 'kahawa tamu asubuhi'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having(
              (e) => e.fieldErrors['current_password'],
              'current_password',
              "That's not your current password.",
            ),
      ),
    );
  });
}
