import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:wss_sports/services/api_service.dart';
import 'package:wss_sports/splash/splash_screen.dart';
import 'package:wss_sports/auth/pages/login_page.dart';
import 'package:wss_sports/auth/pages/reset_password.dart';
import 'package:wss_sports/auth/pages/forgot_password.dart';
import 'package:wss_sports/core/localization/app_strings.dart';
import 'package:wss_sports/core/localization/app_language.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wss_sports/shop/presentation/pages/home_page.dart';


final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

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

  Future<Widget> getStartScreen() async {
    final userData = await ApiService.restoreLoggedInUser();
    if (userData == null) return const LoginPage();
    return HomePage(userData: userData);
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
              navigatorObservers: [routeObserver],
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
              theme: ThemeData(
                // The default font for unassigned text styles
                fontFamily: language.fontFamily,

                // Explicitly defining fonts for different text categories
                textTheme: TextTheme(
                  // HEADINGS -> Plus Jakarta Sans
                  displayLarge: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),
                  displayMedium: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),
                  displaySmall: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),
                  headlineLarge: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),
                  headlineMedium: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),
                  headlineSmall: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),

                  // SUBTITLES / TITLES -> SF Pro
                  titleLarge: TextStyle(
                    fontFamily: 'SFPro',
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),
                  titleMedium: TextStyle(
                    fontFamily: 'SFPro',
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),
                  titleSmall: TextStyle(
                    fontFamily: 'SFPro',
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),

                  // MONOSPACE / SMALL LABELS -> Andale Mono
                  labelSmall: TextStyle(
                    fontFamily: 'AndaleMono',
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),
                  labelMedium: TextStyle(
                    fontFamily: 'AndaleMono',
                    fontFamilyFallback: language.fontFamilyFallback,
                  ),
                ),
              ),
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
