import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// the fixed start of a text box with a line after it, like +254 or PKT-
class FieldPrefix extends StatelessWidget {
  const FieldPrefix(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(width: 12),
          const SizedBox(
            height: 24,
            child: VerticalDivider(width: 1, thickness: 1.5, color: AppColors.divider),
          ),
        ],
      ),
    );
  }
}
