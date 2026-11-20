import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// the red message under a part of the booking form that isn't a text field
class FieldError extends StatelessWidget {
  const FieldError({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;

    if (message == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Semantics(
        liveRegion: true,
        child: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.error)),
      ),
    );
  }
}
