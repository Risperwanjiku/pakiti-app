import 'package:flutter/material.dart';

import 'package:pakiti_app/models/parcel_filter.dart';
import 'package:pakiti_app/theme/app_colors.dart';

// the All, Booked, On the way and Arrived chips at the top of Parcels
class ParcelFilterBar extends StatelessWidget {
  const ParcelFilterBar({super.key, required this.chosen, required this.onChoose});

  final ParcelFilter chosen;
  final ValueChanged<ParcelFilter> onChoose;

  @override
  Widget build(BuildContext context) {
    // all four fit on a 360 dp phone; this only scrolls with very large text
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        spacing: 8,
        children: [for (final filter in ParcelFilter.values) _buildChip(filter)],
      ),
    );
  }

  Widget _buildChip(ParcelFilter filter) {
    final isChosen = filter == chosen;

    return Semantics(
      button: true,
      selected: isChosen,
      child: Material(
        color: isChosen ? AppColors.navy : Colors.white,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => onChoose(filter),
          child: Container(
            height: 40,
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Text(
              filter.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isChosen ? Colors.white : AppColors.darkText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
