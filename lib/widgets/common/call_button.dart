import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

class CallButton extends StatelessWidget {
  const CallButton({super.key, required this.label, required this.onPressed});

  // read out by the screen reader, like "Call John Otieno, the conductor"
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.navTint,
        fixedSize: const Size(44, 44),
      ),
      icon: const Icon(Icons.call_outlined, size: 20, color: AppColors.navy),
    );
  }
}
