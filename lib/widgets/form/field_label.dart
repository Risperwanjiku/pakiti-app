import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// the name above a text box, like Phone number
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
    );
  }
}
