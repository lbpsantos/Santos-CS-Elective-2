import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

// All the Supabase Auth calls: log in, register, GitHub, refresh, log out.
//
// How a Supabase login works:
// - Logging in gives the app a SESSION. A session holds two tokens:
//   - the ACCESS TOKEN: a short-lived JWT (1 hour by default). Supabase
//     sends it with every database request, so the database knows who is
//     asking (that is what the RLS policies check).
//   - the REFRESH TOKEN: a long-lived token that is used once to get a new
//     access token (and a new refresh token) before the old one expires.
// - supabase_flutter saves the session on the device and refreshes the
//   access token by itself, so the user stays logged in after a restart.
class AuthService {
  AuthService(this._auth);

  final GoTrueClient _auth;

  // Where GitHub sends the user back after they log in there.
  // On the web it is the page the app runs on (e.g. http://localhost:3000).
  // On Android it is a deep link that opens the app (see AndroidManifest.xml).
  static const String mobileRedirectUrl = 'io.supabase.shopapp://login-callback/';
  String get _redirectUrl => kIsWeb ? Uri.base.origin : mobileRedirectUrl;

  // The current session, or null when logged out.
  Session? get currentSession => _auth.currentSession;

  // Tells the app when the user logs in or out, and when the access token
  // is refreshed.
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  // Log in with email and password.
  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  // Create an account. Returns true if the user is logged in right away.
  // Returns false if Supabase sent a confirmation email first (the
  // "Confirm email" setting in Supabase is on).
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      // Saved in the user's metadata, shown as "Hello, <name>".
      data: {'full_name': fullName},
      // Where the confirmation email's link opens the app.
      emailRedirectTo: _redirectUrl,
    );
    // When the email is already taken, Supabase pretends it worked (so
    // nobody can find out which emails have accounts) but returns a user
    // without identities.
    if (response.user?.identities?.isEmpty ?? false) {
      throw const AuthException(
        'This email is already registered. Try logging in.',
      );
    }
    return response.session != null;
  }

  // Log in with GitHub (the 3rd-party provider). This opens GitHub's login
  // page. When the user comes back, Supabase turns the code in the link
  // into a session by itself, and authStateChanges reports the login.
  Future<void> signInWithGitHub() async {
    await _auth.signInWithOAuth(OAuthProvider.github, redirectTo: _redirectUrl);
  }

  // Ends the session. Supabase also cancels the refresh token, so it can't
  // be used to log in again.
  Future<void> signOut() => _auth.signOut();
}

// The name to greet the user with. GitHub users have "full_name" / "name" /
// "user_name"; email users have the "full_name" typed when registering.
String displayNameOf(User user) {
  final metadata = user.userMetadata ?? {};
  for (final key in ['full_name', 'name', 'user_name']) {
    final value = metadata[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return user.email?.split('@').first ?? 'Reader';
}

// The profile picture from GitHub, or null for email accounts.
String? avatarUrlOf(User user) {
  final url = user.userMetadata?['avatar_url'];
  return url is String && url.isNotEmpty ? url : null;
}

// How the user logged in: "email" or "github".
String providerOf(User user) {
  return user.appMetadata['provider'] as String? ?? 'email';
}

// Turns an auth error into a short message for the screen.
String friendlyAuthMessage(Object error) {
  if (error is AuthException) {
    final message = error.message;
    if (message.contains('Invalid login credentials')) {
      return 'Wrong email or password.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Please confirm your email first. Check your inbox for the link.';
    }
    if (message.contains('provider is not enabled')) {
      return 'GitHub login is not turned on yet in Supabase '
          '(Authentication -> Sign In / Providers -> GitHub).';
    }
    return message;
  }
  return error.toString();
}
