import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// Above a list of parcels: how many there are, and a line saying which ones they are.
class ListHeading extends StatelessWidget {
  const ListHeading({super.key, required this.title, required this.caption});

  // like 3 parcels
  final String title;

  // like Sent or received by 0712 345 678
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 2),
        Text(caption, style: const TextStyle(fontSize: 13, color: AppColors.grey)),
      ],
    );
  }
}
