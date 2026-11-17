import 'package:flutter/material.dart';

import '../models/staff_user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'change_password.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user, this.auth});

  final StaffUser user;

  // tests pass in a fake one
  final AuthService? auth;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _auth = widget.auth ?? AuthService();

  bool _loggingOut = false;

  Future<void> _changePassword() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ChangePasswordScreen(auth: _auth)),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Password changed.')));
    }
  }

  Future<void> _logOut() async {
    setState(() => _loggingOut = true);

    // clears the token on this phone even if the server can't be reached
    await _auth.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          _buildAccount(widget.user),
          const SizedBox(height: 12),
          const Text(
            'If any of these details are wrong, ask your admin to fix them.',
            style: TextStyle(fontSize: 13, color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          _buildChangePassword(),
          const SizedBox(height: 16),
          _buildLogOut(),
        ],
      ),
    );
  }

  Widget _buildAccount(StaffUser user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.navTint,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials(user.fullName),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        _roleAndOffice(user),
                        style: const TextStyle(fontSize: 14, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.page),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phone number',
                  style: TextStyle(fontSize: 13, color: AppColors.grey),
                ),
                Text(
                  localPhone(user.phone),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'You log in with this number.',
                  style: TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePassword() {
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

  Widget _buildLogOut() {
    return OutlinedButton.icon(
      onPressed: _loggingOut ? null : _logOut,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        disabledForegroundColor: AppColors.navy,
        backgroundColor: Colors.white,
        disabledBackgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: AppColors.navy, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      icon: _loggingOut
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.navy,
              ),
            )
          : const Icon(Icons.logout, size: 22),
      label: Text(_loggingOut ? 'Logging out…' : 'Log out'),
    );
  }
}

// Peter Mwangi -> PM, from the first and last names only
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();

  if (parts.isEmpty) {
    return '';
  }

  final last = parts.length > 1 ? parts.last[0] : '';

  return (parts.first[0] + last).toUpperCase();
}

String _roleAndOffice(StaffUser user) {
  final role = switch (user.role) {
    StaffRole.admin => 'Admin',
    StaffRole.clerk => 'Clerk',
    StaffRole.conductor => 'Conductor',
  };

  final office = user.officeName;

  return office == null ? role : '$role, $office';
}