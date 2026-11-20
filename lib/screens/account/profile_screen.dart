import 'package:flutter/material.dart';

import 'package:pakiti_app/models/staff_user.dart';
import 'package:pakiti_app/screens/account/change_password_screen.dart';
import 'package:pakiti_app/services/auth_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/account/account_card.dart';
import 'package:pakiti_app/widgets/common/page_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user, this.auth});

  final StaffUser user;

  // tests pass in a fake one
  final AuthService? auth;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _authService = widget.auth ?? AuthService();

  bool _loggingOut = false;

  Future<void> _changePassword() async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => ChangePasswordScreen(auth: _authService)));

    if (changed == true && mounted) {
      showMessage(context, 'Password changed.');
    }
  }

  Future<void> _logOut() async {
    setState(() => _loggingOut = true);

    // clears the token on this phone even if the server can't be reached, and goes to
    // Log in even if the phone's storage fails, so Log out never gets stuck
    try {
      await _authService.logout();
    } finally {
      if (mounted) {
        goToLogin(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: const PageAppBar(title: 'Profile', isTab: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          AccountCard(user: widget.user),
          const SizedBox(height: 12),
          const Text(
            'If any of these details are wrong, ask your admin to fix them.',
            style: TextStyle(fontSize: 13, color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          _buildChangePasswordRow(),
          const SizedBox(height: 16),
          _buildLogOutButton(),
        ],
      ),
    );
  }

  Widget _buildChangePasswordRow() {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _loggingOut ? null : _changePassword,
          child: const SizedBox(
            height: 56,
            child: Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 22, color: AppColors.grey),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Change password',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: AppColors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogOutButton() {
    return OutlinedButton.icon(
      onPressed: _loggingOut ? null : _logOut,
      // white, since this one sits on the grey page rather than a white card
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        disabledBackgroundColor: Colors.white,
      ),
      icon: _loggingOut
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.navy),
            )
          : const Icon(Icons.logout, size: 22),
      label: Text(_loggingOut ? 'Logging out…' : 'Log out'),
    );
  }
}
