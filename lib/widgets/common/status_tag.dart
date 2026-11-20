import 'package:flutter/material.dart';

import 'package:pakiti_app/models/parcel_status.dart';
import 'package:pakiti_app/theme/app_colors.dart';

class StatusTag extends StatelessWidget {
  const StatusTag({super.key, required this.status, this.isLate = false});

  final ParcelStatus status;
  final bool isLate;

  @override
  Widget build(BuildContext context) {
    final (label, textColor, background) = _labelAndColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  (String, Color, Color) _labelAndColors() {
    if (isLate) {
      return ('Late', AppColors.statusLate, AppColors.statusLateBg);
    }

    return switch (status) {
      ParcelStatus.booked => (
          'Booked',
          AppColors.statusBooked,
          AppColors.statusBookedBg,
        ),
      ParcelStatus.loaded => (
          'Loaded',
          AppColors.statusBooked,
          AppColors.statusBookedBg,
        ),
      ParcelStatus.inTransit => (
          'On the way',
          AppColors.statusOnTheWay,
          AppColors.statusOnTheWayBg,
        ),
      ParcelStatus.arrived => (
          'Arrived',
          AppColors.statusArrived,
          AppColors.statusArrivedBg,
        ),
      ParcelStatus.collected => (
          'Collected',
          AppColors.statusCollected,
          AppColors.statusCollectedBg,
        ),
    };
  }
}