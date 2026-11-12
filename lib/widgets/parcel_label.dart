import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/booked_parcel.dart';
import '../utils/format.dart';

// The sticker that goes on the parcel, drawn at the size of a 58 mm label.
// The printing step turns this same widget into a picture for the POS printer.
class ParcelLabel extends StatelessWidget {
  const ParcelLabel({super.key, required this.parcel});

  static const width = 464.0;
  static const height = 320.0;

  static const _footer = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  final BookedParcel parcel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.black),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'To',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    parcel.to,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 44,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                QrImageView(
                  data: parcel.trackingNo,
                  size: 168,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parcel.receiverName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.33,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        maskedPhone(parcel.receiverPhone),
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.375,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        parcel.trackingNo,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.27,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(child: Text('From ${parcel.from}', style: _footer)),
                Text(dateAndTime(parcel.bookedAt), style: _footer),
              ],
            ),
          ],
        ),
      ),
    );
  }
}