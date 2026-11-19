import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'dashed_line.dart';

// From one town to the other, dashed while on the way and solid once it got there.
class TripLine extends StatelessWidget {
  const TripLine({
    super.key,
    required this.from,
    required this.fromNote,
    required this.to,
    required this.toNote,
    required this.arrived,
  });

  final String from;
  final String fromNote;
  final String to;
  final String toNote;
  final bool arrived;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 16,
          child: Row(
            children: [
              _buildDot(filled: true),
              const SizedBox(width: 6),
              Expanded(
                child: arrived
                    ? Container(height: 2, color: AppColors.navy)
                    : const DashedLine(color: AppColors.divider),
              ),
              const SizedBox(width: 6),
              _buildDot(filled: arrived),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildEnd(from, fromNote)),
            const SizedBox(width: 12),
            Expanded(child: _buildEnd(to, toNote, atEnd: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildDot({required bool filled}) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: filled ? AppColors.navy : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.navy, width: 2),
      ),
    );
  }

  Widget _buildEnd(String town, String note, {bool atEnd = false}) {
    return Column(
      crossAxisAlignment: atEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          town,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        Text(
          note,
          textAlign: atEnd ? TextAlign.right : TextAlign.left,
          style: const TextStyle(fontSize: 13, color: AppColors.grey),
        ),
      ],
    );
  }
}