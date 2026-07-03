import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static AppStrings of(BuildContext context) {
    final strings = Localizations.of<AppStrings>(context, AppStrings);
    assert(strings != null, 'AppStrings not found in widget tree.');
    return strings!;
  }

  String get _languageCode {
    final code = locale.languageCode.toLowerCase();
    return _localizedValues.containsKey(code) ? code : 'en';
  }

  String _text(String key, [Map<String, String> params = const {}]) {
    final languageValues = _localizedValues[_languageCode]!;
    var value = languageValues[key] ?? _localizedValues['en']![key] ?? key;

    params.forEach((paramKey, paramValue) {
      value = value.replaceAll('{$paramKey}', paramValue);
    });

    return value;
  }

  String get login => _text('login');
  String get welcomeBack => _text('welcomeBack');
  String get signInToContinue => _text('signInToContinue');
  String get email => _text('email');
  String get password => _text('password');
  String get loginUppercase => _text('loginUppercase');
  String get orLabel => _text('orLabel');
  String get signInWithGoogle => _text('signInWithGoogle');
  String get noAccountQuestion => _text('noAccountQuestion');
  String get register => _text('register');
  String get createAccount => _text('createAccount');
  String get joinUs => _text('joinUs');
  String get usernameHint => _text('usernameHint');
  String get emailHint => _text('emailHint');
  String get passwordHint => _text('passwordHint');
  String get confirmPasswordHint => _text('confirmPasswordHint');
  String get registerUppercase => _text('registerUppercase');
  String get alreadyHaveAccount => _text('alreadyHaveAccount');
  String get discover => _text('discover');
  String welcomeUser(String name) => _text('welcomeUser', {'name': name});
  String get searchProducts => _text('searchProducts');
  String get categories => _text('categories');
  String get seeAll => _text('seeAll');
  String noResultsFor(String query) => _text('noResultsFor', {'query': query});
  String get noProductsFound => _text('noProductsFound');
  String get home => _text('home');
  String get orders => _text('orders');
  String get wishlist => _text('wishlist');
  String get reviews => _text('reviews');
  String get profile => _text('profile');
  String get myProfile => _text('myProfile');
  String get activity => _text('activity');
  String get favorites => _text('favorites');
  String get awards => _text('awards');
  String get account => _text('account');
  String get editProfile => _text('editProfile');
  String get updatePersonalInfo => _text('updatePersonalInfo');
  String get privacySecurity => _text('privacySecurity');
  String get password2faSessions => _text('password2faSessions');
  String get notifications => _text('notifications');
  String get manageAlertsSounds => _text('manageAlertsSounds');
  String get preferences => _text('preferences');
  String get appearance => _text('appearance');
  String get themeAndDisplay => _text('themeAndDisplay');
  String get language => _text('language');
  String get helpSupport => _text('helpSupport');
  String get faqsAndContact => _text('faqsAndContact');
  String get logout => _text('logout');
  String get preview => _text('preview');
  String get defaultLanguageSection => _text('defaultLanguageSection');
  String get mainLanguages => _text('mainLanguages');
  String get languageDescription => _text('languageDescription');
  String get saveLanguage => _text('saveLanguage');
  String selectedFontProfile(String title) =>
      _text('selectedFontProfile', {'title': title});
  String get allCategory => _text('allCategory');
  String get removedFromWishlist => _text('removedFromWishlist');
  String get addedToWishlist => _text('addedToWishlist');
  String errorMessage(String error) => _text('errorMessage', {'error': error});
  String get pleaseEnterEmailPassword => _text('pleaseEnterEmailPassword');
  String get welcomeBackToast => _text('welcomeBackToast');
  String get loginFailed => _text('loginFailed');
  String get serverDatabaseError => _text('serverDatabaseError');
  String get emailNotRegistered => _text('emailNotRegistered');
  String get incorrectPassword => _text('incorrectPassword');
  String get connectionFailed => _text('connectionFailed');
  String get googleSignInSuccess => _text('googleSignInSuccess');
  String get googleSignInCancelled => _text('googleSignInCancelled');
  String googleSignInError(String error) =>
      _text('googleSignInError', {'error': error});
  String get nameRequired => _text('nameRequired');
  String get spacesNotAllowed => _text('spacesNotAllowed');
  String get nameMinChars => _text('nameMinChars');
  String get nameMaxChars => _text('nameMaxChars');
  String get usernameAllowedChars => _text('usernameAllowedChars');
  String get emailRequired => _text('emailRequired');
  String get emailInvalid => _text('emailInvalid');
  String get passwordRequired => _text('passwordRequired');
  String get confirmPasswordRequired => _text('confirmPasswordRequired');
  String get passwordsDoNotMatch => _text('passwordsDoNotMatch');
  String get registrationSuccess => _text('registrationSuccess');
  String get registrationFailed => _text('registrationFailed');
  String get emailAlreadyRegistered => _text('emailAlreadyRegistered');
  String get emailAlreadyExistsShort => _text('emailAlreadyExistsShort');
  String emailErrorMessage(String error) =>
      _text('emailErrorMessage', {'error': error});
  String get usernameTaken => _text('usernameTaken');
  String get usernameAlreadyExistsShort => _text('usernameAlreadyExistsShort');
  String nameErrorMessage(String error) =>
      _text('nameErrorMessage', {'error': error});
  String passwordErrorMessage(String error) =>
      _text('passwordErrorMessage', {'error': error});
  String genericError(String error) => _text('genericError', {'error': error});
  String get networkError => _text('networkError');
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      _localizedValues.containsKey(locale.languageCode.toLowerCase());

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

