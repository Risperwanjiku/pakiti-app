import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';

// A white card that stands in for a list with nothing in it.
class EmptyTripList extends StatelessWidget {
  const EmptyTripList({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: AppColors.grey),
      ),
    );
  }
}
