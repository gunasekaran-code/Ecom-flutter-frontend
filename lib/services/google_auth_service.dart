import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '935244299106-v20skm9cgmkcdguqkko7fuais8ks3f95.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;

      if (account == null) {
        if (kIsWeb) {
          // For web, use signIn() directly to avoid double-completion issues
          account = await _googleSignIn.signIn();
        } else {
          // For mobile/desktop, try silent first
          account = await _googleSignIn.signInSilently().catchError(
            (_) => null,
          );
          account ??= await _googleSignIn.signIn();
        }
      }

      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;

        return {
          // Keep Google's string id separate from the backend integer user id.
          // App pages use `id` for API calls, so putting account.id there
          // causes a String-not-int crash on web.
          'id': 0,
          'google_id': account.id,
          'email': account.email,
          'full_name': account.displayName,
          'displayName': account.displayName,
          'photoUrl': account.photoUrl,
          'idToken': auth.idToken,
          'accessToken': auth.accessToken,
        };
      }
      return null;
    } catch (error) {
      debugPrint('Google Sign-In Error: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      debugPrint('Google Sign-Out Error: $error');
    }
  }
}
