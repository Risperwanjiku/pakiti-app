import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// tick: on board or scanned off, ring: still to be scanned, box: on its way
enum ParcelMark { tick, ring, box }

// a parcel in the conductor's lists
class TripParcelRow extends StatelessWidget {
  const TripParcelRow({
    super.key,
    required this.mark,
    required this.trackingNo,
    required this.receiverName,
    this.note,
    this.noteColor = AppColors.grey,
    this.muted = false,
  });

  final ParcelMark mark;
  final String trackingNo;
  final String receiverName;

  // on the right, like Just now or Off at 5:12 pm
  final String? note;
  final Color noteColor;

  // for parcels still at the office, which are not the conductor's yet
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final note = this.note;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          _buildMark(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trackingNo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
                    color: muted ? AppColors.statusBooked : AppColors.darkText,
                  ),
                ),
                Text(
                  'For $receiverName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(width: 12),
            Text(
              note,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: noteColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMark() {
    return switch (mark) {
      ParcelMark.tick => Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.statusCollected,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        ),
      ParcelMark.ring => Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider, width: 2),
          ),
        ),
      ParcelMark.box => const Icon(
          Icons.inventory_2_outlined,
          size: 20,
          color: AppColors.grey,
        ),
    };
  }
}

// the rows in one white card, with a line between them
class TripParcelCard extends StatelessWidget {
  const TripParcelCard({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.page),
            rows[i],
          ],
        ],
      ),
    );
  }
}