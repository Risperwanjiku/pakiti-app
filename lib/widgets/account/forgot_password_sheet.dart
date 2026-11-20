import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/pakiti_sheet.dart';
import 'package:pakiti_app/widgets/common/sheet_body.dart';

// there's no reset by SMS yet, so the admin sets a new password and the clerk changes it in Profile
Future<void> showForgotPasswordSheet(BuildContext context) {
  return showPakitiSheet<void>(
    context,
    builder: (context) {
      return SheetBody(
        title: 'Forgot your password?',
        children: [
          const SizedBox(height: 8),
          const Text(
            'Your admin can reset it for you. Log in with the password they give you, '
            'then change it in Profile to one only you know.',
            style: TextStyle(fontSize: 16, color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      );
    },
  );
}
