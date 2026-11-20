import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';

// shown when a list has nothing in it, like no parcels or no towns
class EmptyListCard extends StatelessWidget {
  const EmptyListCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inventory_2_outlined,
    this.iconColor = AppColors.grey,
    this.extra = const [],
  });

  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  // anything shown under the message, like a note or a button
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          ...extra,
        ],
      ),
    );
  }
}
