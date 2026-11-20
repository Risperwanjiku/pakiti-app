import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/widgets/form/field_label.dart';

// a labelled text field on the booking form, with an optional KSh or +254 in front
class BookingField extends StatelessWidget {
  const BookingField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.error,
    this.prefix,
    this.hint,
    this.helper,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.formatters,
    this.action = TextInputAction.next,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? error;
  final String? prefix;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? formatters;
  final TextInputAction action;
  final FocusNode? focusNode;

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefix = this.prefix;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          textInputAction: action,
          inputFormatters: formatters,
          focusNode: focusNode,
          onChanged: (_) => onChanged(),
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
            errorText: error,
            errorMaxLines: 2,
            errorStyle: const TextStyle(fontSize: 12, color: AppColors.error),
            enabledBorder: _border(AppColors.border, 1.5),
            focusedBorder: _border(AppColors.link, 2),
            errorBorder: _border(AppColors.error, 1.5),
            focusedErrorBorder: _border(AppColors.error, 2),
          ),
        ),
      ],
    );
  }

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
}
