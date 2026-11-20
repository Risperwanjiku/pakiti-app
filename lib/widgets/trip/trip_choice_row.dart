import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// One line on the start trip card, like Route or Vehicle, with a Choose or Change button.
class TripChoiceRow extends StatelessWidget {
  const TripChoiceRow({
    super.key,
    required this.label,
    required this.value,
    required this.note,
    required this.onChange,
  });

  final String label;

  // null until something is chosen
  final String? value;
  final String? note;

  // null while the trip is starting
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final note = this.note;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
                Text(
                  value ?? 'Not chosen yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: value == null ? AppColors.grey : AppColors.darkText,
                  ),
                ),
                if (note != null)
                  Text(
                    note,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.link,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(value == null ? 'Choose' : 'Change'),
          ),
        ],
      ),
    );
  }
}
