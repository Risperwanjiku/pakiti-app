import 'package:flutter/material.dart';

import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/auth_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/common/busy_label.dart';
import 'package:pakiti_app/widgets/common/page_app_bar.dart';
import 'package:pakiti_app/widgets/form/field_label.dart';
import 'package:pakiti_app/widgets/form/password_field.dart';

// Opened from Profile. Closes with true once the new password is saved.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.auth});

  // tests pass in a fake one
  final AuthService? auth;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final AuthService _authService = widget.auth ?? AuthService();

  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _saving = false;

  // what the API found wrong, by field name like 'current_password'
  Map<String, String> _serverErrors = const {};

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    return (value ?? '').isEmpty ? 'Enter your current password.' : null;
  }

  // The length and space rules match NewPassword in the API.
  // Only the API checks whether it is too easy to guess or is the clerk's phone number.
  String? _validateNewPassword(String? value) {
    final password = value ?? '';

    // runes, so é counts as one character like it does in the API
    final length = password.runes.length;

    if (password.isEmpty) {
      return 'Enter a new password.';
    }
    if (password.trim() != password) {
      return 'Take out the space at the start or end.';
    }
    if (length < 8) {
      return 'Use at least 8 characters.';
    }
    if (length > 64) {
      return 'Use 64 characters or fewer.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Type the new password again.';
    }
    if (value != _newPasswordController.text) {
      return "This doesn't match the new password.";
    }
    return null;
  }

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() {
        _serverErrors = Map.of(_serverErrors)..remove(field);
      });
    }
  }

  Future<void> _save() async {
    setState(() => _serverErrors = const {});

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      await _authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _serverErrors = Map.of(error.fieldErrors);
      });

      // a field error already shows under its field
      if (error.fieldErrors.isEmpty) {
        showApiError(context, error);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // going back halfway through would leave the clerk not knowing which password works
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: AppColors.page,
        appBar: const PageAppBar(title: 'Change password'),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Choose a password only you know.',
                        style: TextStyle(fontSize: 14, color: AppColors.grey),
                      ),
                      const SizedBox(height: 20),
                      const FieldLabel('Current password'),
                      const SizedBox(height: 8),
                      PasswordField(
                        controller: _currentPasswordController,
                        enabled: !_saving,
                        validator: _validateCurrentPassword,
                        error: _serverErrors['current_password'],
                        onChanged: (_) => _clearServerError('current_password'),
                        // typing is all there is to do here, so the keyboard comes straight up
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel('New password'),
                      const SizedBox(height: 8),
                      PasswordField(
                        controller: _newPasswordController,
                        enabled: !_saving,
                        validator: _validateNewPassword,
                        error: _serverErrors['new_password'],
                        onChanged: (_) => _clearServerError('new_password'),
                        helper: 'At least 8 characters. A short phrase is easy to remember.',
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel('Confirm new password'),
                      const SizedBox(height: 8),
                      PasswordField(
                        controller: _confirmPasswordController,
                        enabled: !_saving,
                        validator: _validateConfirmation,
                        action: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildSaveBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const BusyLabel('Saving…') : const Text('Save new password'),
          ),
        ),
      ),
    );
  }
}
