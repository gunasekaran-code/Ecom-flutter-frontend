import 'package:flutter/material.dart';
import 'package:ecom_app/core/localization/app_strings.dart';
import 'package:ecom_app/core/localization/app_language.dart';
import 'package:ecom_app/shared/widgets/shared_ui.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  final AppLanguageController _languageController =
      AppLanguageController.instance;
  late AppLanguageOption _selectedLanguage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _languageController.current;
  }

  Future<void> _saveLanguage() async {
    setState(() => _isSaving = true);
    await _languageController.setLanguage(_selectedLanguage);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, _selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final primaryLanguages = AppLanguages.all
        .where((language) => language.code != AppLanguages.english.code)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextDark),
        title: Text(
          strings.language,
          style: TextStyle(
            color: kBrandRed,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                children: [
                  _buildPreviewCard(),
                  const SizedBox(height: 18),
                  Text(
                    strings.defaultLanguageSection,
                    style: TextStyle(
                      color: kTextDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLanguageTile(AppLanguages.english),
                  const SizedBox(height: 10),
                  Text(
                    strings.mainLanguages,
                    style: TextStyle(
                      color: kTextDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.languageDescription,
                    style: TextStyle(
                      color: kTextMuted,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...primaryLanguages.map(_buildLanguageTile),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveLanguage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          strings.saveLanguage,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final strings = context.strings;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kBrandRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              strings.preview,
              style: TextStyle(
                color: kBrandRed,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _selectedLanguage.nativeTitle,
            style: TextStyle(
              color: kTextDark,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: _selectedLanguage.fontFamily,
              fontFamilyFallback: _selectedLanguage.fontFamilyFallback,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedLanguage.sample,
            style: TextStyle(
              color: kTextMuted,
              fontSize: 15,
              height: 1.45,
              fontFamily: _selectedLanguage.fontFamily,
              fontFamilyFallback: _selectedLanguage.fontFamilyFallback,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.font_download_outlined,
                color: kBrandRed,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.selectedFontProfile(_selectedLanguage.title),
                  style: TextStyle(
                    color: kTextDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(AppLanguageOption language) {
    final isSelected = _selectedLanguage.code == language.code;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? kBrandRed.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? kBrandRed : kBorder,
          width: isSelected ? 1.6 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: language.code,
        groupValue: _selectedLanguage.code,
        activeColor: kBrandRed,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          language.nativeTitle,
          style: TextStyle(
            color: kTextDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: language.fontFamily,
            fontFamilyFallback: language.fontFamilyFallback,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            language.title,
            style: const TextStyle(
              color: kTextMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? kBrandRed : kSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isSelected ? Icons.check_rounded : Icons.language_rounded,
            color: isSelected ? Colors.white : kBrandRed,
          ),
        ),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _selectedLanguage = AppLanguages.fromCode(value);
          });
        },
      ),
    );
  }
}
