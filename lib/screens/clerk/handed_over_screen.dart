import 'dart:io';

import 'package:flutter/material.dart';

import 'package:pakiti_app/models/handed_over.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/widgets/common/white_card.dart';
import 'package:pakiti_app/widgets/parcel/parcel_thumb.dart';

// After the receiver has the parcel. Done goes back to the parcel's page, which now shows it collected.
class HandedOverScreen extends StatelessWidget {
  const HandedOverScreen({
    super.key,
    required this.result,
    required this.photoPath,
    required this.photoTakenAt,
  });

  final HandedOver result;

  // the photo is shown from the phone, so it doesn't have to download again
  final String photoPath;
  final DateTime photoTakenAt;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: AppColors.page,
        surfaceTintColor: AppColors.page,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: AppColors.darkText),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Parcel handed over',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.receiverName} collected ${result.trackingNo} '
                    'at ${clockTime(result.collectedAt)}.',
                    style: const TextStyle(fontSize: 15, color: AppColors.grey),
                  ),
                  const SizedBox(height: 24),
                  _buildRecord(),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecord() {
    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ParcelThumb(photo: ResizeImage(FileImage(File(photoPath)), width: 168)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photo at handover',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        'Taken at ${clockTime(photoTakenAt)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.page),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Text(
              'Handed over by ${result.handedOverBy} at ${result.office}. '
              "It's now in the parcel's history.",
              style: const TextStyle(fontSize: 14, color: AppColors.darkText),
            ),
          ),
        ],
      ),
    );
  }
}
