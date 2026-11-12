import 'package:flutter/material.dart';

import '../models/new_parcel.dart';
import '../services/api_client.dart';
import '../services/parcel_service.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';

// closes with the booked parcel, or with nothing when the clerk goes back to edit
class CheckDetailsSheet extends StatefulWidget {
  const CheckDetailsSheet({
    super.key,
    required this.parcel,
    required this.requestId,
    required this.onFieldErrors,
  });

  final NewParcel parcel;
  final String requestId;
  final void Function(Map<String, String> errors) onFieldErrors;

  @override
  State<CheckDetailsSheet> createState() => _CheckDetailsSheetState();
}

class _CheckDetailsSheetState extends State<CheckDetailsSheet> {
  final _parcelService = ParcelService();

  bool _booking = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _booking = true;
      _error = null;
    });

    try {
      final booked = await _parcelService.book(
        widget.parcel,
        requestId: widget.requestId,
      );

      if (mounted) {
        Navigator.of(context).pop(booked);
      }
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      // the server found something to fix in the form itself
      if (e.fieldErrors.isNotEmpty) {
        widget.onFieldErrors(e.fieldErrors);
        Navigator.of(context).pop();
        return;
      }

      setState(() {
        _booking = false;
        _error = e.message;
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

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Check with the customer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
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
            _buildRow(
              'Sender',
              '${parcel.senderName}, ${localPhone(parcel.senderPhone)}',
            ),
            if (parcel.senderEmail != null) _buildRow('Email', parcel.senderEmail!),
            _buildRow("What's inside", parcel.contents),
            _buildRow('Value', ksh(parcel.value)),
            _buildRow('Size and fee', '${parcel.size.label}, ${ksh(parcel.fee)}'),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 13, color: AppColors.error),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _booking ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                disabledBackgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: _booking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                        semanticsLabel: 'Booking',
                      ),
                    )
                  : Text(_error == null ? 'Confirm and book' : 'Try again'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _booking ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                minimumSize: const Size.fromHeight(56),
                side: const BorderSide(color: AppColors.navy, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('Edit details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}