import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/screens/account/login_screen.dart';
import 'package:pakiti_app/screens/account/start_screen.dart';
import 'package:pakiti_app/services/api_client.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('with no saved login, Log in opens', (tester) async {
    await tester.pumpWidget(MaterialApp(home: StartScreen(auth: FakeAuthService())));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('with no signal, Log in opens instead of waiting', (tester) async {
    final auth = FakeAuthService(
      savedLoginError: const ApiException(
        "Can't reach the server. Check your connection and try again.",
      ),
    );
    await tester.pumpWidget(MaterialApp(home: StartScreen(auth: auth)));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
