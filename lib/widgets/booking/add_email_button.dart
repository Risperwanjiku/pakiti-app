import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// Under the sender's phone. The email is optional, so its box only shows once this is tapped.
class AddEmailButton extends StatelessWidget {
  const AddEmailButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add email for a receipt'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.link,
          minimumSize: const Size(0, 44),
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
