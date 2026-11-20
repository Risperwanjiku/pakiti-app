import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:pakiti_app/screens/account/start_screen.dart';
import 'package:pakiti_app/services/api_client.dart';
import 'package:pakiti_app/services/auth_service.dart';
import 'package:pakiti_app/theme/app_colors.dart';
import 'package:pakiti_app/theme/app_theme.dart';
import 'package:pakiti_app/utils/messages.dart';
import 'package:pakiti_app/widgets/account/forgot_password_sheet.dart';
import 'package:pakiti_app/widgets/common/busy_label.dart';
import 'package:pakiti_app/widgets/form/field_label.dart';
import 'package:pakiti_app/widgets/form/field_prefix.dart';
import 'package:pakiti_app/widgets/form/password_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _loggingIn = false;

  // a wrong phone or password, shown under the password box
  String? _passwordError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // the box already shows +254, so a leading 0 is dropped
  String _numberAfterCode(String value) {
    final number = value.trim();
    return number.startsWith('0') ? number.substring(1) : number;
  }

  String? _validatePhone(String? value) {
    final number = _numberAfterCode(value ?? '');
    if (number.isEmpty) {
      return 'Enter your phone number';
    }
    if (!RegExp(r'^[17]\d{8}$').hasMatch(number)) {
      return 'Enter a valid number, like 712 345 678';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your password';
    }
    return null;
  }

  Future<void> _logIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _passwordError = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loggingIn = true);

    final phone = '+254${_numberAfterCode(_phoneController.text)}';

    try {
      final user = await _authService.login(phone, _passwordController.text);

      if (!mounted) return;

      final tabs = tabsFor(user);

      if (tabs == null) {
        setState(() => _loggingIn = false);
        showMessage(context, 'The admin screens are not ready yet.');
        return;
      }

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => tabs));
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _loggingIn = false;
        if (error.statusCode == 401) {
          _passwordError = error.message;
        }
      });

      if (error.statusCode != 401) {
        showMessage(context, error.message);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => _loggingIn = false);
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        Expanded(child: _buildForm(bottomInset)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: AspectRatio(
        aspectRatio: 342 / 120,
        child: SvgPicture.asset('assets/images/matatu.svg'),
      ),
    );
  }

  Widget _buildForm(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Log in to Pakiti',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use your registered phone number.',
              style: TextStyle(fontSize: 16, color: AppColors.grey),
            ),
            const SizedBox(height: 24),
            const FieldLabel('Phone number'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              enabled: !_loggingIn,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: _validatePhone,
              decoration: AppTheme.fieldDecoration(
                hint: '712 345 678',
                prefix: const FieldPrefix('+254'),
              ),
            ),
            const SizedBox(height: 16),
            const FieldLabel('Password'),
            const SizedBox(height: 8),
            _buildPasswordField(),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loggingIn ? null : () => showForgotPasswordSheet(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.link,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loggingIn ? null : _logIn,
              child: _loggingIn ? const BusyLabel('Logging in…') : const Text('Log in'),
            ),
            const SizedBox(height: 24),
            const Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 14, color: AppColors.grey),
                children: [
                  TextSpan(
                    text: 'New staff? ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  TextSpan(text: 'Ask your admin for an account.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return PasswordField(
      controller: _passwordController,
      enabled: !_loggingIn,
      validator: _validatePassword,
      hint: 'Enter your password',
      error: _passwordError,
      action: TextInputAction.done,
      onChanged: (_) {
        if (_passwordError != null) {
          setState(() => _passwordError = null);
        }
      },
      onSubmitted: (_) => _logIn(),
    );
  }
}
