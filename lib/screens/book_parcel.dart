import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/booked_parcel.dart';
import '../models/destination.dart';
import '../models/new_parcel.dart';
import '../models/parcel_size.dart';
import '../services/parcel_service.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import '../utils/input_formatters.dart';
import '../utils/phone.dart';
import '../widgets/check_details_sheet.dart';
import 'choose_town.dart';

class BookParcelScreen extends StatefulWidget {
  const BookParcelScreen({super.key, required this.destination});

  final Destination destination;

  @override
  State<BookParcelScreen> createState() => _BookParcelScreenState();
}

class _BookParcelScreenState extends State<BookParcelScreen> {
  // same names the API uses, in the order they appear on the screen
  static const _fields = [
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

  static const _labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.darkText,
  );

  final _keys = {for (final field in _fields) field: GlobalKey()};
  final _contents = TextEditingController();
  final _value = TextEditingController();
  final _senderName = TextEditingController();
  final _senderPhone = TextEditingController();
  final _senderEmail = TextEditingController();
  final _receiverName = TextEditingController();
  final _receiverPhone = TextEditingController();

  late Destination _destination = widget.destination;
  ParcelSize? _size;
  XFile? _photo;
  DateTime? _photoTakenAt;
  bool _showEmail = false;
  Map<String, String> _errors = {};

  // stays the same until the details change, so a booking sent twice is only saved once
  String? _requestId;

