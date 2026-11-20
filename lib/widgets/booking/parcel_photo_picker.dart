import 'dart:io';

import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/widgets/form/field_error.dart';

// the Take a photo button, which turns into a small preview with Retake once a photo is taken
class ParcelPhotoPicker extends StatelessWidget {
  const ParcelPhotoPicker({
    super.key,
    required this.photoPath,
    required this.takenAt,
    required this.onTakePhoto,
    this.error,
  });

  final String? photoPath;
  final DateTime? takenAt;
  final VoidCallback onTakePhoto;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final photoPath = this.photoPath;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: error != null ? AppColors.error : AppColors.border,
        width: 1.5,
      ),
    );

    if (photoPath == null) {
      return _buildTakePhoto(shape);
    }

    return _buildPreview(photoPath, shape);
  }

  Widget _buildTakePhoto(ShapeBorder shape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.white,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onTakePhoto,
            child: SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.statusBookedBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take a photo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          'Proof of its condition at booking',
                          style: TextStyle(fontSize: 12, color: AppColors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        FieldError(message: error),
      ],
    );
  }

  Widget _buildPreview(String path, ShapeBorder shape) {
    final takenAt = this.takenAt;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: ShapeDecoration(color: Colors.white, shape: shape),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(path),
              width: 56,
              height: 56,
              cacheWidth: 168,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.statusCollected,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Photo added',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                if (takenAt != null)
                  Text(
                    'Taken at ${clockTime(takenAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTakePhoto,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.link,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Retake'),
          ),
        ],
      ),
    );
  }
}
