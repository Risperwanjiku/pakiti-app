import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    FocusScope.of(context).unfocus();
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBrand(),
          const SizedBox(height: 32),
          AspectRatio(
            aspectRatio: 342 / 120,
            child: SvgPicture.asset('assets/images/matatu.svg'),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: const Text(
            'P',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pakiti',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Sacco parcel tracking',
              style: TextStyle(
                color: AppColors.lightBlue,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
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
              'Sign in',
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
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
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
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signIn(),
              decoration: AppTheme.fieldDecoration(
                hint: 'Enter your password',
                suffix: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
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
                onPressed: () {},
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
              onPressed: _signIn,
              child: const Text('Sign in'),
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