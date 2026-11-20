import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/busy_label.dart';

// The Depart button along the bottom of the loading screen.
class DepartBar extends StatelessWidget {
  const DepartBar({
    super.key,
    required this.label,
    required this.departing,
    required this.onDepart,
  });

  // what the button says, like Depart with 2 parcels
  final String label;

  // shows a spinner in the button while the trip departs
  final bool departing;

  // null while busy, which greys the button out
  final VoidCallback? onDepart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: FilledButton(
          onPressed: onDepart,
          child: departing ? const BusyLabel('Departing…') : Text(label),
        ),
      ),
    );
  }
}
