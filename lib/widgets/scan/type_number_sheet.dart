import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/theme/app_theme.dart';
import 'package:pakiti_app/widgets/common/pakiti_sheet.dart';
import 'package:pakiti_app/widgets/form/field_label.dart';
import 'package:pakiti_app/widgets/form/field_prefix.dart';

// For a label the camera can't read. Gives back the tracking number, like PKT-460048,
// or null when the sheet is closed.
Future<String?> showTypeNumberSheet(BuildContext context, {required String action}) {
  return showPakitiSheet<String>(context, builder: (_) => _TypeNumberSheet(action: action));
}

class _TypeNumberSheet extends StatefulWidget {
  const _TypeNumberSheet({required this.action});

  // what the button says, like Load parcel
  final String action;

  @override
  State<_TypeNumberSheet> createState() => _TypeNumberSheetState();
}

class _TypeNumberSheetState extends State<_TypeNumberSheet> {
  final _numberController = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_numberController.text.length != 6) {
      setState(() => _error = 'Type the 6 numbers after PKT-');
      return;
    }

    Navigator.of(context).pop('PKT-${_numberController.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // keeps the sheet above the keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Type the tracking number',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "It's printed under the QR code on the label.",
                style: TextStyle(fontSize: 14, color: AppColors.grey),
              ),
              const SizedBox(height: 20),
              const FieldLabel('Tracking number'),
              const SizedBox(height: 8),
              TextField(
                controller: _numberController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) {
                  if (_error != null) {
                    setState(() => _error = null);
                  }
                },
                onSubmitted: (_) => _submit(),
                decoration: AppTheme.fieldDecoration(
                  hint: '460048',
                  prefix: const FieldPrefix('PKT-'),
                  error: _error,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _submit, child: Text(widget.action)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
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
}
