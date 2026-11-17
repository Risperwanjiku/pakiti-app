import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/screens/login.dart';

void main() {
  testWidgets('says log in, like the rest of the app', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Log in to Pakiti'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    expect(find.textContaining('Sign in'), findsNothing);
  });

  testWidgets('Forgot password? says who can reset it', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // the test screen is shorter than a phone, so the link starts below the fold
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot your password?'), findsOneWidget);
    expect(find.textContaining('Your admin can reset it for you.'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot your password?'), findsNothing);
  });
}