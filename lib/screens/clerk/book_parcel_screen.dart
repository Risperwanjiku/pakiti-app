import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pakiti_app/models/booked_parcel.dart';
import 'package:pakiti_app/models/destination.dart';
import 'package:pakiti_app/models/new_parcel.dart';
import 'package:pakiti_app/models/parcel_size.dart';
import 'package:pakiti_app/screens/clerk/choose_town_screen.dart';
import 'package:pakiti_app/screens/clerk/parcel_booked_screen.dart';
import 'package:pakiti_app/services/parcel_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/booking_checks.dart';
import 'package:pakiti_app/utils/format.dart';
import 'package:pakiti_app/utils/input_formatters.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/utils/parcel_camera.dart';
import 'package:pakiti_app/utils/phone.dart';
import 'package:pakiti_app/widgets/booking/add_email_button.dart';
import 'package:pakiti_app/widgets/booking/booking_fee_bar.dart';
import 'package:pakiti_app/widgets/booking/booking_field.dart';
import 'package:pakiti_app/widgets/booking/check_details_sheet.dart';
import 'package:pakiti_app/widgets/booking/destination_card.dart';
import 'package:pakiti_app/widgets/booking/parcel_photo_picker.dart';
import 'package:pakiti_app/widgets/booking/size_picker.dart';
import 'package:pakiti_app/widgets/common/page_app_bar.dart';
import 'package:pakiti_app/widgets/common/pakiti_sheet.dart';
import 'package:pakiti_app/widgets/form/form_section.dart';

class BookParcelScreen extends StatefulWidget {
  const BookParcelScreen({
    super.key,
    required this.destination,
    this.sameSenderAs,
    this.onBookAnother,
    this.takePhoto,
    this.service,
  });

  final Destination destination;

  // tests pass in a fake one
  final ParcelService? service;

  // tests pass one that gives back a file, since there is no camera in a test
  final Future<String?> Function()? takePhoto;

  // a parcel booked just before this one, whose sender fills in the sender fields
  final BookedParcel? sameSenderAs;

  // handed on to the Parcel booked screen for its Book another button
  final void Function(BookedParcel parcel)? onBookAnother;

  @override
  State<BookParcelScreen> createState() => _BookParcelScreenState();
}

class _BookParcelScreenState extends State<BookParcelScreen> {
  // same names the API uses, in the order they appear on the screen
  static const _fieldOrder = [
    'route_id',
    'size',
    'contents',
    'declared_value',
    'sender_name',
    'sender_phone',
    'sender_email',
    'receiver_name',
    'receiver_phone',
    'photo',
  ];

  final _fieldKeys = {for (final field in _fieldOrder) field: GlobalKey()};
  final _contents = TextEditingController();
  final _declaredValue = TextEditingController();
  final _senderName = TextEditingController();
  final _senderPhone = TextEditingController();
  final _senderEmail = TextEditingController();
  final _receiverName = TextEditingController();
  final _receiverPhone = TextEditingController();
  final _emailFocus = FocusNode();

  late Destination _destination = widget.destination;
  ParcelSize? _size;
  String? _photoPath;
  DateTime? _photoTakenAt;
  bool _showEmail = false;
  Map<String, String> _errors = {};

  // stays the same until the details change, so a booking sent twice is only saved once
  String? _requestId;

  @override
  void initState() {
    super.initState();

    final previous = widget.sameSenderAs;

    if (previous != null) {
      _senderName.text = previous.senderName;
      _senderPhone.text = phoneAfterCode(previous.senderPhone);

      if (previous.senderEmail != null) {
        _showEmail = true;
        _senderEmail.text = previous.senderEmail!;
      }
    }
  }

