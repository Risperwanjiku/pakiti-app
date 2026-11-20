import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// A list's heading, with a short note on the right like 2 parcels.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final note = this.note;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
        ),
        if (note != null)
          Text(
            note,
            style: const TextStyle(fontSize: 13, color: AppColors.grey),
          ),
      ],
    );
  }
}
