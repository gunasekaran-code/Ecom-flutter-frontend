import 'package:flutter/material.dart';

import 'package:wss_sports/auth/pages/login_page.dart' show LoginPage;
import 'package:wss_sports/services/api_service.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String token;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final TextEditingController emailController;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmationPassword = confirmPasswordController.text.trim();

    if (widget.token.isEmpty) {
      _showSnackBar('Invalid or expired reset link.', Colors.red);
      return;
    }

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address.', Colors.orange);
      return;
    }

    if (password.isEmpty || confirmationPassword.isEmpty) {
      _showSnackBar('Please enter and confirm your password.', Colors.orange);
      return;
    }

    if (password != confirmationPassword) {
      _showSnackBar('Passwords do not match.', Colors.redAccent);
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiService.resetPassword(
      token: widget.token,
      email: email,
      password: password,
      passwordConfirmation: confirmationPassword,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result['success'] == true) {
      _showSnackBar('Password changed successfully. Please login.', kBrandRed);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } else {
      _showSnackBar(
        (result['error'] ?? 'Unable to change password.').toString(),
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    showAppSnackBar(
      context,
      title: _snackBarTitle(color),
      message: message,
      type: _snackBarType(color),
    );
  }

  AppSnackBarType _snackBarType(Color color) {
    if (color == Colors.red || color == Colors.redAccent) {
      return AppSnackBarType.error;
    }
    if (color == Colors.orange) return AppSnackBarType.alert;
    if (color == kBrandRed) return AppSnackBarType.success;
    return AppSnackBarType.info;
  }

  String _snackBarTitle(Color color) {
    final type = _snackBarType(color);
    return switch (type) {
      AppSnackBarType.success => 'Success',
      AppSnackBarType.error => 'Error',
      AppSnackBarType.alert => 'Alert',
      AppSnackBarType.info => 'Info',
    };
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      title: 'Change Password',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kBrandRed.withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 44,
                  color: kBrandRed,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.email.isEmpty)
                Text(
                  'Enter your email and new password.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black.withOpacity(0.55),
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  widget.email,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              const SizedBox(height: 32),
              if (widget.email.isEmpty) ...[
                GlassTextField(
                  hintText: 'Email',
                  icon: Icons.email_outlined,
                  controller: emailController,
                ),
                const SizedBox(height: 16),
              ],
              GlassTextField(
                hintText: 'Password',
                icon: Icons.lock_outline,
                isPassword: true,
                controller: passwordController,
              ),
              const SizedBox(height: 16),
              GlassTextField(
                hintText: 'Confirmation password',
                icon: Icons.lock_person_outlined,
                isPassword: true,
                controller: confirmPasswordController,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandRed,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: kBrandRed.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : _changePassword,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'CHANGE PASSWORD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
