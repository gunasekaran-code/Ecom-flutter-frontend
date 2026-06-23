import 'package:flutter/material.dart';
import 'package:wss_sports/auth/pages/login_page.dart' show LoginPage;
import 'package:wss_sports/services/api_service.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  bool resetEmailSent = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetRequest() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address.', Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiService.forgotPassword(email: email);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result['success'] == true) {
      setState(() => resetEmailSent = true);
      _showSnackBar(
        'Verification email sent. Please check your Gmail.',
        kBrandRed,
      );
    } else {
      _showSnackBar(
        (result['error'] ?? 'Unable to send reset request.').toString(),
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    showAppSnackBar(
      context,
      title: color == Colors.red ? 'Error' : 'Alert',
      message: message,
      type: color == Colors.red ? AppSnackBarType.error : AppSnackBarType.alert,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      title: 'Forgot Password',
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
                  Icons.mark_email_unread_outlined,
                  size: 44,
                  color: kBrandRed,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Forgot Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                resetEmailSent
                    ? 'Open the verification link from Gmail to reset your password.'
                    : 'Enter your email to continue.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withOpacity(0.55),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GlassTextField(
                hintText: 'Email',
                icon: Icons.email_outlined,
                controller: emailController,
              ),
              if (resetEmailSent) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kBrandRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBrandRed.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hourglass_top_rounded,
                        color: kBrandRed,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Waiting for Gmail verification. The reset page opens only from the email link.',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.65),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                  onPressed: isLoading ? null : _sendResetRequest,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SEND',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      ),
                child: const Text(
                  'Back to login',
                  style: TextStyle(
                    color: kBrandRed,
                    fontWeight: FontWeight.bold,
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
