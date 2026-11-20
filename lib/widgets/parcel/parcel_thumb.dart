import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// a small square photo of the parcel, with a plain box in its place while it loads or if it fails
class ParcelThumb extends StatelessWidget {
  const ParcelThumb({
    super.key,
    required this.photo,
    this.size = 56,
    this.boxColor = AppColors.page,
  });

  final ImageProvider photo;
  final double size;

  // different from the card it sits on, so the empty box still shows
  final Color boxColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image(
        image: photo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          return frame == null && !wasSynchronouslyLoaded
              ? _buildBox(Icons.photo_outlined)
              : child;
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildBox(Icons.image_not_supported_outlined);
        },
      ),
    );
  }

  Widget _buildBox(IconData icon) {
    return Container(
      width: size,
      height: size,
      color: boxColor,
      child: Icon(icon, color: AppColors.border),
    );
  }
}
