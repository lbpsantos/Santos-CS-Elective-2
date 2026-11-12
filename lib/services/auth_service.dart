import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

// All the Supabase Auth calls: log in, register, Google, GitHub, log out.
//
// How a Supabase login works:
// - Logging in gives the app a SESSION. A session holds two tokens:
//   - the ACCESS TOKEN: a short-lived JWT (1 hour by default). Supabase
//     sends it with every database request, so the database knows who is
//     asking (that is what the RLS policies check with auth.uid()).
//   - the REFRESH TOKEN: a long-lived token that is used once to get a new
//     access token (and a new refresh token) before the old one expires.
// - supabase_flutter saves the session on the device and refreshes the
//   access token by itself, so the user stays logged in after a restart.
class AuthService {
  AuthService(this._auth);

  final GoTrueClient _auth;

  // Where Google / GitHub send the user back after they log in there.
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
  //
  // The names go into the user's metadata. The handle_new_user trigger in
  // Supabase copies them into the new profiles row (as a customer).
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {
        'firstname': firstName,
        'lastname': lastName,
        'full_name': '$firstName $lastName'.trim(),
      },
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

  // Log in with Google. This opens Google's login page. When the user
  // comes back, Supabase turns the code in the link into a session by
  // itself, and authStateChanges reports the login. A profile is made by
  // the handle_new_user trigger the first time.
  Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(OAuthProvider.google, redirectTo: _redirectUrl);
  }

  // Log in with GitHub, the same way as Google.
  Future<void> signInWithGitHub() async {
    await _auth.signInWithOAuth(OAuthProvider.github, redirectTo: _redirectUrl);
  }

  // Ends the session. Supabase also cancels the refresh token, so it can't
  // be used to log in again.
  Future<void> signOut() => _auth.signOut();
}

// The name to greet the user with. Google users have "full_name" / "name";
// GitHub users "name" / "user_name"; email users the first and last name
// typed when registering.
String displayNameOf(User user) {
  final metadata = user.userMetadata ?? {};
  final firstName = metadata['firstname'];
  final lastName = metadata['lastname'];
  if (firstName is String && firstName.trim().isNotEmpty) {
    return '$firstName ${lastName is String ? lastName : ''}'.trim();
  }
  for (final key in ['full_name', 'name', 'user_name']) {
    final value = metadata[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return user.email?.split('@').first ?? 'Reader';
}

// The profile picture from Google or GitHub, or null for email accounts.
String? avatarUrlOf(User user) {
  final metadata = user.userMetadata ?? {};
  for (final key in ['avatar_url', 'picture']) {
    final url = metadata[key];
    if (url is String && url.isNotEmpty) return url;
  }
  return null;
}

// How the user logged in this time: "email", "google" or "github".
//
// appMetadata['provider'] is NOT used for this: Supabase sets it once, to
// the method the account was first made with. When the same email later
// logs in another way (e.g. made with GitHub, now Google), Supabase links
// the new method to the same account as another "identity". Each identity
// remembers its own last login, so the newest one is how the user just
// logged in.
String providerOf(User user) {
  final identities = [...?user.identities];
  if (identities.isEmpty) {
    return user.appMetadata['provider'] as String? ?? 'email';
  }
  DateTime lastLogin(UserIdentity identity) =>
      DateTime.tryParse(identity.lastSignInAt ?? '') ?? DateTime(0);
  identities.sort((a, b) => lastLogin(b).compareTo(lastLogin(a)));
  return identities.first.provider;
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
      return 'This login provider is not turned on yet in Supabase '
          '(Authentication -> Sign In / Providers).';
    }
    return message;
  }
  return error.toString();
}
