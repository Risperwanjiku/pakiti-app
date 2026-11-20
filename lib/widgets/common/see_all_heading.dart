import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// A list's heading with See all on the right, for a list that only shows the latest few.
class SeeAllHeading extends StatelessWidget {
  const SeeAllHeading({super.key, required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.link,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Text('See all'),
        ),
      ],
    );
  }
}