  @override
  void dispose() {
    for (final controller in [
      _contents,
      _value,
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

  void _changed(String field) {
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
    final picked = await Navigator.of(context).push<Destination>(
      MaterialPageRoute(builder: (_) => const ChooseTownScreen(pickOnly: true)),
    );

    if (picked != null && mounted) {
      _requestId = null;
      setState(() {
        _destination = picked;
        _errors.remove('route_id');
      });
    }
  }

  Future<void> _takePhoto() async {
    XFile? photo;

    try {
      photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 80,
      );
    } on PlatformException {
      if (mounted) {
        _showMessage("The camera didn't open. Check that Pakiti is allowed to use it.");
      }
      return;
    }

    if (photo == null || !mounted) {
      return;
    }

    _requestId = null;
    setState(() {
      _photo = photo;
      _photoTakenAt = DateTime.now();
      _errors.remove('photo');
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _clean(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');

  // the same checks the API makes, so most mistakes are caught before sending
  Map<String, String> _validate() {
    final errors = <String, String>{};
    final email = _senderEmail.text.trim();

    if (_size == null) {
      errors['size'] = 'Choose the size of the parcel.';
    }
    if (_clean(_contents.text).length < 2) {
      errors['contents'] = "Say what's inside the parcel.";
    }
    if (int.tryParse(_value.text.replaceAll(',', '')) == null) {
      errors['declared_value'] = 'Enter the value in shillings.';
    }
    if (_clean(_senderName.text).length < 2) {
      errors['sender_name'] = "Enter the sender's name.";
    }
    if (_senderPhone.text.isEmpty) {
      errors['sender_phone'] = "Enter the sender's phone number.";
    } else if (normalizePhone(_senderPhone.text) == null) {
      errors['sender_phone'] = "Check the sender's phone number.";
    }
    if (_showEmail &&
        email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      errors['sender_email'] = 'Check the email address.';
    }
    if (_clean(_receiverName.text).length < 2) {
      errors['receiver_name'] = "Enter the receiver's name.";
    }
    if (_receiverPhone.text.isEmpty) {
      errors['receiver_phone'] = "Enter the receiver's phone number.";
    } else if (normalizePhone(_receiverPhone.text) == null) {
      errors['receiver_phone'] = "Check the receiver's phone number.";
    }
    if (_photo == null) {
      errors['photo'] = 'Take a photo of the parcel before booking.';
    }

    return errors;
  }

  void _showErrors(Map<String, String> errors) {
    setState(() {
      _errors = errors;
    });

    // after the messages are drawn, scroll to the first one
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final first = _fields.where(errors.containsKey).firstOrNull;
      final target = first == null ? null : _keys[first]!.currentContext;

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

  Future<void> _review() async {
    FocusScope.of(context).unfocus();

    final errors = _validate();

    if (errors.isNotEmpty) {
      _showErrors(errors);
      return;
    }

    final email = _senderEmail.text.trim();
    final parcel = NewParcel(
      destination: _destination,
      size: _size!,
      contents: _clean(_contents.text),
      value: int.parse(_value.text.replaceAll(',', '')),
      senderName: _clean(_senderName.text),
      senderPhone: normalizePhone(_senderPhone.text)!,
      senderEmail: _showEmail && email.isNotEmpty ? email : null,
      receiverName: _clean(_receiverName.text),
      receiverPhone: normalizePhone(_receiverPhone.text)!,
      photoPath: _photo!.path,
    );
    final requestId = _requestId ??= ParcelService.newRequestId();

    final booked = await showModalBottomSheet<BookedParcel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      elevation: 0,
      barrierColor: const Color(0x800F1B2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CheckDetailsSheet(
        parcel: parcel,
        requestId: requestId,
        onFieldErrors: _showErrors,
      ),
    );

    if (booked != null && mounted) {
      _finish(booked);
    }
  }

  // for now this goes back home; the Parcel booked screen comes in the next step
  void _finish(BookedParcel parcel) {
    final messenger = ScaffoldMessenger.of(context);

    Navigator.of(context).popUntil((route) => route.isFirst);
    messenger.showSnackBar(
      SnackBar(content: Text('${parcel.trackingNo} is booked.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 4,
        title: const Text(
          'Book a parcel',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection('Going to', [
                    _keyed('route_id', _buildGoingTo()),
                  ]),
                  const SizedBox(height: 28),
                  _buildSection('Parcel', [
                    _keyed('size', _buildSizes()),
                    const SizedBox(height: 16),
                    _buildField(
                      field: 'contents',
                      label: "What's inside",
                      controller: _contents,
                      capitalization: TextCapitalization.sentences,
                      formatters: [LengthLimitingTextInputFormatter(255)],
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      field: 'declared_value',
                      label: 'Value',
                      controller: _value,
                      prefix: 'KSh',
                      helper: "Used for claims if it's lost or damaged.",
                      keyboardType: TextInputType.number,
                      formatters: [AmountInputFormatter()],
                    ),
                  ]),
                  const SizedBox(height: 28),
                  _buildSection('Sender', [
                    _buildField(
                      field: 'sender_name',
                      label: "Sender's name",
                      controller: _senderName,
                      keyboardType: TextInputType.name,
                      capitalization: TextCapitalization.words,
                      formatters: [LengthLimitingTextInputFormatter(100)],
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      field: 'sender_phone',
                      label: "Sender's phone number",
                      controller: _senderPhone,
                      prefix: '+254',
                      hint: '712 345 678',
                      keyboardType: TextInputType.phone,
                      formatters: [PhoneInputFormatter()],
                    ),
                    const SizedBox(height: 8),
                    if (_showEmail)
                      _buildField(
                        field: 'sender_email',
                        label: "Sender's email",
                        controller: _senderEmail,
                        helper: 'For the booking receipt.',
                        keyboardType: TextInputType.emailAddress,
                        formatters: [LengthLimitingTextInputFormatter(254)],
                        autofocus: true,
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showEmail = true),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add email for a receipt'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.link,
                            minimumSize: const Size(0, 44),
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 28),
                  _buildSection('Receiver', [
                    _buildField(
                      field: 'receiver_name',
                      label: "Receiver's name",
                      controller: _receiverName,
                      keyboardType: TextInputType.name,
                      capitalization: TextCapitalization.words,
                      formatters: [LengthLimitingTextInputFormatter(100)],
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      field: 'receiver_phone',
                      label: "Receiver's phone number",
                      controller: _receiverPhone,
                      prefix: '+254',
                      hint: '712 345 678',
                      helper: 'The collection code goes to this number.',
                      keyboardType: TextInputType.phone,
                      formatters: [PhoneInputFormatter()],
                      action: TextInputAction.done,
                    ),
                  ]),
                  const SizedBox(height: 28),
                  _buildSection('Photo', [
                    _keyed('photo', _buildPhoto()),
                  ]),
                ],
              ),
            ),
          ),
          _buildFeeBar(),
        ],
      ),
    );
  }

  Widget _keyed(String field, Widget child) {
    return KeyedSubtree(key: _keys[field], child: child);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildFieldError(String field) {
    final error = _errors[field];

    if (error == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Semantics(
        liveRegion: true,
        child: Text(
          error,
          style: const TextStyle(fontSize: 12, color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildGoingTo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: _errors.containsKey('route_id')
                ? Border.all(color: AppColors.error, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.statusOnTheWayBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _destination.town,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    Text(
                      '${_destination.county} County',
                      style: const TextStyle(fontSize: 13, color: AppColors.grey),
                    ),
                    Text(
                      travelTime(_destination.minutes),
                      style: const TextStyle(fontSize: 13, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _changeTown,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.link,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('Change'),
              ),
            ],
          ),
        ),
        _buildFieldError('route_id'),
      ],
    );
  }

  Widget _buildSizes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Size', style: _labelStyle),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final size in ParcelSize.values) ...[
                if (size != ParcelSize.values.first) const SizedBox(width: 8),
                Expanded(child: _buildSizeTile(size)),
              ],
            ],
          ),
        ),
        _buildFieldError('size'),
      ],
    );
  }

