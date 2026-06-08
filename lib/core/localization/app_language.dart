import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageOption {
  final String code;
  final String title;
  final String nativeTitle;
  final String sample;
  final Locale locale;
  final String? fontFamily;
  final List<String> fontFamilyFallback;

  const AppLanguageOption({
    required this.code,
    required this.title,
    required this.nativeTitle,
    required this.sample,
    required this.locale,
    this.fontFamily,
    this.fontFamilyFallback = const [],
  });

  String get profileLabel => '$title • $nativeTitle';
}

class AppLanguages {
  static const english = AppLanguageOption(
    code: 'en',
    title: 'English',
    nativeTitle: 'English',
    sample: 'Discover the best products for your everyday needs.',
    locale: Locale('en', 'US'),
  );

  static const hindi = AppLanguageOption(
    code: 'hi',
    title: 'Hindi',
    nativeTitle: 'हिन्दी',
    sample: 'अपने रोज़मर्रा की ज़रूरतों के लिए बेहतरीन उत्पाद खोजें।',
    locale: Locale('hi', 'IN'),
    fontFamily: 'Noto Sans Devanagari',
    fontFamilyFallback: [
      'Noto Sans Devanagari',
      'Nirmala UI',
      'Kohinoor Devanagari',
    ],
  );

  static const bengali = AppLanguageOption(
    code: 'bn',
    title: 'Bengali',
    nativeTitle: 'বাংলা',
    sample: 'আপনার দৈনন্দিন প্রয়োজনের জন্য সেরা পণ্য খুঁজুন।',
    locale: Locale('bn', 'IN'),
    fontFamily: 'Noto Sans Bengali',
    fontFamilyFallback: ['Noto Sans Bengali', 'Nirmala UI', 'Kohinoor Bangla'],
  );

  static const marathi = AppLanguageOption(
    code: 'mr',
    title: 'Marathi',
    nativeTitle: 'मराठी',
    sample: 'तुमच्या रोजच्या गरजांसाठी सर्वोत्तम उत्पादने शोधा.',
    locale: Locale('mr', 'IN'),
    fontFamily: 'Noto Sans Devanagari',
    fontFamilyFallback: [
      'Noto Sans Devanagari',
      'Nirmala UI',
      'Kohinoor Devanagari',
    ],
  );

  static const telugu = AppLanguageOption(
    code: 'te',
    title: 'Telugu',
    nativeTitle: 'తెలుగు',
    sample: 'మీ రోజువారీ అవసరాలకు ఉత్తమ ఉత్పత్తులను కనుగొనండి.',
    locale: Locale('te', 'IN'),
    fontFamily: 'Noto Sans Telugu',
    fontFamilyFallback: ['Noto Sans Telugu', 'Nirmala UI', 'Kohinoor Telugu'],
  );

  static const tamil = AppLanguageOption(
    code: 'ta',
    title: 'Tamil',
    nativeTitle: 'தமிழ்',
    sample: 'உங்கள் அன்றாட தேவைகளுக்கு சிறந்த தயாரிப்புகளை கண்டறியுங்கள்.',
    locale: Locale('ta', 'IN'),
    fontFamily: 'Noto Sans Tamil',
    fontFamilyFallback: ['Noto Sans Tamil', 'Nirmala UI', 'Kohinoor Tamil'],
  );

  static const List<AppLanguageOption> all = [
    english,
    hindi,
    bengali,
    marathi,
    telugu,
    tamil,
  ];

  static AppLanguageOption fromCode(String? code) {
    for (final language in all) {
      if (language.code == code) return language;
    }
    return english;
  }
}

class AppLanguageController extends ChangeNotifier {
  AppLanguageController._();

  static final AppLanguageController instance = AppLanguageController._();
  static const String _storageKey = 'selected_app_language';

  AppLanguageOption _current = AppLanguages.english;
  bool _isReady = false;

  AppLanguageOption get current => _current;
  bool get isReady => _isReady;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _current = AppLanguages.fromCode(prefs.getString(_storageKey));
    _isReady = true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguageOption language) async {
    if (_current.code == language.code) return;

    _current = language;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, language.code);
  }
}
