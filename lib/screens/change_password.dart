import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'login.dart';

// Opened from Profile. Closes with true once the new password is saved.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.auth});

  // tests pass in a fake one
  final AuthService? auth;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final AuthService _auth = widget.auth ?? AuthService();

  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _againController = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideAgain = true;
  bool _saving = false;

  // what the API found wrong, by field name like 'current_password'
  Map<String, String> _serverErrors = const {};

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _againController.dispose();
    super.dispose();
  }

  String? _checkCurrent(String? value) {
    return (value ?? '').isEmpty ? 'Enter your current password.' : null;
  }

  // The length and space rules match NewPassword in the API.
  // Only the API checks whether it is too easy to guess or is the clerk's phone number.
  String? _checkNew(String? value) {
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

  String? _checkAgain(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Type the new password again.';
    }
    if (value != _newController.text) {
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
      await _auth.changePassword(_currentController.text, _newController.text);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _serverErrors = e.fieldErrors;
      });

      // a field error already shows under its field
      if (e.fieldErrors.isEmpty) {
        _showProblem(e);
      }
    }
  }

  void _showProblem(ApiException error) {
    final sessionEnded = error.statusCode == 401;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: sessionEnded
              ? SnackBarAction(label: 'Log in again', onPressed: _goToLogin)
              : null,
        ),
      );
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // going back halfway through would leave the clerk not knowing which password works
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: AppColors.page,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          scrolledUnderElevation: 0,
          titleSpacing: 4,
          title: const Text(
            'Change password',
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
                      _buildLabel('Current password'),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _currentController,
                        hidden: _hideCurrent,
                        onToggle: () {
                          setState(() => _hideCurrent = !_hideCurrent);
                        },
                        validator: _checkCurrent,
                        error: _serverErrors['current_password'],
                        onChanged: (_) => _clearServerError('current_password'),
                        // typing is all there is to do here, so the keyboard comes straight up
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('New password'),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _newController,
                        hidden: _hideNew,
                        onToggle: () {
                          setState(() => _hideNew = !_hideNew);
                        },
                        validator: _checkNew,
                        error: _serverErrors['new_password'],
                        onChanged: (_) => _clearServerError('new_password'),
                        helper: 'At least 8 characters. A short phrase is easy to remember.',
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Confirm new password'),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _againController,
                        hidden: _hideAgain,
                        onToggle: () {
                          setState(() => _hideAgain = !_hideAgain);
                        },
                        validator: _checkAgain,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool hidden,
    required VoidCallback onToggle,
    required FormFieldValidator<String> validator,
    String? error,
    String? helper,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    TextInputAction action = TextInputAction.next,
    bool autofocus = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      obscureText: hidden,
      // keyboards like to fix words, which would quietly change a passphrase
      autocorrect: false,
      enableSuggestions: false,
      autofocus: autofocus,
      textInputAction: action,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      decoration: AppTheme.fieldDecoration(
        error: error,
        // left out of Next, so the keyboard's Next key goes to the next box and not to the eye
        suffix: ExcludeFocusTraversal(
          child: IconButton(
            tooltip: hidden ? 'Show password' : 'Hide password',
            onPressed: _saving ? null : onToggle,
            icon: Icon(
              hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.grey,
            ),
          ),
        ),
      ).copyWith(
        helperText: helper,
        helperMaxLines: 2,
        helperStyle: const TextStyle(fontSize: 12, color: AppColors.grey),
        errorMaxLines: 2,
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
            child: _saving
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Saving…'),
                    ],
                  )
                : const Text('Save new password'),
          ),
        ),
      ),
    );
  }
}