  Widget _buildSizeTile(ParcelSize size) {
    final selected = _size == size;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: selected
            ? AppColors.navy
            : _errors.containsKey('size')
                ? AppColors.error
                : AppColors.border,
        width: selected ? 2.5 : 1.5,
      ),
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? AppColors.statusOnTheWayBg : Colors.white,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: () => _pickSize(size),
            child: Padding(
              // the thicker border takes 1 px, so the text does not move when picked
              padding: EdgeInsets.all(selected ? 11 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    size.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  Text(
                    size.hint,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  const Spacer(),
                  const SizedBox(height: 6),
                  Text(
                    ksh(_destination.fees[size]!),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String field,
    required String label,
    required TextEditingController controller,
    String? prefix,
    String? hint,
    String? helper,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    TextInputAction action = TextInputAction.next,
    bool autofocus = false,
  }) {
    OutlineInputBorder border(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return _keyed(
      field,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: _labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            textInputAction: action,
            inputFormatters: formatters,
            autofocus: autofocus,
            onChanged: (_) => _changed(field),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.grey),
              prefixIcon: prefix == null ? null : _buildPrefix(prefix),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              helperText: helper,
              helperMaxLines: 2,
              helperStyle: const TextStyle(fontSize: 12, color: AppColors.grey),
              errorText: _errors[field],
              errorMaxLines: 2,
              errorStyle: const TextStyle(fontSize: 12, color: AppColors.error),
              enabledBorder: border(AppColors.border, 1.5),
              focusedBorder: border(AppColors.link, 2),
              errorBorder: border(AppColors.error, 1.5),
              focusedErrorBorder: border(AppColors.error, 2),
            ),
          ),
        ],
      ),
    );
  }

  // the KSh or +254 in front of a field, with a line after it
  Widget _buildPrefix(String text) {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.divider, width: 1.5)),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    final photo = _photo;
    final hasError = _errors.containsKey('photo');
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: hasError ? AppColors.error : AppColors.border,
        width: 1.5,
      ),
    );

    if (photo == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.white,
            shape: shape,
            child: InkWell(
              customBorder: shape,
              onTap: _takePhoto,
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
          _buildFieldError('photo'),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: ShapeDecoration(color: Colors.white, shape: shape),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(photo.path),
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
                if (_photoTakenAt != null)
                  Text(
                    'Taken at ${clockTime(_photoTakenAt!)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _takePhoto,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.link,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            child: const Text('Retake'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeBar() {
    final size = _size;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Row(
            children: [
              // the fee shows once a size is picked, since it depends on the size
              if (size != null) ...[
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fee',
                      style: TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                    Text(
                      ksh(_destination.fees[size]!),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: _review,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Book parcel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}