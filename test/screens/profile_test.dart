import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakiti_app/models/staff_user.dart';
import 'package:pakiti_app/screens/change_password.dart';
import 'package:pakiti_app/screens/login.dart';
import 'package:pakiti_app/screens/profile.dart';

import '../support/fakes.dart';

Future<void> openProfile(
  WidgetTester tester, {
  StaffUser user = peter,
  FakeAuthService? auth,
}) {
  return tester.pumpWidget(
    MaterialApp(home: ProfileScreen(user: user, auth: auth ?? FakeAuthService())),
  );
}

void main() {
  testWidgets('shows who is logged in and the number they log in with', (tester) async {
    await openProfile(tester);

    expect(find.text('PM'), findsOneWidget);
    expect(find.text('Peter Mwangi'), findsOneWidget);
    expect(find.text('Clerk, Nyeri office'), findsOneWidget);
    expect(find.text('0712 345 678'), findsOneWidget);
    expect(find.text('You log in with this number.'), findsOneWidget);
  });

  testWidgets('takes the initials from the first and last names', (tester) async {
    await openProfile(
      tester,
      user: const StaffUser(
        id: 4,
        fullName: 'Grace Wanjiru Achieng',
        phone: '+254798765432',
        role: StaffRole.clerk,
        officeId: 3,
        officeName: 'Nakuru office',
      ),
    );

    expect(find.text('GA'), findsOneWidget);
    expect(find.text('Clerk, Nakuru office'), findsOneWidget);
  });

  testWidgets('Log out ends the session and goes back to the login screen', (tester) async {
    final auth = FakeAuthService();
    await openProfile(tester, auth: auth);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(auth.loggedOut, isTrue);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
  });

  testWidgets('says the password changed once Change password is done', (tester) async {
    final auth = FakeAuthService();
    await openProfile(tester, auth: auth);

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'nyeri office morning');
    await tester.enterText(find.byType(TextField).at(1), 'kahawa tamu asubuhi');
    await tester.enterText(find.byType(TextField).at(2), 'kahawa tamu asubuhi');
    await tester.tap(find.text('Save new password'));
    await tester.pumpAndSettle();

    expect(auth.changes, ['nyeri office morning -> kahawa tamu asubuhi']);
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(find.text('Password changed.'), findsOneWidget);
  });
}