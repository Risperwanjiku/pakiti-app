import 'package:flutter/material.dart';

import 'package:pakiti_app/models/clerk_summary.dart';
import 'package:pakiti_app/models/parcel_filter.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/common/placeholder_bar.dart';

// the Booked, On the way and Arrived numbers on the clerk's home screen
class TodayCounts extends StatelessWidget {
  const TodayCounts({super.key, required this.summary, required this.onShowParcels});

  // null while it loads, which shows grey bars instead of numbers
  final ClerkSummary? summary;

  // opens Parcels on the filter that matches the number tapped
  final ValueChanged<ParcelFilter> onShowParcels;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;

    // nothing to open until the numbers are in
    VoidCallback? showParcels(ParcelFilter filter) {
      return summary == null ? null : () => onShowParcels(filter);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _CountTile(
              count: summary?.booked,
              label: 'Booked',
              onTap: showParcels(ParcelFilter.booked),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CountTile(
              count: summary?.onTheWay,
              label: 'On the way',
              onTap: showParcels(ParcelFilter.onTheWay),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CountTile(
              count: summary?.arrived,
              label: 'Arrived',
              highlight: true,
              onTap: showParcels(ParcelFilter.arrived),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.count,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final int? count;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final count = this.count;
    final color = highlight ? AppColors.statusArrived : AppColors.navy;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 34,
                child: count == null
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: const PlaceholderBar(width: 32, height: 22),
                      )
                    : Text(
                        '$count',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: color),
                      ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: highlight ? FontWeight.w500 : FontWeight.w400,
                  color: highlight ? AppColors.statusArrived : AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
