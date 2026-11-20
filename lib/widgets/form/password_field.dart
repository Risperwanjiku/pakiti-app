import 'package:flutter/material.dart';

import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/theme/app_theme.dart';

// a password box with an eye to show or hide what was typed
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.validator,
    this.enabled = true,
    this.error,
    this.hint,
    this.helper,
    this.onChanged,
    this.onSubmitted,
    this.action = TextInputAction.next,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final bool enabled;

  // from the server, shown under the box
  final String? error;
  final String? hint;
  final String? helper;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction action;
  final bool autofocus;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _hidden,
      // keyboards like to fix words, which would quietly change a passphrase
      autocorrect: false,
      enableSuggestions: false,
      autofocus: widget.autofocus,
      textInputAction: widget.action,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      decoration:
          AppTheme.fieldDecoration(
            hint: widget.hint,
            error: widget.error,
            // left out of Next, so the keyboard's Next key goes to the next box and not to the eye
            suffix: ExcludeFocusTraversal(
              child: IconButton(
                tooltip: _hidden ? 'Show password' : 'Hide password',
                onPressed: widget.enabled ? () => setState(() => _hidden = !_hidden) : null,
                icon: Icon(
                  _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.grey,
                ),
              ),
            ),
          ).copyWith(
            helperText: widget.helper,
            helperMaxLines: 2,
            helperStyle: const TextStyle(fontSize: 12, color: AppColors.grey),
            errorMaxLines: 2,
          ),
    );
  }
}
