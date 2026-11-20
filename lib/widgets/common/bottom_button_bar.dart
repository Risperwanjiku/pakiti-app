import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// the white strip along the bottom of a screen that holds its main button, like Hand over
class BottomButtonBar extends StatelessWidget {
  const BottomButtonBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
