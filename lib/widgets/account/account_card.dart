import 'package:flutter/material.dart';

import 'package:pakiti_app/models/staff_user.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';

// the staff member's name, role and phone number at the top of Profile
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.user});

  final StaffUser user;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
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
}

// Peter Mwangi -> PM, from the first and last names only
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();

  if (parts.isEmpty) {
    return '';
  }

  final lastInitial = parts.length > 1 ? parts.last[0] : '';

  return (parts.first[0] + lastInitial).toUpperCase();
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