extension AppStringsBuildContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}

const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'login': 'Login',
    'welcomeBack': 'Welcome Back',
    'signInToContinue': 'Sign in to continue',
    'email': 'Email',
    'password': 'Password',
    'loginUppercase': 'LOGIN',
    'orLabel': 'OR',
    'signInWithGoogle': 'Sign in with Google',
    'noAccountQuestion': "Don't have an account? ",
    'register': 'Register',
    'createAccount': 'Create Account',
    'joinUs': 'Join us - it only takes a minute',
    'usernameHint': 'Username',
    'emailHint': 'Email ',
    'passwordHint': 'Password ',
    'confirmPasswordHint': 'Confirm Password',
    'registerUppercase': 'REGISTER',
    'alreadyHaveAccount': 'Already have an account? ',
    'discover': 'Discover ',
    'welcomeUser': 'Welcome, {name}',
    'searchProducts': 'Search products...',
    'categories': 'Categories',
    'seeAll': 'See all',
    'noResultsFor': 'No results for "{query}"',
    'noProductsFound': 'No products found',
    'home': 'Home',
    'orders': 'Orders',
    'wishlist': 'Wishlist',
    'profile': 'Profile',
    'myProfile': 'My Profile',
    'activity': 'Activity',
    'favorites': 'Favorites',
    'awards': 'Awards',
    'account': 'Account',
    'editProfile': 'Edit Profile',
    'updatePersonalInfo': 'Update your personal info',
    'privacySecurity': 'Privacy & Security',
    'password2faSessions': 'Password, 2FA, sessions',
    'notifications': 'Notifications',
    'manageAlertsSounds': 'Manage alerts and sounds',
    'preferences': 'Preferences',
    'appearance': 'Appearance',
    'themeAndDisplay': 'Theme and display',
    'language': 'Language',
    'helpSupport': 'Help & Support',
    'faqsAndContact': 'FAQs and contact us',
    'logout': 'Logout',
    'preview': 'Preview',
    'defaultLanguageSection': 'Default',
    'mainLanguages': 'Main Languages',
    'languageDescription':
        'Choose a language and save it to update the app text and font preference.',
    'saveLanguage': 'Save Language',
    'selectedFontProfile': 'Selected language profile: {title}',
    'allCategory': 'All',
    'removedFromWishlist': 'Removed from wishlist',
    'addedToWishlist': 'Added to wishlist',
    'errorMessage': 'Error: {error}',
    'pleaseEnterEmailPassword': 'Please enter both email and password.',
    'welcomeBackToast': 'Welcome back!',
    'loginFailed': 'Login failed',
    'serverDatabaseError': 'Server database error. Please check backend logs.',
    'emailNotRegistered': 'Email not registered.',
    'incorrectPassword': 'Incorrect Email or password',
    
    'connectionFailed': 'Connection failed. Is the server running?',
    'googleSignInSuccess': 'Google Sign-In successful!',
    'googleSignInCancelled': 'Google Sign-In cancelled.',
    'googleSignInError': 'Google Sign-In error: {error}',
    'nameRequired': 'Name is required',
    'spacesNotAllowed': 'Spaces are not allowed in username',
    'nameMinChars': 'Name must be at least 3 characters',
    'nameMaxChars': 'Name must be maximum 20 characters',
    'usernameAllowedChars':
        'Only letters, numbers, and underscores (_) are allowed',
    'emailRequired': 'Email is required',
    'emailInvalid': 'Please enter a valid email address (e.g., user@gmail.com)',
    'passwordRequired': 'Password is required',
    'confirmPasswordRequired': 'Confirm password is required',
    'passwordsDoNotMatch': 'Passwords do not match',
    'registrationSuccess': 'Registration successful!',
    'registrationFailed': 'Registration failed. Please try again.',
    'emailAlreadyRegistered':
        'This email is already registered. Please use another email.',
    'emailAlreadyExistsShort': 'Email already exists',
    'emailErrorMessage': 'Email: {error}',
    'usernameTaken':
        'This username is already taken. Please choose another one.',
    'usernameAlreadyExistsShort': 'Username already exists',
    'nameErrorMessage': 'Name: {error}',
    'passwordErrorMessage': 'Password: {error}',
    'genericError': '{error}',
    'networkError':
        'Network error. Please check your connection and try again.',
  },
  'hi': {
    'login': 'लॉगिन',
    'welcomeBack': 'वापसी पर स्वागत है',
    'signInToContinue': 'जारी रखने के लिए साइन इन करें',
    'email': 'ईमेल',
    'password': 'पासवर्ड',
    'loginUppercase': 'लॉगिन',
    'orLabel': 'या',
    'signInWithGoogle': 'Google से साइन इन करें',
    'noAccountQuestion': 'क्या आपका खाता नहीं है? ',
    'register': 'रजिस्टर करें',
    'createAccount': 'खाता बनाएं',
    'joinUs': 'हमसे जुड़ें - इसमें केवल एक मिनट लगता है',
    'usernameHint': 'यूज़रनेम (3-20 अक्षर, बिना स्पेस)',
    'emailHint': 'ईमेल (जैसे user@gmail.com)',
    'passwordHint': 'पासवर्ड (कम से कम 6 अक्षर)',
    'registerUppercase': 'रजिस्टर',
    'alreadyHaveAccount': 'क्या पहले से खाता है? ',
    'discover': 'खोजें',
    'welcomeUser': 'स्वागत है, {name}',
    'searchProducts': 'उत्पाद खोजें...',
    'categories': 'श्रेणियां',
    'seeAll': 'सभी देखें',
    'noResultsFor': '"{query}" के लिए कोई परिणाम नहीं',
    'noProductsFound': 'कोई उत्पाद नहीं मिला',
    'home': 'होम',
    'orders': 'ऑर्डर',
    'wishlist': 'विशलिस्ट',
    'profile': 'प्रोफ़ाइल',
    'myProfile': 'मेरी प्रोफ़ाइल',
    'activity': 'गतिविधि',
    'favorites': 'पसंदीदा',
    'awards': 'पुरस्कार',
    'account': 'खाता',
    'editProfile': 'प्रोफ़ाइल संपादित करें',
    'updatePersonalInfo': 'अपनी व्यक्तिगत जानकारी अपडेट करें',
    'privacySecurity': 'गोपनीयता और सुरक्षा',
    'password2faSessions': 'पासवर्ड, 2FA, सत्र',
    'notifications': 'सूचनाएं',
    'manageAlertsSounds': 'अलर्ट और ध्वनि प्रबंधित करें',
    'preferences': 'प्राथमिकताएं',
    'appearance': 'दिखावट',
    'themeAndDisplay': 'थीम और डिस्प्ले',
    'language': 'भाषा',
    'helpSupport': 'मदद और सहायता',
    'faqsAndContact': 'अक्सर पूछे जाने वाले प्रश्न और संपर्क',
    'logout': 'लॉगआउट',
    'preview': 'पूर्वावलोकन',
    'defaultLanguageSection': 'डिफॉल्ट',
    'mainLanguages': 'मुख्य भाषाएं',
    'languageDescription':
        'ऐप के टेक्स्ट और फ़ॉन्ट पसंद को अपडेट करने के लिए भाषा चुनें और सेव करें।',
    'saveLanguage': 'भाषा सेव करें',
    'selectedFontProfile': 'चुनी गई भाषा प्रोफ़ाइल: {title}',
    'allCategory': 'सभी',
    'removedFromWishlist': 'विशलिस्ट से हटाया गया',
    'addedToWishlist': 'विशलिस्ट में जोड़ा गया',
    'errorMessage': 'त्रुटि: {error}',
    'pleaseEnterEmailPassword': 'कृपया ईमेल और पासवर्ड दोनों दर्ज करें।',
    'welcomeBackToast': 'वापसी पर स्वागत है!',
    'loginFailed': 'लॉगिन विफल',
    'serverDatabaseError': 'सर्वर डेटाबेस त्रुटि। कृपया बैकएंड लॉग जांचें।',
    'emailNotRegistered': 'ईमेल पंजीकृत नहीं है।',
    'incorrectPassword': 'गलत पासवर्ड।',
    'connectionFailed': 'कनेक्शन विफल। क्या सर्वर चल रहा है?',
    'googleSignInSuccess': 'Google साइन-इन सफल रहा!',
    'googleSignInCancelled': 'Google साइन-इन रद्द किया गया।',
    'googleSignInError': 'Google साइन-इन त्रुटि: {error}',
    'nameRequired': 'नाम आवश्यक है',
    'spacesNotAllowed': 'यूज़रनेम में स्पेस की अनुमति नहीं है',
    'nameMinChars': 'नाम कम से कम 3 अक्षरों का होना चाहिए',
    'nameMaxChars': 'नाम अधिकतम 20 अक्षरों का होना चाहिए',
    'usernameAllowedChars': 'केवल अक्षर, अंक और अंडरस्कोर (_) की अनुमति है',
    'emailRequired': 'ईमेल आवश्यक है',
    'emailInvalid': 'कृपया एक मान्य ईमेल पता दर्ज करें (जैसे user@gmail.com)',
    'passwordRequired': 'पासवर्ड आवश्यक है',
    'registrationSuccess': 'पंजीकरण सफल रहा!',
    'registrationFailed': 'पंजीकरण विफल हुआ। कृपया फिर से प्रयास करें।',
    'emailAlreadyRegistered':
        'यह ईमेल पहले से पंजीकृत है। कृपया दूसरा ईमेल उपयोग करें।',
    'emailAlreadyExistsShort': 'ईमेल पहले से मौजूद है',
    'emailErrorMessage': 'ईमेल: {error}',
    'usernameTaken': 'यह यूज़रनेम पहले से लिया जा चुका है। कृपया दूसरा चुनें।',
    'usernameAlreadyExistsShort': 'यूज़रनेम पहले से मौजूद है',
    'nameErrorMessage': 'नाम: {error}',
    'passwordErrorMessage': 'पासवर्ड: {error}',
    'genericError': '{error}',
    'networkError':
        'नेटवर्क त्रुटि। कृपया अपना कनेक्शन जांचें और फिर प्रयास करें।',
  },
  'bn': {
    'login': 'লগইন',
    'welcomeBack': 'আবারও স্বাগতম',
    'signInToContinue': 'চালিয়ে যেতে সাইন ইন করুন',
    'email': 'ইমেল',
    'password': 'পাসওয়ার্ড',
    'loginUppercase': 'লগইন',
    'orLabel': 'অথবা',
    'signInWithGoogle': 'Google দিয়ে সাইন ইন করুন',
    'noAccountQuestion': 'আপনার কি অ্যাকাউন্ট নেই? ',
    'register': 'রেজিস্টার',
    'createAccount': 'অ্যাকাউন্ট তৈরি করুন',
    'joinUs': 'আমাদের সাথে যুক্ত হোন - মাত্র এক মিনিট লাগবে',
    'usernameHint': 'ইউজারনেম (৩-২০ অক্ষর, স্পেস নয়)',
    'emailHint': 'ইমেল (যেমন user@gmail.com)',
    'passwordHint': 'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)',
    'registerUppercase': 'রেজিস্টার',
    'alreadyHaveAccount': 'আগে থেকেই অ্যাকাউন্ট আছে? ',
    'discover': 'আবিষ্কার করুন',
    'welcomeUser': 'স্বাগতম, {name}',
    'searchProducts': 'পণ্য খুঁজুন...',
    'categories': 'বিভাগ',
    'seeAll': 'সব দেখুন',
    'noResultsFor': '"{query}" এর জন্য কোনো ফলাফল নেই',
    'noProductsFound': 'কোনো পণ্য পাওয়া যায়নি',
    'home': 'হোম',
    'orders': 'অর্ডার',
    'wishlist': 'উইশলিস্ট',
    'profile': 'প্রোফাইল',
    'myProfile': 'আমার প্রোফাইল',
    'activity': 'কার্যকলাপ',
    'favorites': 'পছন্দ',
    'awards': 'পুরস্কার',
    'account': 'অ্যাকাউন্ট',
    'editProfile': 'প্রোফাইল সম্পাদনা',
    'updatePersonalInfo': 'আপনার ব্যক্তিগত তথ্য আপডেট করুন',
    'privacySecurity': 'গোপনীয়তা ও নিরাপত্তা',
    'password2faSessions': 'পাসওয়ার্ড, 2FA, সেশন',
    'notifications': 'নোটিফিকেশন',
    'manageAlertsSounds': 'অ্যালার্ট ও সাউন্ড পরিচালনা করুন',
    'preferences': 'পছন্দসমূহ',
    'appearance': 'চেহারা',
    'themeAndDisplay': 'থিম ও ডিসপ্লে',
    'language': 'ভাষা',
    'helpSupport': 'সহায়তা ও সাপোর্ট',
    'faqsAndContact': 'প্রশ্নোত্তর ও যোগাযোগ',
    'logout': 'লগআউট',
    'preview': 'প্রিভিউ',
    'defaultLanguageSection': 'ডিফল্ট',
    'mainLanguages': 'প্রধান ভাষাসমূহ',
    'languageDescription':
        'অ্যাপের লেখা ও ফন্ট পছন্দ আপডেট করতে ভাষা বেছে নিয়ে সেভ করুন।',
    'saveLanguage': 'ভাষা সেভ করুন',
    'selectedFontProfile': 'নির্বাচিত ভাষা প্রোফাইল: {title}',
    'allCategory': 'সব',
    'removedFromWishlist': 'উইশলিস্ট থেকে সরানো হয়েছে',
    'addedToWishlist': 'উইশলিস্টে যোগ করা হয়েছে',
    'errorMessage': 'ত্রুটি: {error}',
    'pleaseEnterEmailPassword': 'অনুগ্রহ করে ইমেল এবং পাসওয়ার্ড দুটোই লিখুন।',
    'welcomeBackToast': 'আবারও স্বাগতম!',
    'loginFailed': 'লগইন ব্যর্থ হয়েছে',
    'serverDatabaseError': 'সার্ভার ডাটাবেস ত্রুটি। ব্যাকএন্ড লগ পরীক্ষা করুন।',
    'emailNotRegistered': 'ইমেল নিবন্ধিত নয়।',
    'incorrectPassword': 'ভুল পাসওয়ার্ড।',
    'connectionFailed': 'সংযোগ ব্যর্থ হয়েছে। সার্ভার কি চলছে?',
    'googleSignInSuccess': 'Google সাইন-ইন সফল হয়েছে!',
    'googleSignInCancelled': 'Google সাইন-ইন বাতিল হয়েছে।',
    'googleSignInError': 'Google সাইন-ইন ত্রুটি: {error}',
    'nameRequired': 'নাম প্রয়োজন',
    'spacesNotAllowed': 'ইউজারনেমে স্পেস ব্যবহার করা যাবে না',
    'nameMinChars': 'নাম কমপক্ষে ৩ অক্ষরের হতে হবে',
    'nameMaxChars': 'নাম সর্বোচ্চ ২০ অক্ষরের হতে হবে',
    'usernameAllowedChars':
        'শুধু অক্ষর, সংখ্যা এবং আন্ডারস্কোর (_) ব্যবহার করা যাবে',
    'emailRequired': 'ইমেল প্রয়োজন',
    'emailInvalid': 'সঠিক ইমেল ঠিকানা লিখুন (যেমন user@gmail.com)',
    'passwordRequired': 'পাসওয়ার্ড প্রয়োজন',
    'registrationSuccess': 'রেজিস্ট্রেশন সফল হয়েছে!',
    'registrationFailed':
        'রেজিস্ট্রেশন ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
    'emailAlreadyRegistered':
        'এই ইমেল আগে থেকেই নিবন্ধিত। অন্য ইমেল ব্যবহার করুন।',
    'emailAlreadyExistsShort': 'ইমেল আগে থেকেই আছে',
    'emailErrorMessage': 'ইমেল: {error}',
    'usernameTaken': 'এই ইউজারনেম আগে থেকেই নেওয়া হয়েছে। অন্যটি বেছে নিন।',
    'usernameAlreadyExistsShort': 'ইউজারনেম আগে থেকেই আছে',
    'nameErrorMessage': 'নাম: {error}',
    'passwordErrorMessage': 'পাসওয়ার্ড: {error}',
    'genericError': '{error}',
    'networkError':
        'নেটওয়ার্ক ত্রুটি। অনুগ্রহ করে সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।',
  },
  'mr': {
    'login': 'लॉगिन',
    'welcomeBack': 'पुन्हा स्वागत आहे',
    'signInToContinue': 'पुढे जाण्यासाठी साइन इन करा',
    'email': 'ईमेल',
    'password': 'पासवर्ड',
    'loginUppercase': 'लॉगिन',
    'orLabel': 'किंवा',
    'signInWithGoogle': 'Google ने साइन इन करा',
    'noAccountQuestion': 'तुमचे खाते नाही का? ',
    'register': 'नोंदणी करा',
    'createAccount': 'खाते तयार करा',
    'joinUs': 'आमच्यात सामील व्हा - फक्त एक मिनिट लागेल',
    'usernameHint': 'वापरकर्तानाव (3-20 अक्षरे, स्पेस नाही)',
    'emailHint': 'ईमेल (उदा. user@gmail.com)',
    'passwordHint': 'पासवर्ड (किमान 6 अक्षरे)',
    'registerUppercase': 'नोंदणी',
    'alreadyHaveAccount': 'आधीच खाते आहे का? ',
    'discover': 'शोधा',
    'welcomeUser': 'स्वागत आहे, {name}',
    'searchProducts': 'उत्पादने शोधा...',
    'categories': 'श्रेण्या',
    'seeAll': 'सर्व पहा',
    'noResultsFor': '"{query}" साठी कोणतेही परिणाम नाहीत',
    'noProductsFound': 'कोणतीही उत्पादने सापडली नाहीत',
    'home': 'होम',
    'orders': 'ऑर्डर',
    'wishlist': 'विशलिस्ट',
    'profile': 'प्रोफाइल',
    'myProfile': 'माझे प्रोफाइल',
    'activity': 'क्रियाकलाप',
    'favorites': 'आवडी',
    'awards': 'पुरस्कार',
    'account': 'खाते',
    'editProfile': 'प्रोफाइल संपादित करा',
    'updatePersonalInfo': 'तुमची वैयक्तिक माहिती अपडेट करा',
    'privacySecurity': 'गोपनीयता आणि सुरक्षा',
    'password2faSessions': 'पासवर्ड, 2FA, सत्रे',
    'notifications': 'सूचना',
    'manageAlertsSounds': 'अलर्ट आणि ध्वनी व्यवस्थापित करा',
    'preferences': 'प्राधान्ये',
    'appearance': 'दिसणे',
    'themeAndDisplay': 'थीम आणि डिस्प्ले',
    'language': 'भाषा',
    'helpSupport': 'मदत आणि समर्थन',
    'faqsAndContact': 'FAQ आणि संपर्क',
    'logout': 'लॉगआउट',
    'preview': 'पूर्वावलोकन',
    'defaultLanguageSection': 'डीफॉल्ट',
    'mainLanguages': 'मुख्य भाषा',
    'languageDescription':
        'अॅपमधील मजकूर आणि फॉन्ट पसंती अपडेट करण्यासाठी भाषा निवडा आणि सेव्ह करा.',
    'saveLanguage': 'भाषा सेव्ह करा',
    'selectedFontProfile': 'निवडलेला भाषा प्रोफाइल: {title}',
    'allCategory': 'सर्व',
    'removedFromWishlist': 'विशलिस्टमधून काढले',
    'addedToWishlist': 'विशलिस्टमध्ये जोडले',
    'errorMessage': 'त्रुटी: {error}',
    'pleaseEnterEmailPassword': 'कृपया ईमेल आणि पासवर्ड दोन्ही प्रविष्ट करा.',
    'welcomeBackToast': 'पुन्हा स्वागत आहे!',
    'loginFailed': 'लॉगिन अयशस्वी',
    'serverDatabaseError': 'सर्व्हर डेटाबेस त्रुटी. कृपया बॅकएंड लॉग तपासा.',
    'emailNotRegistered': 'ईमेल नोंदणीकृत नाही.',
    'incorrectPassword': 'चुकीचा पासवर्ड.',
    'connectionFailed': 'कनेक्शन अयशस्वी. सर्व्हर चालू आहे का?',
    'googleSignInSuccess': 'Google साइन-इन यशस्वी!',
    'googleSignInCancelled': 'Google साइन-इन रद्द केले.',
    'googleSignInError': 'Google साइन-इन त्रुटी: {error}',
    'nameRequired': 'नाव आवश्यक आहे',
    'spacesNotAllowed': 'वापरकर्तानावात स्पेसला परवानगी नाही',
    'nameMinChars': 'नाव किमान 3 अक्षरांचे असावे',
    'nameMaxChars': 'नाव जास्तीत जास्त 20 अक्षरांचे असावे',
    'usernameAllowedChars':
        'फक्त अक्षरे, संख्या आणि अंडरस्कोर (_) वापरता येतील',
    'emailRequired': 'ईमेल आवश्यक आहे',
    'emailInvalid': 'कृपया वैध ईमेल पत्ता प्रविष्ट करा (उदा. user@gmail.com)',
    'passwordRequired': 'पासवर्ड आवश्यक आहे',
    'registrationSuccess': 'नोंदणी यशस्वी झाली!',
    'registrationFailed': 'नोंदणी अयशस्वी झाली. कृपया पुन्हा प्रयत्न करा.',
    'emailAlreadyRegistered':
        'हा ईमेल आधीच नोंदणीकृत आहे. कृपया दुसरा ईमेल वापरा.',
    'emailAlreadyExistsShort': 'ईमेल आधीच अस्तित्वात आहे',
    'emailErrorMessage': 'ईमेल: {error}',
    'usernameTaken': 'हे वापरकर्तानाव आधीच घेतले आहे. कृपया दुसरे निवडा.',
    'usernameAlreadyExistsShort': 'वापरकर्तानाव आधीच अस्तित्वात आहे',
    'nameErrorMessage': 'नाव: {error}',
    'passwordErrorMessage': 'पासवर्ड: {error}',
    'genericError': '{error}',
    'networkError':
        'नेटवर्क त्रुटी. कृपया तुमचे कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.',
  },
  'te': {
    'login': 'లాగిన్',
    'welcomeBack': 'మళ్లీ స్వాగతం',
    'signInToContinue': 'కొనసాగడానికి సైన్ ఇన్ చేయండి',
    'email': 'ఈమెయిల్',
    'password': 'పాస్‌వర్డ్',
    'loginUppercase': 'లాగిన్',
    'orLabel': 'లేదా',
    'signInWithGoogle': 'Google తో సైన్ ఇన్ చేయండి',
    'noAccountQuestion': 'మీకు ఖాతా లేదా? ',
    'register': 'నమోదు చేసుకోండి',
    'createAccount': 'ఖాతాను సృష్టించండి',
    'joinUs': 'మాతో చేరండి - కేవలం ఒక నిమిషమే పడుతుంది',
    'usernameHint': 'వినియోగదారు పేరు (3-20 అక్షరాలు, స్పేస్ లేదు)',
    'emailHint': 'ఈమెయిల్ (ఉదా: user@gmail.com)',
    'passwordHint': 'పాస్‌వర్డ్ (కనీసం 6 అక్షరాలు)',
    'registerUppercase': 'నమోదు',
    'alreadyHaveAccount': 'ఇప్పటికే ఖాతా ఉందా? ',
    'discover': 'కనుగొనండి',
    'welcomeUser': 'స్వాగతం, {name}',
    'searchProducts': 'ఉత్పత్తులను వెతకండి...',
    'categories': 'వర్గాలు',
    'seeAll': 'అన్నీ చూడండి',
    'noResultsFor': '"{query}" కు ఫలితాలు లేవు',
    'noProductsFound': 'ఏ ఉత్పత్తులు దొరకలేదు',
    'home': 'హోమ్',
    'orders': 'ఆర్డర్లు',
    'wishlist': 'విష్‌లిస్ట్',
    'profile': 'ప్రొఫైల్',
    'myProfile': 'నా ప్రొఫైల్',
    'activity': 'చర్య',
    'favorites': 'ఇష్టాలు',
    'awards': 'అవార్డులు',
    'account': 'ఖాతా',
    'editProfile': 'ప్రొఫైల్ సవరించండి',
    'updatePersonalInfo': 'మీ వ్యక్తిగత సమాచారాన్ని అప్‌డేట్ చేయండి',
    'privacySecurity': 'గోప్యత & భద్రత',
    'password2faSessions': 'పాస్‌వర్డ్, 2FA, సెషన్లు',
    'notifications': 'నోటిఫికేషన్లు',
    'manageAlertsSounds': 'అలర్ట్లు మరియు శబ్దాలను నిర్వహించండి',
    'preferences': 'అభిరుచులు',
    'appearance': 'రూపం',
    'themeAndDisplay': 'థీమ్ మరియు డిస్ప్లే',
    'language': 'భాష',
    'helpSupport': 'సహాయం & మద్దతు',
    'faqsAndContact': 'FAQలు మరియు సంప్రదింపు',
    'logout': 'లాగ్‌అవుట్',
    'preview': 'ప్రివ్యూ',
    'defaultLanguageSection': 'డిఫాల్ట్',
    'mainLanguages': 'ప్రధాన భాషలు',
    'languageDescription':
        'యాప్ టెక్స్ట్ మరియు ఫాంట్ అభిరుచిని అప్‌డేట్ చేయడానికి భాషను ఎంచుకుని సేవ్ చేయండి.',
    'saveLanguage': 'భాషను సేవ్ చేయండి',
    'selectedFontProfile': 'ఎంచుకున్న భాష ప్రొఫైల్: {title}',
    'allCategory': 'అన్ని',
    'removedFromWishlist': 'విష్‌లిస్ట్ నుండి తొలగించబడింది',
    'addedToWishlist': 'విష్‌లిస్ట్‌లో చేర్చబడింది',
    'errorMessage': 'లోపం: {error}',
    'pleaseEnterEmailPassword':
        'దయచేసి ఈమెయిల్ మరియు పాస్‌వర్డ్ రెండింటినీ నమోదు చేయండి.',
    'welcomeBackToast': 'మళ్లీ స్వాగతం!',
    'loginFailed': 'లాగిన్ విఫలమైంది',
    'serverDatabaseError':
        'సర్వర్ డేటాబేస్ లోపం. దయచేసి బ్యాక్‌ఎండ్ లాగ్స్ చూడండి.',
    'emailNotRegistered': 'ఈమెయిల్ నమోదు కాలేదు.',
    'incorrectPassword': 'తప్పు పాస్‌వర్డ్.',
    'connectionFailed': 'కనెక్షన్ విఫలమైంది. సర్వర్ నడుస్తుందా?',
    'googleSignInSuccess': 'Google సైన్-ఇన్ విజయవంతమైంది!',
    'googleSignInCancelled': 'Google సైన్-ఇన్ రద్దు చేయబడింది.',
    'googleSignInError': 'Google సైన్-ఇన్ లోపం: {error}',
    'nameRequired': 'పేరు అవసరం',
    'spacesNotAllowed': 'వినియోగదారు పేరులో ఖాళీలు అనుమతించబడవు',
    'nameMinChars': 'పేరు కనీసం 3 అక్షరాలు ఉండాలి',
    'nameMaxChars': 'పేరు గరిష్టంగా 20 అక్షరాలు ఉండాలి',
    'usernameAllowedChars':
        'అక్షరాలు, సంఖ్యలు, అండర్‌స్కోర్ (_) మాత్రమే అనుమతించబడతాయి',
    'emailRequired': 'ఈమెయిల్ అవసరం',
    'emailInvalid':
        'దయచేసి సరైన ఈమెయిల్ చిరునామా నమోదు చేయండి (ఉదా: user@gmail.com)',
    'passwordRequired': 'పాస్‌వర్డ్ అవసరం',
    'registrationSuccess': 'నమోదు విజయవంతమైంది!',
    'registrationFailed': 'నమోదు విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
    'emailAlreadyRegistered':
        'ఈ ఈమెయిల్ ఇప్పటికే నమోదైంది. దయచేసి మరొక ఈమెయిల్ ఉపయోగించండి.',
    'emailAlreadyExistsShort': 'ఈమెయిల్ ఇప్పటికే ఉంది',
    'emailErrorMessage': 'ఈమెయిల్: {error}',
    'usernameTaken':
        'ఈ వినియోగదారు పేరు ఇప్పటికే తీసుకోబడింది. దయచేసి మరొకదాన్ని ఎంచుకోండి.',
    'usernameAlreadyExistsShort': 'వినియోగదారు పేరు ఇప్పటికే ఉంది',
    'nameErrorMessage': 'పేరు: {error}',
    'passwordErrorMessage': 'పాస్‌వర్డ్: {error}',
    'genericError': '{error}',
    'networkError':
        'నెట్‌వర్క్ లోపం. దయచేసి కనెక్షన్‌ను తనిఖీ చేసి మళ్లీ ప్రయత్నించండి.',
  },
  'ta': {
    'login': 'உள்நுழை',
    'welcomeBack': 'மீண்டும் வரவேற்கிறோம்',
    'signInToContinue': 'தொடர சைன் இன் செய்யவும்',
    'email': 'மின்னஞ்சல்',
    'password': 'கடவுச்சொல்',
    'loginUppercase': 'உள்நுழை',
    'orLabel': 'அல்லது',
    'signInWithGoogle': 'Google மூலம் உள்நுழைக',
    'noAccountQuestion': 'உங்களுக்கு கணக்கு இல்லையா? ',
    'register': 'பதிவு செய்யவும்',
    'createAccount': 'கணக்கை உருவாக்கவும்',
    'joinUs': 'எங்களுடன் சேருங்கள் - ஒரு நிமிடம் போதும்',
    'usernameHint': 'பயனர் பெயர் (3-20 எழுத்துகள், இடைவெளி இல்லை)',
    'emailHint': 'மின்னஞ்சல் (எ.கா. user@gmail.com)',
    'passwordHint': 'கடவுச்சொல் (குறைந்தது 6 எழுத்துகள்)',
    'registerUppercase': 'பதிவு',
    'alreadyHaveAccount': 'ஏற்கனவே கணக்கு உள்ளதா? ',
    'discover': 'கண்டறிக',
    'welcomeUser': 'வரவேற்கிறோம், {name}',
    'searchProducts': 'பொருட்களைத் தேடுங்கள்...',
    'categories': 'வகைகள்',
    'seeAll': 'அனைத்தையும் காண்க',
    'noResultsFor': '"{query}" க்கு முடிவுகள் இல்லை',
    'noProductsFound': 'எந்த பொருட்களும் கிடைக்கவில்லை',
    'home': 'முகப்பு',
    'orders': 'ஆர்டர்கள்',
    'wishlist': 'விருப்பப் பட்டியல்',
    'profile': 'சுயவிவரம்',
    'myProfile': 'என் சுயவிவரம்',
    'activity': 'செயல்பாடு',
    'favorites': 'பிடித்தவை',
    'awards': 'விருதுகள்',
    'account': 'கணக்கு',
    'editProfile': 'சுயவிவரத்தை திருத்து',
    'updatePersonalInfo': 'உங்கள் தனிப்பட்ட தகவலை புதுப்பிக்கவும்',
    'privacySecurity': 'தனியுரிமை & பாதுகாப்பு',
    'password2faSessions': 'கடவுச்சொல், 2FA, அமர்வுகள்',
    'notifications': 'அறிவிப்புகள்',
    'manageAlertsSounds': 'அலர்ட்கள் மற்றும் ஒலிகளை நிர்வகிக்கவும்',
    'preferences': 'விருப்பங்கள்',
    'appearance': 'தோற்றம்',
    'themeAndDisplay': 'தீம் மற்றும் திரை',
    'language': 'மொழி',
    'helpSupport': 'உதவி & ஆதரவு',
    'faqsAndContact': 'கேள்விகள் மற்றும் தொடர்பு',
    'logout': 'வெளியேறு',
    'preview': 'முன்னோட்டம்',
    'defaultLanguageSection': 'இயல்புநிலை',
    'mainLanguages': 'முக்கிய மொழிகள்',
    'languageDescription':
        'பயன்பாட்டு உரையும் எழுத்துரு விருப்பமும் புதுப்பிக்க மொழியை தேர்ந்தெடுத்து சேமிக்கவும்.',
    'saveLanguage': 'மொழியை சேமிக்கவும்',
    'selectedFontProfile': 'தேர்ந்தெடுக்கப்பட்ட மொழி சுயவிவரம்: {title}',
    'allCategory': 'அனைத்து',
    'removedFromWishlist': 'விருப்பப் பட்டியலில் இருந்து நீக்கப்பட்டது',
    'addedToWishlist': 'விருப்பப் பட்டியலில் சேர்க்கப்பட்டது',
    'errorMessage': 'பிழை: {error}',
    'pleaseEnterEmailPassword':
        'தயவுசெய்து மின்னஞ்சலும் கடவுச்சொல்லும் உள்ளிடவும்.',
    'welcomeBackToast': 'மீண்டும் வரவேற்கிறோம்!',
    'loginFailed': 'உள்நுழைவு தோல்வியடைந்தது',
    'serverDatabaseError':
        'சர்வர் தரவுத்தள பிழை. பின்புற பதிவு கோப்புகளை பார்க்கவும்.',
    'emailNotRegistered': 'மின்னஞ்சல் பதிவு செய்யப்படவில்லை.',
    'incorrectPassword': 'தவறான கடவுச்சொல்.',
    'connectionFailed': 'இணைப்பு தோல்வியடைந்தது. சர்வர் இயங்குகிறதா?',
    'googleSignInSuccess': 'Google உள்நுழைவு வெற்றிகரமாக முடிந்தது!',
    'googleSignInCancelled': 'Google உள்நுழைவு ரத்து செய்யப்பட்டது.',
    'googleSignInError': 'Google உள்நுழைவு பிழை: {error}',
    'nameRequired': 'பெயர் அவசியம்',
    'spacesNotAllowed': 'பயனர் பெயரில் இடைவெளி அனுமதிக்கப்படாது',
    'nameMinChars': 'பெயர் குறைந்தது 3 எழுத்துகள் இருக்க வேண்டும்',
    'nameMaxChars': 'பெயர் அதிகபட்சம் 20 எழுத்துகள் இருக்க வேண்டும்',
    'usernameAllowedChars':
        'எழுத்துகள், எண்கள் மற்றும் அடிக்கோடு (_) மட்டும் அனுமதிக்கப்படும்',
    'emailRequired': 'மின்னஞ்சல் அவசியம்',
    'emailInvalid':
        'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும் (எ.கா. user@gmail.com)',
    'passwordRequired': 'கடவுச்சொல் அவசியம்',
    'registrationSuccess': 'பதிவு வெற்றிகரமாக முடிந்தது!',
    'registrationFailed': 'பதிவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.',
    'emailAlreadyRegistered':
        'இந்த மின்னஞ்சல் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது. வேறு மின்னஞ்சலை பயன்படுத்தவும்.',
    'emailAlreadyExistsShort': 'மின்னஞ்சல் ஏற்கனவே உள்ளது',
    'emailErrorMessage': 'மின்னஞ்சல்: {error}',
    'usernameTaken':
        'இந்த பயனர் பெயர் ஏற்கனவே பயன்படுத்தப்பட்டுள்ளது. மற்றொன்றை தேர்ந்தெடுக்கவும்.',
    'usernameAlreadyExistsShort': 'பயனர் பெயர் ஏற்கனவே உள்ளது',
    'nameErrorMessage': 'பெயர்: {error}',
    'passwordErrorMessage': 'கடவுச்சொல்: {error}',
    'genericError': '{error}',
    'networkError':
        'நெட்வொர்க் பிழை. இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
  },
};
