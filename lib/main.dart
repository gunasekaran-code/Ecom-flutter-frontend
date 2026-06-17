import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:ecom_app/core/localization/app_language.dart';
import 'package:ecom_app/core/localization/app_strings.dart';

import 'package:ecom_app/auth/pages/forgot_password.dart';
import 'package:ecom_app/auth/pages/login_page.dart';
import 'package:ecom_app/auth/pages/reset_password.dart';
import 'package:ecom_app/splash/splash_screen.dart'; // ← NEW

void main() {
  runApp(const MyApp());
}

class _ResetPasswordLink {
  final String token;
  final String email;
  const _ResetPasswordLink({required this.token, required this.email});
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLanguageController _languageController =
      AppLanguageController.instance;

  late final Future<void> _loadSettings;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _sub;
  _ResetPasswordLink? _pendingResetLink;

  @override
  void initState() {
    super.initState();
    _loadSettings = _languageController.load();
    handleDeepLink(Uri.base.toString());
    initDeepLinks();
  }

  Future<void> initDeepLinks() async {
    try {
      final initialLink = await AppLinks().getInitialLink();
      if (initialLink != null) {
        handleDeepLink(initialLink.toString());
      }
      _sub = AppLinks().uriLinkStream.listen((Uri uri) {
        handleDeepLink(uri.toString());
      });
    } catch (e) {
      debugPrint("Deep Link Error: $e");
    }
  }

  void handleDeepLink(String link) {
    debugPrint("Deep Link: $link");
    final uri = Uri.parse(link);
    final token = uri.queryParameters['token'];
    final email = Uri.decodeComponent(uri.queryParameters['email'] ?? '');
    debugPrint("Token: $token");
    debugPrint("Email: $email");

    if (_isResetPasswordLink(uri) && token != null) {
      _openResetPassword(token: token, email: email);
    } else {
      debugPrint("Ignored deep link because token/email/path did not match.");
    }
  }

  bool _isResetPasswordLink(Uri uri) {
    final pathSegments = uri.pathSegments.map((part) => part.toLowerCase());
    return (uri.scheme == 'myapp' && uri.host == 'reset-password') ||
        uri.host.toLowerCase() == 'reset-password' ||
        pathSegments.contains('reset-password');
  }

  void _openResetPassword({required String token, required String email}) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingResetLink = _ResetPasswordLink(token: token, email: email);
      return;
    }
    _pendingResetLink = null;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(token: token, email: email),
      ),
      (route) => false,
    );
  }

  void _openPendingResetLink() {
    final pendingResetLink = _pendingResetLink;
    if (pendingResetLink == null || navigatorKey.currentState == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final latestPendingResetLink = _pendingResetLink;
      if (latestPendingResetLink == null || !mounted) return;
      _openResetPassword(
        token: latestPendingResetLink.token,
        email: latestPendingResetLink.email,
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadSettings,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !_languageController.isReady) {
          // ← NEW: show branded splash while settings load (replaces plain spinner)
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        }

        return AnimatedBuilder(
          animation: _languageController,
          builder: (context, _) {
            final language = _languageController.current;
            final initialResetLink = _resetLinkFromUri(Uri.base);

            // ← NEW: splash is the default home; deep link overrides it
            final home = initialResetLink != null
                ? ResetPasswordPage(
                    token: initialResetLink.token,
                    email: initialResetLink.email,
                  )
                : const SplashScreen(); // ← was LoginPage

            _openPendingResetLink();

            return MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              locale: language.locale,
              supportedLocales: AppLanguages.all
                  .map((option) => option.locale)
                  .toSet()
                  .toList(),
              localizationsDelegates: const [
                AppStrings.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(fontFamily: language.fontFamily),
              builder: (context, child) {
                return DefaultTextStyle.merge(
                  style: TextStyle(
                    fontFamily: language.fontFamily,
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: home,
              routes: {
                '/LoginPage': (context) => const LoginPage(),
                '/ForgotPasswordPage': (context) => const ForgotPasswordPage(),
              },
            );
          },
        );
      },
    );
  }

  _ResetPasswordLink? _resetLinkFromUri(Uri uri) {
    final token = uri.queryParameters['token'];
    if (!_isResetPasswordLink(uri) || token == null || token.isEmpty) {
      return null;
    }
    return _ResetPasswordLink(
      token: token,
      email: Uri.decodeComponent(uri.queryParameters['email'] ?? ''),
    );
  }
}