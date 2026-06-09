import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ecom_app/core/localization/app_strings.dart';
import 'package:ecom_app/auth/pages/forgot_password.dart';
import 'package:ecom_app/auth/pages/register_page.dart';
import 'package:ecom_app/shared/widgets/shared_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ecom_app/services/api_service.dart';
import 'package:ecom_app/services/google_auth_service.dart';
import 'package:ecom_app/shared/widgets/navbar.dart';
// import 'package:ecom_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:universal_html/html.dart' as html;

const Color kBrandRed = Color(0xFFE4252A);
const Color kBrandRedSoft = Color(0xFFFFE5E6);
const Color kBgLight = Color(0xFFFDF7F7);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool isLoading = false;

  static const String _demoEmail = 'guna@gmail.com';
  static const String _demoPassword = '123456';
  static const String _demoName = 'Guna Sekaran V';

  @override
  void initState() {
    super.initState();
    // emailController.text = _demoEmail;
    // passwordController.text = _demoPassword;
    if (kIsWeb) _renderGoogleButton();
  }

  void _renderGoogleButton() {
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        final container = html.document.getElementById('google-signin-button');
        if (container != null) {
          debugPrint('Google Sign-In button container ready');
        }
      } catch (e) {
        debugPrint('Error setting up Google button: $e');
      }
    });
  }

  void handleLogin() async {
    final strings = context.strings;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email == _demoEmail && password == _demoPassword) {
      setState(() => isLoading = false);
      _showSnackBar(strings.welcomeBackToast, kBrandRed);
      final userData = {
        'id': 1,
        'name': _demoName,
        'email': _demoEmail,
      };
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserHomePage(userData: userData),
        ),
      );
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(strings.pleaseEnterEmailPassword, Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.loginUserWithWakeUp(
        email: email,
        password: password,
      );

      setState(() => isLoading = false);

      if (result['success'] == true) {
        _showSnackBar(strings.welcomeBackToast, kBrandRed);

        final data = (result['data'] as Map<String, dynamic>?) ?? {};
        final userData = (data['user'] is Map<String, dynamic>)
            ? (data['user'] as Map<String, dynamic>)
            : data;

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserHomePage(userData: userData),
          ),
        );
      } else {
        final errorText = (result['error'] ?? strings.loginFailed).toString();
        final serverError = errorText.toLowerCase();

        if (serverError.contains('doctype html')) {
          _showSnackBar(strings.serverDatabaseError, Colors.red);
          return;
        }

        if (serverError.contains('email') || serverError.contains('not found')) {
          _showSnackBar(strings.emailNotRegistered, Colors.blueGrey);
        } else if (serverError.contains('password') ||
            serverError.contains('credentials')) {
          _showSnackBar(strings.incorrectPassword, Colors.redAccent);
        } else {
          _showSnackBar(errorText, Colors.red);
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Login Error: $e");
      _showSnackBar(strings.connectionFailed, Colors.red);
    }
  }

  Future<void> handleGoogleSignIn() async {
    if (isLoading) return; // Prevent multiple calls
    final strings = context.strings;
    setState(() => isLoading = true);
    try {
      final result = await _googleAuthService.signInWithGoogle();
      if (result != null && mounted) {
        debugPrint('[GOOGLE LOGIN] user data: $result');
        debugPrint('[GOOGLE LOGIN] backend id: ${result['id']}');
        debugPrint('[GOOGLE LOGIN] google id: ${result['google_id']}');
        debugPrint('[GOOGLE LOGIN] redirecting to: UserHomePage');
        _showSnackBar(strings.googleSignInSuccess, kBrandRed);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserHomePage(userData: result),
          ),
        );
      } else if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar(strings.googleSignInCancelled, Colors.orange);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar(strings.googleSignInError(e.toString()), Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return GlassScaffold(
      title: strings.login,
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
                  color: kBrandRed.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 44,
                  color: kBrandRed,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.welcomeBack,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.signInToContinue,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 32),

              GlassTextField(
                hintText: strings.email,
                icon: Icons.email_outlined,
                controller: emailController,
              ),
              const SizedBox(height: 16),
              GlassTextField(
                hintText: strings.password,
                icon: Icons.lock_outline,
                isPassword: true,
                controller: passwordController,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: kBrandRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
                    shadowColor: kBrandRed.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : handleLogin,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          strings.loginUppercase,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.black.withValues(alpha: 0.15)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      strings.orLabel,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.black.withValues(alpha: 0.15)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: BorderSide(
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading ? null : handleGoogleSignIn,
                  icon: SvgPicture.network(
                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                    height: 22,
                  ),
                  label: Text(
                    strings.signInWithGoogle,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    strings.noAccountQuestion,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.65),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    ),
                    child: Text(
                      strings.register,
                      style: TextStyle(
                        color: kBrandRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