  @override
  void dispose() {
    _emailFocus.dispose();

    for (final controller in [
      _contents,
      _declaredValue,
      _senderName,
      _senderPhone,
      _senderEmail,
      _receiverName,
      _receiverPhone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addEmail() {
    setState(() => _showEmail = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _emailFocus.requestFocus());
  }

  void _onFieldChanged(String field) {
    _requestId = null;

    if (_errors.containsKey(field)) {
      setState(() {
        _errors.remove(field);
      });
    }
  }

  void _pickSize(ParcelSize size) {
    _requestId = null;
    setState(() {
      _size = size;
      _errors.remove('size');
    });
  }

  Future<void> _changeTown() async {
    final picked = await Navigator.of(
      context,
    ).push<Destination>(MaterialPageRoute(builder: (_) => const ChooseTownScreen(pickOnly: true)));

    if (picked != null && mounted) {
      _requestId = null;
      setState(() {
        _destination = picked;
        _errors.remove('route_id');
      });
    }
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

    _requestId = null;
    setState(() {
      _photoPath = path;
      _photoTakenAt = DateTime.now();
      _errors.remove('photo');
    });
  }

  // a hidden email box counts as empty
  String get _email => _showEmail ? _senderEmail.text.trim() : '';

  void _showErrors(Map<String, String> errors) {
    // a copy, since the map can be the API's own and the fields remove from it as they change
    setState(() {
      _errors = Map.of(errors);
    });

    // after the messages are drawn, scroll to the first one
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firstField = _fieldOrder.where(errors.containsKey).firstOrNull;
      final target = firstField == null ? null : _fieldKeys[firstField]!.currentContext;

      if (target != null) {
        Scrollable.ensureVisible(
          target,
          alignment: 0.1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _checkDetails() async {
    FocusScope.of(context).unfocus();

    final errors = checkBooking(
      size: _size,
      contents: _contents.text,
      declaredValue: _declaredValue.text,
      senderName: _senderName.text,
      senderPhone: _senderPhone.text,
      senderEmail: _email,
      receiverName: _receiverName.text,
      receiverPhone: _receiverPhone.text,
      hasPhoto: _photoPath != null,
    );

    if (errors.isNotEmpty) {
      _showErrors(errors);
      return;
    }

    final parcel = NewParcel(
      destination: _destination,
      size: _size!,
      contents: tidySpaces(_contents.text),
      value: int.parse(_declaredValue.text.replaceAll(',', '')),
      senderName: tidySpaces(_senderName.text),
      senderPhone: normalizePhone(_senderPhone.text)!,
      senderEmail: _email.isEmpty ? null : _email,
      receiverName: tidySpaces(_receiverName.text),
      receiverPhone: normalizePhone(_receiverPhone.text)!,
      photoPath: _photoPath!,
    );
    final requestId = _requestId ??= ParcelService.newRequestId();

    final booked = await showPakitiSheet<BookedParcel>(
      context,
      builder: (_) => CheckDetailsSheet(
        parcel: parcel,
        requestId: requestId,
        onFieldErrors: _showErrors,
        service: widget.service,
      ),
    );

    if (booked != null && mounted) {
      _showParcelBooked(booked);
    }
  }

  // the form is swapped for Parcel booked, so going back from there skips the filled form
  void _showParcelBooked(BookedParcel parcel) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ParcelBookedScreen(parcel: parcel, onBookAnother: widget.onBookAnother),
      ),
      result: parcel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: const PageAppBar(title: 'Book a parcel'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormSection(
                    title: 'Going to',
                    children: [
                      DestinationCard(
                        key: _fieldKeys['route_id'],
                        destination: _destination,
                        error: _errors['route_id'],
                        onChange: _changeTown,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _buildParcelSection(),
                  const SizedBox(height: 28),
                  _buildSenderSection(),
                  const SizedBox(height: 28),
                  _buildReceiverSection(),
                  const SizedBox(height: 28),
                  FormSection(
                    title: 'Photo',
                    children: [
                      ParcelPhotoPicker(
                        key: _fieldKeys['photo'],
                        photoPath: _photoPath,
                        takenAt: _photoTakenAt,
                        error: _errors['photo'],
                        onTakePhoto: _takePhoto,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          BookingFeeBar(fee: size == null ? null : _destination.fees[size], onBook: _checkDetails),
        ],
      ),
    );
  }

  Widget _buildParcelSection() {
    return FormSection(
      title: 'Parcel',
      children: [
        SizePicker(
          key: _fieldKeys['size'],
          fees: _destination.fees,
          selected: _size,
          error: _errors['size'],
          onPick: _pickSize,
        ),
        const SizedBox(height: 16),
        BookingField(
          key: _fieldKeys['contents'],
          error: _errors['contents'],
          onChanged: () => _onFieldChanged('contents'),
          label: "What's inside",
          controller: _contents,
          capitalization: TextCapitalization.sentences,
          formatters: [LengthLimitingTextInputFormatter(255)],
        ),
        const SizedBox(height: 16),
        BookingField(
          key: _fieldKeys['declared_value'],
          error: _errors['declared_value'],
          onChanged: () => _onFieldChanged('declared_value'),
          label: 'Value',
          controller: _declaredValue,
          prefix: 'KSh',
          helper: "Used for claims if it's lost or damaged.",
          keyboardType: TextInputType.number,
          formatters: [AmountInputFormatter()],
        ),
      ],
    );
  }

  Widget _buildSenderSection() {
    return FormSection(
      title: 'Sender',
      children: [
        BookingField(
          key: _fieldKeys['sender_name'],
          error: _errors['sender_name'],
          onChanged: () => _onFieldChanged('sender_name'),
          label: "Sender's name",
          controller: _senderName,
          keyboardType: TextInputType.name,
          capitalization: TextCapitalization.words,
          formatters: [LengthLimitingTextInputFormatter(100)],
        ),
        const SizedBox(height: 16),
        BookingField(
          key: _fieldKeys['sender_phone'],
          error: _errors['sender_phone'],
          onChanged: () => _onFieldChanged('sender_phone'),
          label: "Sender's phone number",
          controller: _senderPhone,
          prefix: '+254',
          hint: '712 345 678',
          keyboardType: TextInputType.phone,
          formatters: [PhoneInputFormatter()],
        ),
        const SizedBox(height: 8),
        if (_showEmail)
          BookingField(
            key: _fieldKeys['sender_email'],
            error: _errors['sender_email'],
            onChanged: () => _onFieldChanged('sender_email'),
            label: "Sender's email",
            controller: _senderEmail,
            helper: 'For the booking receipt.',
            keyboardType: TextInputType.emailAddress,
            formatters: [LengthLimitingTextInputFormatter(254)],
            focusNode: _emailFocus,
          )
        else
          AddEmailButton(onPressed: _addEmail),
      ],
    );
  }

  Widget _buildReceiverSection() {
    return FormSection(
      title: 'Receiver',
      children: [
        BookingField(
          key: _fieldKeys['receiver_name'],
          error: _errors['receiver_name'],
          onChanged: () => _onFieldChanged('receiver_name'),
          label: "Receiver's name",
          controller: _receiverName,
          keyboardType: TextInputType.name,
          capitalization: TextCapitalization.words,
          formatters: [LengthLimitingTextInputFormatter(100)],
        ),
        const SizedBox(height: 16),
        BookingField(
          key: _fieldKeys['receiver_phone'],
          error: _errors['receiver_phone'],
          onChanged: () => _onFieldChanged('receiver_phone'),
          label: "Receiver's phone number",
          controller: _receiverPhone,
          prefix: '+254',
          hint: '712 345 678',
          helper: 'The collection code goes to this number.',
          keyboardType: TextInputType.phone,
          formatters: [PhoneInputFormatter()],
          action: TextInputAction.done,
        ),
      ],
    );
  }
}
