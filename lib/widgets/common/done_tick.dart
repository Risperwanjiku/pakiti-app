import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// How the app shows that something is done: a 20px green circle with a white tick.
class DoneTick extends StatelessWidget {
  const DoneTick({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: AppColors.statusCollected,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 14, color: Colors.white),
    );
  }
}
