import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';

// The search box on Home, Search and Where is it going?. Compact is the smaller grey one
// that sits in the top bar of the Search screen.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.focusNode,
    this.autofocus = false,
    this.capitalization = TextCapitalization.none,
    this.compact = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  // shows a clear button while there is text, when given
  final VoidCallback? onClear;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextCapitalization capitalization;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final onClear = this.onClear;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      textCapitalization: capitalization,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.darkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontWeight: FontWeight.w400, color: AppColors.grey),
        prefixIcon: const Icon(Icons.search, color: AppColors.grey),
        suffixIcon: onClear == null || controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(Icons.close, color: AppColors.grey),
              ),
        filled: true,
        fillColor: compact ? AppColors.page : Colors.white,
        isDense: compact,
        contentPadding: EdgeInsets.symmetric(vertical: compact ? 12 : 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.link, width: 2),
        ),
      ),
    );
  }
}
