import 'dart:async';
import 'dart:convert';

import 'package:my_first_flutter_ui/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// A JWT-shaped access token (header.payload.signature) with the claims the
// app reads: sub, role, iat and exp.
String fakeAccessToken({required DateTime expiresAt, int version = 0}) {
  String encode(Map<String, Object> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return [
    encode({'alg': 'HS256', 'typ': 'JWT'}),
    encode({
      'sub': 'user-123',
      'role': 'authenticated',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    }),
    'signature-$version',
  ].join('.');
}

// A logged-in session, like the one Supabase gives after a login.
Session fakeSession({
  String name = 'Lucas Santos',
  String email = 'lucas@example.com',
  String provider = 'email',
  int version = 0,
}) {
  return Session(
    accessToken: fakeAccessToken(
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      version: version,
    ),
    refreshToken: 'refresh-token-$version-abcdefghijklmnopqrstuvwxyz',
    expiresIn: 3600,
    tokenType: 'bearer',
    user: User(
      id: 'user-123',
      appMetadata: {'provider': provider},
      userMetadata: {'full_name': name},
      aud: 'authenticated',
      email: email,
      createdAt: '2026-11-10T00:00:00Z',
    ),
  );
}

// An AuthService without Supabase, for the widget and provider tests.
// The real Supabase Auth requests are tested in auth_service_test.dart.
class FakeAuthService implements AuthService {
  // Pass a session to start logged in, e.g. FakeAuthService(fakeSession()).
  FakeAuthService([this._session]);

  Session? _session;
  final _changes = StreamController<AuthState>.broadcast();

  // Accounts that can log in: email -> password.
  final Map<String, String> accounts = {'lucas@example.com': 'secret123'};
  // Like the "Confirm email" setting in Supabase.
  bool confirmEmail = false;
  int gitHubLogins = 0;

  void _change(AuthChangeEvent event, Session? session) {
    _session = session;
    _changes.add(AuthState(event, session));
  }

  // Like a GitHub login that comes back with an error.
  void failGitHubLogin(String message) => _changes.addError(
    AuthException(message),
  );

  @override
  Session? get currentSession => _session;

  @override
  Stream<AuthState> get authStateChanges => _changes.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (accounts[email] != password) {
      throw const AuthException('Invalid login credentials');
    }
    _change(AuthChangeEvent.signedIn, fakeSession(email: email));
  }

  @override
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (accounts.containsKey(email)) {
      throw const AuthException(
        'This email is already registered. Try logging in.',
      );
    }
    accounts[email] = password;
    if (confirmEmail) return false;
    _change(
      AuthChangeEvent.signedIn,
      fakeSession(name: fullName, email: email),
    );
    return true;
  }

  @override
  Future<void> signInWithGitHub() async => gitHubLogins++;

  @override
  Future<void> signOut() async => _change(AuthChangeEvent.signedOut, null);
}
