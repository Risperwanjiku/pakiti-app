import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pakiti_app/models/staff_user.dart';
import 'package:pakiti_app/screens/account/login_screen.dart';
import 'package:pakiti_app/screens/clerk/clerk_tabs.dart';
import 'package:pakiti_app/screens/conductor/conductor_tabs.dart';
import 'package:pakiti_app/services/auth_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';

// The tabs a staff member works in, or null for the admin, whose screens aren't built yet.
Widget? tabsFor(StaffUser user) {
  return switch (user.role) {
    StaffRole.clerk => ClerkTabs(user: user),
    StaffRole.conductor => ConductorTabs(user: user),
    StaffRole.admin => null,
  };
}

// The first screen. A login is kept for 7 days, so someone who logged in earlier goes
// straight to their tabs, and everyone else gets Log in.
class StartScreen extends StatefulWidget {
  const StartScreen({super.key, this.auth});

  // tests pass in a fake one
  final AuthService? auth;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final AuthService _authService = widget.auth ?? AuthService();

  @override
  void initState() {
    super.initState();
    _openSavedLogin();
  }

  Future<void> _openSavedLogin() async {
    Widget? next;

    try {
      final user = await _authService.currentUser();
      next = user == null ? null : tabsFor(user);
    } catch (_) {
      // no signal or no server: Log in shows why when the clerk tries, and the saved
      // login is still there for next time
      next = null;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => next ?? const LoginScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  // the same navy as Log in, so there is no flash while the saved login is checked
  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
        ),
      ),
    );
  }
}
