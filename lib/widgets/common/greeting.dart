import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// At the top of the first screen after logging in, for clerks and conductors.
class Greeting extends StatelessWidget {
  const Greeting({super.key, required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Habari, $firstName',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
    );
  }
}
