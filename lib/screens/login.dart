import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/staff_user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'clerk_home.dart';

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

  bool _hidePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _localNumber(String value) {
    final digits = value.trim();
    return digits.startsWith('0') ? digits.substring(1) : digits;
  }

  String? _validatePhone(String? value) {
    final number = _localNumber(value ?? '');
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

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    final phone = '+254${_localNumber(_phoneController.text)}';

    try {
      final user = await _authService.login(phone, _passwordController.text);

      if (!mounted) return;

      if (user.role != StaffRole.clerk) {
        setState(() => _loading = false);
        _showMessage('Only the clerk screens are ready for now.');
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ClerkHomeScreen(user: user)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        if (e.statusCode == 401) {
          _error = e.message;
        }
      });

      if (e.statusCode != 401) {
        _showMessage(e.message);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
              'Sign in to Pakiti',
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
            _buildLabel('Phone number'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              enabled: !_loading,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: _validatePhone,
              decoration: AppTheme.fieldDecoration(
                hint: '712 345 678',
                prefix: _buildPhonePrefix(),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              enabled: !_loading,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              validator: _validatePassword,
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
              onFieldSubmitted: (_) => _signIn(),
              decoration: AppTheme.fieldDecoration(
                hint: 'Enter your password',
                error: _error,
                suffix: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  onPressed: _loading
                      ? null
                      : () {
                          setState(() => _hidePassword = !_hidePassword);
                        },
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading ? null : () {},
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
              onPressed: _loading ? null : _signIn,
              child: _loading
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
                        Text('Signing in…'),
                      ],
                    )
                  : const Text('Sign in'),
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

  Widget _buildPhonePrefix() {
    return const Padding(
      padding: EdgeInsets.only(left: 16, right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+254',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(width: 12),
          SizedBox(
            height: 24,
            child: VerticalDivider(
              width: 1,
              thickness: 1.5,
              color: AppColors.divider,
            ),
          ),
        ],
      ),
    );
  }
}