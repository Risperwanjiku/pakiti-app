import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// a grey bar that stands in for text while it loads
class PlaceholderBar extends StatelessWidget {
  const PlaceholderBar({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.page, borderRadius: BorderRadius.circular(6)),
    );
  }
}
