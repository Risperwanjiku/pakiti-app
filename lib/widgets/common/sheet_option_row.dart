import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// One thing to pick in a bottom sheet list, with a tick on the one already chosen.
class SheetOptionRow extends StatelessWidget {
  const SheetOptionRow({
    super.key,
    required this.title,
    this.note,
    this.noteColor = AppColors.grey,
    required this.chosen,
    required this.onTap,
  });

  final String title;
  final String? note;
  final Color noteColor;
  final bool chosen;

  // null when it can't be picked, which greys the title out
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppColors.darkText : AppColors.grey,
                    ),
                  ),
                  if (note != null)
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: noteColor == AppColors.grey ? FontWeight.w400 : FontWeight.w500,
                        color: noteColor,
                      ),
                    ),
                ],
              ),
            ),
            if (chosen) const Icon(Icons.check, color: AppColors.link),
          ],
        ),
      ),
    );
  }
}
