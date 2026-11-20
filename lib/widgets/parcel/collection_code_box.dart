import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/theme/app_theme.dart';

// On the Hand over screen. The box for the receiver's 6 numbers, with the link
// that sends them a code under it.
class CollectionCodeBox extends StatelessWidget {
  const CollectionCodeBox({
    super.key,
    required this.controller,
    required this.hint,
    required this.sendLabel,
    required this.onChanged,
    required this.onSend,
    this.error,
  });

  final TextEditingController controller;

  // the line under the box, like Ask Kevin for the 6 numbers.
  final String hint;
  final String? error;

  // Send a code, Send a new code, or Sending… while it goes
  final String sendLabel;

  final VoidCallback onChanged;

  // null while something is being sent
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Collection code',
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textInputAction: TextInputAction.done,
            onChanged: (_) => onChanged(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText,
            ),
            decoration: AppTheme.fieldDecoration(error: error).copyWith(
              helperText: hint,
              helperMaxLines: 2,
              helperStyle: const TextStyle(fontSize: 12, color: AppColors.grey),
              errorMaxLines: 2,
              errorStyle: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onSend,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.link,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            child: Text(sendLabel),
          ),
        ),
      ],
    );
  }
}
