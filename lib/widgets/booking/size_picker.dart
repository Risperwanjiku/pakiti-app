import 'package:flutter/material.dart';

import 'package:pakiti_app/models/parcel_size.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/widgets/form/field_error.dart';
import 'package:pakiti_app/widgets/form/field_label.dart';

// a row of size tiles, each with the fee for that size
class SizePicker extends StatelessWidget {
  const SizePicker({
    super.key,
    required this.fees,
    required this.selected,
    required this.onPick,
    this.error,
  });

  final Map<ParcelSize, num> fees;
  final ParcelSize? selected;
  final void Function(ParcelSize size) onPick;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Size'),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final size in ParcelSize.values) ...[
                if (size != ParcelSize.values.first) const SizedBox(width: 8),
                Expanded(child: _buildTile(size)),
              ],
            ],
          ),
        ),
        FieldError(message: error),
      ],
    );
  }

  Widget _buildTile(ParcelSize size) {
    final isSelected = selected == size;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: isSelected
            ? AppColors.navy
            : error != null
            ? AppColors.error
            : AppColors.border,
        width: isSelected ? 2.5 : 1.5,
      ),
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: Material(
          color: isSelected ? AppColors.statusOnTheWayBg : Colors.white,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: () => onPick(size),
            child: Padding(
              // the thicker border takes 1 px, so the text does not move when picked
              padding: EdgeInsets.all(isSelected ? 11 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    size.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  Text(
                    size.hint,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  const Spacer(),
                  const SizedBox(height: 6),
                  Text(
                    ksh(fees[size]!),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
