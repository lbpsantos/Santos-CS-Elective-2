import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_first_flutter_ui/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fake_auth_service.dart';

// These tests check the requests AuthService sends to Supabase Auth.
// A fake HTTP client answers instead of a real Supabase project.
void main() {
  late List<http.Request> requests;

  AuthService serviceThatReplies(
    Future<http.Response> Function(http.Request request) reply,
  ) {
    requests = [];
    final supabase = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
      // Sign-up uses PKCE, which saves a secret code. supabase_flutter
      // saves it on the device; here a simple map is enough.
      authOptions: AuthClientOptions(
        pkceAsyncStorage: _MemoryStorage(),
        autoRefreshToken: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await reply(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    addTearDown(supabase.dispose);
    return AuthService(supabase.auth);
  }

  http.Response jsonReply(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );

  Map<String, dynamic> userJson({bool hasIdentity = true}) => {
    'id': 'user-123',
    'aud': 'authenticated',
    'email': 'lucas@example.com',
    'app_metadata': {'provider': 'email'},
    'user_metadata': {'full_name': 'Lucas Santos'},
    'created_at': '2026-11-10T00:00:00Z',
    'identities': [
      if (hasIdentity)
        {
          'id': 'user-123',
          'identity_id': 'identity-1',
          'user_id': 'user-123',
          'identity_data': {'email': 'lucas@example.com'},
          'provider': 'email',
          'created_at': '2026-11-10T00:00:00Z',
          'last_sign_in_at': '2026-11-10T00:00:00Z',
        },
    ],
  };

  Map<String, dynamic> sessionJson(String refreshToken) => {
    'access_token': fakeAccessToken(
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    ),
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': refreshToken,
    'user': userJson(),
  };

  test('signIn sends the email and password and keeps the session', () async {
    final service = serviceThatReplies(
      (request) async => jsonReply(sessionJson('refresh-1')),
    );

    await service.signIn(email: 'lucas@example.com', password: 'secret123');

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/auth/v1/token');
    expect(request.url.queryParameters['grant_type'], 'password');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['email'], 'lucas@example.com');
    expect(body['password'], 'secret123');

    final session = service.currentSession!;
    expect(session.refreshToken, 'refresh-1');
    expect(session.user.email, 'lucas@example.com');
    expect(session.expiresAt, isNotNull); // read from the access token
  });

  test('register saves the name and reports a confirmation email', () async {
    // With "Confirm email" on, Supabase sends back only the user.
    final service = serviceThatReplies((request) async => jsonReply(userJson()));

    final loggedIn = await service.register(
      email: 'lucas@example.com',
      password: 'secret123',
      fullName: 'Lucas Santos',
    );

    final request = requests.single;
    expect(request.url.path, '/auth/v1/signup');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['email'], 'lucas@example.com');
    expect(body['data'], {'full_name': 'Lucas Santos'});
    expect(loggedIn, isFalse);
    expect(service.currentSession, isNull);
  });

  test('register with a taken email gives a clear error', () async {
    final service = serviceThatReplies(
      (request) async => jsonReply(userJson(hasIdentity: false)),
    );

    await expectLater(
      service.register(
        email: 'lucas@example.com',
        password: 'secret123',
        fullName: 'Lucas Santos',
      ),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          contains('already registered'),
        ),
      ),
    );
  });

  test('user details come from the session', () {
    final githubUser = fakeSession(provider: 'github', name: 'octocat').user;

    expect(displayNameOf(githubUser), 'octocat');
    expect(providerOf(githubUser), 'github');
    expect(
      friendlyAuthMessage(const AuthException('Invalid login credentials')),
      'Wrong email or password.',
    );
  });
}

class _MemoryStorage extends GotrueAsyncStorage {
  final _items = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _items[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _items[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _items.remove(key);
  }
}
