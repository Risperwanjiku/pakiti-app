import 'package:flutter/material.dart';

import 'package:pakiti_app/models/arrival.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/widgets/common/pakiti_sheet.dart';
import 'package:pakiti_app/widgets/common/status_tag.dart';

// For a parcel coming in to this office. Gives back true when the clerk taps
// Mark as arrived, and false when the sheet is closed.
Future<bool> showArrivalSheet(
  BuildContext context, {
  required IncomingParcel parcel,
  required ImageProvider photo,
}) async {
  final marked = await showPakitiSheet<bool>(
    context,
    builder: (_) => _ArrivalSheet(parcel: parcel, photo: photo),
  );

  return marked ?? false;
}

class _ArrivalSheet extends StatelessWidget {
  const _ArrivalSheet({required this.parcel, required this.photo});

  final IncomingParcel parcel;
  final ImageProvider photo;

  @override
  Widget build(BuildContext context) {
    final departedAt = parcel.departedAt;
    final vehicle = parcel.vehicle;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  StatusTag(status: parcel.status),
                  const SizedBox(width: 12),
                  if (departedAt != null)
                    Expanded(
                      child: Text(
                        'Left ${parcel.from} ${atTimeOrDay(departedAt)}',
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.grey),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                parcel.trackingNo,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                vehicle == null ? 'From ${parcel.from}' : 'From ${parcel.from} on $vehicle',
                style: const TextStyle(fontSize: 14, color: AppColors.grey),
              ),
              const SizedBox(height: 16),
              _buildContents(),
              const SizedBox(height: 16),
              const Text(
                'Receiver',
                style: TextStyle(fontSize: 13, color: AppColors.grey),
              ),
              Text(
                parcel.receiverName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                localPhone(parcel.receiverPhone),
                style: const TextStyle(fontSize: 14, color: AppColors.grey),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Mark as arrived'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.link,
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // the photo from booking next to what's inside, so the clerk can see it is the same parcel
  Widget _buildContents() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.page,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image(
              image: photo,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                return frame == null && !wasSynchronouslyLoaded
                    ? _buildPhotoBox(Icons.photo_outlined)
                    : child;
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildPhotoBox(Icons.image_not_supported_outlined);
              },
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parcel.contents,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  '${parcel.size.label}. Check it matches the photo.',
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // stands in for the photo while it loads, or if it fails
  Widget _buildPhotoBox(IconData icon) {
    return Container(
      width: 56,
      height: 56,
      color: Colors.white,
      child: Icon(icon, color: AppColors.border),
    );
  }
}
