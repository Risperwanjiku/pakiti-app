import 'package:flutter/material.dart';

import 'package:pakiti_app/models/booked_parcel.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/parcel/parcel_label.dart';

class ParcelBookedScreen extends StatelessWidget {
  const ParcelBookedScreen({super.key, required this.parcel, this.onBookAnother});

  final BookedParcel parcel;
  final void Function(BookedParcel parcel)? onBookAnother;

  void _close(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // goes back to the town list, which starts the next form with the same sender
  void _bookAnother(BuildContext context) {
    onBookAnother?.call(parcel);
    Navigator.of(context).pop();
  }

  void _printLabel(BuildContext context) {
    showMessage(context, 'Printing is coming next.');
  }

  @override
  Widget build(BuildContext context) {
    final firstName = parcel.senderName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: AppColors.page,
        surfaceTintColor: AppColors.page,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => _close(context),
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
                    'Parcel booked',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(color: Color(0x290F1B2D), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: FittedBox(child: ParcelLabel(parcel: parcel)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Prints on the POS printer, with a receipt for $firstName.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => _printLabel(context),
                    icon: const Icon(Icons.print_outlined, size: 22),
                    label: const Text('Print label and receipt'),
                  ),
                  if (onBookAnother != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _bookAnother(context),
                      child: Text('Book another for $firstName'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
