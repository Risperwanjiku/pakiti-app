import 'package:flutter/material.dart';

import 'package:pakiti_app/models/new_parcel.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/parcel_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/widgets/common/busy_label.dart';
import 'package:pakiti_app/widgets/common/detail_row.dart';
import 'package:pakiti_app/widgets/common/sheet_body.dart';

// closes with the booked parcel, or with nothing when the clerk goes back to edit
class CheckDetailsSheet extends StatefulWidget {
  const CheckDetailsSheet({
    super.key,
    required this.parcel,
    required this.requestId,
    required this.onFieldErrors,
    this.service,
  });

  final NewParcel parcel;
  final String requestId;
  final void Function(Map<String, String> errors) onFieldErrors;

  // tests pass in a fake one
  final ParcelService? service;

  @override
  State<CheckDetailsSheet> createState() => _CheckDetailsSheetState();
}

class _CheckDetailsSheetState extends State<CheckDetailsSheet> {
  late final ParcelService _parcelService = widget.service ?? ParcelService();

  bool _booking = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _booking = true;
      _error = null;
    });

    try {
      final booked = await _parcelService.book(widget.parcel, requestId: widget.requestId);

      if (mounted) {
        Navigator.of(context).pop(booked);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      // the server found something to fix in the form itself
      if (error.fieldErrors.isNotEmpty) {
        widget.onFieldErrors(error.fieldErrors);
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _booking = false;
        _error = error.message;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _booking = false;
          _error = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parcel = widget.parcel;

    return SheetBody(
      title: 'Check with the customer',
      children: [
        const SizedBox(height: 4),
        const Text(
          'Read these back before you book.',
          style: TextStyle(fontSize: 14, color: AppColors.grey),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.statusOnTheWayBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Collection code goes to',
                style: TextStyle(fontSize: 12, color: AppColors.statusBooked),
              ),
              const SizedBox(height: 2),
              Text(
                localPhone(parcel.receiverPhone),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.navy,
                ),
              ),
              Text(
                '${parcel.receiverName}, ${parcel.destination.town}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DetailRow(
          label: 'Sender',
          value: '${parcel.senderName}, ${localPhone(parcel.senderPhone)}',
        ),
        if (parcel.senderEmail != null) DetailRow(label: 'Email', value: parcel.senderEmail!),
        DetailRow(label: "What's inside", value: parcel.contents),
        DetailRow(label: 'Value', value: ksh(parcel.value)),
        DetailRow(label: 'Size and fee', value: '${parcel.size.label}, ${ksh(parcel.fee)}'),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.error)),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _booking ? null : _confirm,
          child: _booking
              ? const BusyLabel('Booking…')
              : Text(_error == null ? 'Confirm and book' : 'Try again'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _booking ? null : () => Navigator.of(context).pop(),
          child: const Text('Edit details'),
        ),
      ],
    );
  }
}
