import 'dart:html' as html;

import 'package:flutter/foundation.dart';

void setupGoogleButtonContainer() {
  final container = html.document.getElementById('google-signin-button');
  if (container != null) {
    debugPrint('Google Sign-In button container ready');
  }
}
