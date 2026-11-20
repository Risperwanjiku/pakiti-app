import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/screens/account/change_password_screen.dart';
import 'package:pakiti_app/services/api_client.dart';

import '../../support/fakes.dart';

// the boxes from top to bottom: current password, new password, new password again
Finder box(int index) => find.byType(TextField).at(index);

Future<void> openScreen(WidgetTester tester, FakeAuthService auth) async {
  await tester.pumpWidget(MaterialApp(home: ChangePasswordScreen(auth: auth)));
  await tester.pumpAndSettle();
}

Future<void> fillInAndSave(WidgetTester tester, String current, String chosen, String again) async {
  await tester.enterText(box(0), current);
  await tester.enterText(box(1), chosen);
  await tester.enterText(box(2), again);
  await tester.tap(find.text('Save new password'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens with the keyboard on the current password', (tester) async {
    await openScreen(tester, FakeAuthService());

    final current = tester.widget<EditableText>(find.byType(EditableText).first);

    expect(current.focusNode.hasFocus, isTrue);
  });

  testWidgets('Next on the keyboard goes to the next box, not to the eye button', (tester) async {
    await openScreen(tester, FakeAuthService());

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    final newPassword = tester.widget<EditableText>(find.byType(EditableText).at(1));

    expect(newPassword.focusNode.hasFocus, isTrue);
  });

  testWidgets('says what is missing without asking the server', (tester) async {
    final auth = FakeAuthService();
    await openScreen(tester, auth);

    await tester.tap(find.text('Save new password'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your current password.'), findsOneWidget);
    expect(find.text('Enter a new password.'), findsOneWidget);
    expect(find.text('Type the new password again.'), findsOneWidget);
    expect(auth.changes, isEmpty);
  });

  testWidgets('needs 8 characters and the same new password twice', (tester) async {
    final auth = FakeAuthService();
    await openScreen(tester, auth);

    await fillInAndSave(tester, 'nyeri office morning', 'mandazi', 'mandazi7');

    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.text("This doesn't match the new password."), findsOneWidget);
    expect(auth.changes, isEmpty);
  });

  testWidgets('a wrong current password shows under its box and the new one stays', (tester) async {
    final auth = FakeAuthService(
      error: const ApiException(
        'Check the passwords and try again.',
        statusCode: 422,
        fieldErrors: {'current_password': "That's not your current password."},
      ),
    );
    await openScreen(tester, auth);

    await fillInAndSave(tester, 'not it', 'kahawa tamu asubuhi', 'kahawa tamu asubuhi');

    expect(find.text("That's not your current password."), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(1)).controller.text,
      'kahawa tamu asubuhi',
    );

    // typing in that box again clears the message
    await tester.enterText(box(0), 'nyeri office morning');
    await tester.pump();

    expect(find.text("That's not your current password."), findsNothing);
  });

  testWidgets('closes with true once the new password is saved', (tester) async {
    final auth = FakeAuthService();
    bool? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              saved = await Navigator.of(
                context,
              ).push<bool>(MaterialPageRoute(builder: (_) => ChangePasswordScreen(auth: auth)));
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await fillInAndSave(
      tester,
      'nyeri office morning',
      'kahawa tamu asubuhi',
      'kahawa tamu asubuhi',
    );

    expect(auth.changes, ['nyeri office morning -> kahawa tamu asubuhi']);
    expect(saved, isTrue);
    expect(find.byType(ChangePasswordScreen), findsNothing);
  });

  testWidgets('offers to log in again when the session has ended', (tester) async {
    final auth = FakeAuthService(
      error: const ApiException('Your session has ended. Please log in again.', statusCode: 401),
    );
    await openScreen(tester, auth);

    await fillInAndSave(
      tester,
      'nyeri office morning',
      'kahawa tamu asubuhi',
      'kahawa tamu asubuhi',
    );

    expect(find.text('Your session has ended. Please log in again.'), findsOneWidget);
    expect(find.text('Log in again'), findsOneWidget);
  });
}
