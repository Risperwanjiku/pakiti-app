import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';

// the bar under the booking form with the fee and the Book parcel button
class BookingFeeBar extends StatelessWidget {
  const BookingFeeBar({super.key, required this.fee, required this.onBook});

  // null until a size is picked, since the fee depends on the size
  final num? fee;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final fee = this.fee;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Row(
            children: [
              if (fee != null) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fee',
                      style: TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                    Text(
                      ksh(fee),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: onBook,
                  child: const Text('Book parcel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
