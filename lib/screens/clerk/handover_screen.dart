import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pakiti_app/models/parcel_details.dart';
import 'package:pakiti_app/screens/clerk/handed_over_screen.dart';
import 'package:pakiti_app/screens/clerk/parcel_photo_screen.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/parcel_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/utils/parcel_camera.dart';
import 'package:pakiti_app/widgets/booking/parcel_photo_picker.dart';
import 'package:pakiti_app/widgets/common/bottom_button_bar.dart';
import 'package:pakiti_app/widgets/common/busy_label.dart';
import 'package:pakiti_app/widgets/common/page_app_bar.dart';
import 'package:pakiti_app/widgets/form/form_section.dart';
import 'package:pakiti_app/widgets/parcel/collection_code_box.dart';
import 'package:pakiti_app/widgets/parcel/locked_sheet.dart';
import 'package:pakiti_app/widgets/parcel/parcel_check_card.dart';
import 'package:pakiti_app/widgets/parcel/receiver_id_card.dart';

// The receiver is at the counter. Gives back true once the parcel has changed, after it
// is handed over or locked, so the parcel's page loads it again.
class HandoverScreen extends StatefulWidget {
  const HandoverScreen({
    super.key,
    required this.details,
    required this.photo,
    this.service,
    this.takePhoto,
  });

  final ParcelDetails details;

  // the booking photo, already loaded by the parcel's page
  final ImageProvider photo;

  // tests pass in a fake one
  final ParcelService? service;

  // tests pass one that gives back a file, since there is no camera in a test
  final Future<String?> Function()? takePhoto;

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  late final ParcelService _service = widget.service ?? ParcelService();
  final _code = TextEditingController();

  late bool _codeSent = widget.details.handOver?.codeSent ?? true;
  String? _photoPath;
  DateTime? _photoTakenAt;
  Map<String, String> _errors = {};

  // replaces the usual line under the code once a new code has gone out
  String? _codeNote;
  bool _sendingCode = false;
  bool _handingOver = false;

  String get _trackingNo => widget.details.booking.trackingNo;

  String get _receiver => widget.details.booking.receiverName.split(' ').first;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    String? path;

    try {
      path = await (widget.takePhoto ?? takeParcelPhoto)();
    } on PlatformException {
      if (mounted) {
        showMessage(context, cameraFailedMessage);
      }
      return;
    }

    if (path == null || !mounted) {
      return;
    }

    setState(() {
      _photoPath = path;
      _photoTakenAt = DateTime.now();
      _errors = Map.of(_errors)..remove('photo');
    });
  }

  void _viewPhoto() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParcelPhotoScreen(photo: widget.photo, trackingNo: _trackingNo),
      ),
    );
  }

  void _onCodeChanged() {
    if (_errors.containsKey('code')) {
      setState(() => _errors = Map.of(_errors)..remove('code'));
    }
  }

  // the same checks the API makes, so nothing is sent just to be turned back
  Map<String, String> _check() {
    return {
      if (!_codeSent)
        'code': 'Send $_receiver a code first.'
      else if (_code.text.length != 6)
        'code': 'Type the 6 numbers of the code.',
      if (_photoPath == null) 'photo': 'Take a photo of the parcel before you hand it over.',
    };
  }

  Future<void> _handOver() async {
    FocusScope.of(context).unfocus();

    final errors = _check();

    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    setState(() {
      _errors = {};
      _handingOver = true;
    });

    try {
      final handedOver = await _service.handOver(
        _trackingNo,
        code: _code.text,
        photoPath: _photoPath!,
      );

      if (!mounted) {
        return;
      }

      HapticFeedback.mediumImpact();

      // the form is swapped for the result, so Back can't bring the finished form up again
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HandedOverScreen(
            result: handedOver,
            photoPath: _photoPath!,
            photoTakenAt: _photoTakenAt!,
          ),
        ),
        result: true,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _handingOver = false);
      await _showProblem(error);
    } catch (error) {
      if (!mounted) return;

      setState(() => _handingOver = false);
      showError(context, error);
    }
  }

  // for a receiver who lost the SMS, or a parcel that came in before codes were sent
  Future<void> _sendCode() async {
    setState(() => _sendingCode = true);

    try {
      await _service.sendNewCode(_trackingNo);

      if (!mounted) {
        return;
      }

      final phone = localPhone(widget.details.booking.receiverPhone);

      setState(() {
        _codeNote = _codeSent
            ? "New code sent to $phone. The old one won't work now."
            : 'Code sent to $phone.';
        _codeSent = true;
        _code.clear();
        _errors = Map.of(_errors)..remove('code');
        _sendingCode = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _sendingCode = false);
      await _showProblem(error);
    } catch (error) {
      if (!mounted) return;

      setState(() => _sendingCode = false);
      showError(context, error);
    }
  }

  Future<void> _showProblem(ApiException error) async {
    final status = error.statusCode;

    // the fifth wrong code, or one the clerk on the next counter typed in
    if (status == 423) {
      HapticFeedback.vibrate();
      await showLockedSheet(context, _trackingNo);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    if (status == 422 && error.fieldErrors.isNotEmpty) {
      HapticFeedback.vibrate();
      setState(() => _errors = error.fieldErrors);
      return;
    }

    // collected at another counter, or not waiting here any more
    if (status == 409) {
      showApiError(context, error);
      Navigator.of(context).pop(true);
      return;
    }

    showApiError(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _handingOver || _sendingCode;

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: PageAppBar(title: 'Hand over $_trackingNo'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReceiverIdCard(booking: widget.details.booking),
                  const SizedBox(height: 20),
                  FormSection(
                    title: 'Collection code',
                    children: [
                      CollectionCodeBox(
                        controller: _code,
                        hint: _codeHint,
                        error: _errors['code'],
                        sendLabel: _sendingCode
                            ? 'Sending…'
                            : (_codeSent ? 'Send a new code' : 'Send a code'),
                        onChanged: _onCodeChanged,
                        onSend: busy ? null : _sendCode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FormSection(
                    title: 'Parcel',
                    children: [
                      ParcelCheckCard(
                        booking: widget.details.booking,
                        photo: widget.photo,
                        hasPhoto: widget.details.hasBookingPhoto,
                        onViewPhoto: _viewPhoto,
                      ),
                      const SizedBox(height: 12),
                      ParcelPhotoPicker(
                        photoPath: _photoPath,
                        takenAt: _photoTakenAt,
                        error: _errors['photo'],
                        onTakePhoto: _takePhoto,
                        hint: 'Proof of its condition at handover',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          BottomButtonBar(
            child: FilledButton(
              onPressed: busy ? null : _handOver,
              child: _handingOver ? const BusyLabel('Handing over…') : const Text('Hand over'),
            ),
          ),
        ],
      ),
    );
  }

  String get _codeHint {
    return _codeNote ??
        (_codeSent
            ? 'Ask $_receiver for the 6 numbers.'
            : 'No code has been sent to $_receiver yet.');
  }
}
