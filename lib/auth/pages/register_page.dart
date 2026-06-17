import 'package:flutter/material.dart';
import 'package:wss_sports/core/localization/app_strings.dart';
import 'package:wss_sports/auth/pages/login_page.dart';
import 'package:wss_sports/shared/widgets/shared_ui.dart';
import 'package:wss_sports/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;
  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  // Email validation regex
  final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Username validation regex (3-20 chars, letters, numbers, underscore only)
  final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? validateName(String value) {
    final strings = context.strings;
    if (value.isEmpty) {
      return strings.nameRequired;
    }

    if (value.contains(' ')) {
      return strings.spacesNotAllowed;
    }

    if (value.length < 3) {
      return strings.nameMinChars;
    }

    if (value.length > 20) {
      return strings.nameMaxChars;
    }

    if (!usernameRegex.hasMatch(value)) {
      return strings.usernameAllowedChars;
    }

    return null;
  }

  String? validateEmail(String value) {
    final strings = context.strings;
    if (value.isEmpty) {
      return strings.emailRequired;
    }

    if (!emailRegex.hasMatch(value)) {
      return strings.emailInvalid;
    }

    return null;
  }

  String? validatePassword(String value) {
    final strings = context.strings;
    if (value.isEmpty) {
      return strings.passwordRequired;
    }

    return null;
  }

  String? validateConfirmPassword(String value) {
    final strings = context.strings;
    if (value.isEmpty) {
      return strings.confirmPasswordRequired;
    }

    if (value != passwordController.text.trim()) {
      return strings.passwordsDoNotMatch;
    }

    return null;
  }

  void handleRegister() async {
    final strings = context.strings;
    // Clear previous errors
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;
    });

    // Validate all fields
    final nameValidation = validateName(nameController.text.trim());
    final emailValidation = validateEmail(emailController.text.trim());
    final passwordValidation = validatePassword(passwordController.text.trim());
    final confirmPasswordValidation = validateConfirmPassword(
      confirmPasswordController.text.trim(),
    );

    if (nameValidation != null ||
        emailValidation != null ||
        passwordValidation != null ||
        confirmPasswordValidation != null) {
      setState(() {
        nameError = nameValidation;
        emailError = emailValidation;
        passwordError = passwordValidation;
        confirmPasswordError = confirmPasswordValidation;
      });

      // Show first error in snackbar
      String errorMsg =
          nameValidation ??
          emailValidation ??
          passwordValidation ??
          confirmPasswordValidation ??
          '';
      _showSnackBar(errorMsg, Colors.red);
      return;
    }

    setState(() => isLoading = true);
    print('🔵 Button pressed, calling API...');

    try {
      final result = await ApiService.registerUser(
        fullName: nameController.text.trim(),
        email: emailController.text
            .trim()
            .toLowerCase(), // Convert to lowercase
        password: passwordController.text.trim(),
      );

      setState(() => isLoading = false);
      print('🔵 API Result: $result');

      if (result['success']) {
        _showSnackBar(strings.registrationSuccess, Colors.green);
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        String errorMessage = strings.registrationFailed;

        // Handle API errors
        if (result['error'] is Map) {
          final errors = result['error'] as Map;

          // Email errors
          if (errors['email'] != null) {
            List<dynamic> emailErrors = errors['email'];
            if (emailErrors.isNotEmpty) {
              if (emailErrors[0].toString().toLowerCase().contains(
                    'already exists',
                  ) ||
                  emailErrors[0].toString().toLowerCase().contains(
                    'already taken',
                  )) {
                errorMessage = strings.emailAlreadyRegistered;
                setState(() => emailError = strings.emailAlreadyExistsShort);
              } else {
                errorMessage = strings.emailErrorMessage(
                  emailErrors[0].toString(),
                );
                setState(() => emailError = emailErrors[0].toString());
              }
            }
          }

          // Username/Name errors
          if (errors['name'] != null ||
              errors['full_name'] != null ||
              errors['username'] != null) {
            List<dynamic> nameErrors =
                errors['name'] ?? errors['full_name'] ?? errors['username'];
            if (nameErrors.isNotEmpty) {
              if (nameErrors[0].toString().toLowerCase().contains(
                    'already exists',
                  ) ||
                  nameErrors[0].toString().toLowerCase().contains(
                    'already taken',
                  )) {
                errorMessage = strings.usernameTaken;
                setState(() => nameError = strings.usernameAlreadyExistsShort);
              } else {
                errorMessage = strings.nameErrorMessage(
                  nameErrors[0].toString(),
                );
                setState(() => nameError = nameErrors[0].toString());
              }
            }
          }

          // Password errors
          if (errors['password'] != null) {
            List<dynamic> passwordErrors = errors['password'];
            if (passwordErrors.isNotEmpty) {
              errorMessage = strings.passwordErrorMessage(
                passwordErrors[0].toString(),
              );
              setState(() => passwordError = passwordErrors[0].toString());
            }
          }
        } else if (result['error'] is String) {
          errorMessage = strings.genericError(result['error'].toString());
        }

        _showSnackBar(
          errorMessage,
          Colors.red,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('🔴 Exception in handleRegister: $e');
      _showSnackBar(
        strings.networkError,
        Colors.red,
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _showSnackBar(
    String message,
    Color color, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return GlassScaffold(
      title: strings.register,
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
                  Icons.person_add_alt_1_rounded,
                  size: 44,
                  color: kBrandRed,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                strings.createAccount,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.joinUs,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 32),

              // Name Field with Error
              GlassTextField(
                hintText: strings.usernameHint,
                icon: Icons.person_outline,
                controller: nameController,
              ),
              if (nameError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      nameError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Email Field with Error
              GlassTextField(
                hintText: strings.emailHint,
                icon: Icons.email_outlined,
                controller: emailController,
              ),
              if (emailError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      emailError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Password Field with Error
              GlassTextField(
                hintText: strings.passwordHint,
                icon: Icons.lock_outline,
                isPassword: true,
                controller: passwordController,
              ),
              if (passwordError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      passwordError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Confirm Password Field with Error
              GlassTextField(
                hintText: strings.confirmPasswordHint,
                icon: Icons.lock_outline,
                isPassword: true,
                controller: confirmPasswordController,
              ),
              if (confirmPasswordError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      confirmPasswordError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              // Register Button
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
                  onPressed: isLoading ? null : handleRegister,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          strings.registerUppercase,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Navigate to Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    strings.alreadyHaveAccount,
                    style: TextStyle(color: Colors.black.withOpacity(0.65)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    ),
                    child: Text(
                      strings.login,
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
