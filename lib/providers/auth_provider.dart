import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

// Gives the app the AuthService. The tests replace it with a fake one.
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(Supabase.instance.client.auth),
);

// Gives the app the ProfileService. The tests replace it with a fake one.
final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(Supabase.instance.client),
);

// The current session (null = logged out).
// It listens to Supabase, so it changes by itself when the user logs in,
// logs out, or when the access token is refreshed. The router watches it to
// decide between the login page and the shop.
class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() {
    final auth = ref.watch(authServiceProvider);

    final subscription = auth.authStateChanges.listen(
      (authState) => state = authState.session,
      // e.g. the Google login was cancelled or is not set up in Supabase.
      onError: (Object error) {
        ref.read(authErrorProvider.notifier).show(friendlyAuthMessage(error));
      },
    );
    ref.onDispose(subscription.cancel);

    // Logged in already? (supabase_flutter restores the saved session.)
    return auth.currentSession;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);

// The logged-in user's id, or null. Only changes on log in / log out (not
// when the access token is refreshed), so providers that watch it don't
// reload every hour.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(sessionProvider.select((session) => session?.user.id)),
);

// The logged-in user's row in the profiles table, with their role.
// null when logged out, or when the profile is missing.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileServiceProvider).fetchMyProfile(userId);
}, retry: (retryCount, error) => null);

// true when the logged-in user is an admin. The screens use it to show or
// hide the admin controls. This is only for the looks: the real check is
// done by the RLS policies in Supabase.
final isAdminProvider = Provider<bool>(
  (ref) => ref.watch(profileProvider).value?.isAdmin ?? false,
);

// Log in, register, Google login and log out. The screens call these
// instead of talking to the AuthService themselves.
final authActionsProvider = Provider<AuthActions>(AuthActions.new);

class AuthActions {
  AuthActions(this.ref);

  final Ref ref;

  AuthService get _auth => ref.read(authServiceProvider);

  Future<void> signIn({required String email, required String password}) {
    ref.read(authErrorProvider.notifier).clear();
    return _auth.signIn(email: email, password: password);
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) {
    ref.read(authErrorProvider.notifier).clear();
    return _auth.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }

  Future<void> signInWithGoogle() {
    ref.read(authErrorProvider.notifier).clear();
    return _auth.signInWithGoogle();
  }

  // The cart empties by itself (cartProvider watches the user id).
  Future<void> signOut() => _auth.signOut();

  // Change the user's own first and last name in the profiles table.
  Future<void> updateName({
    required String firstName,
    required String lastName,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref
        .read(profileServiceProvider)
        .updateMyName(userId: userId, firstName: firstName, lastName: lastName);
    ref.invalidate(profileProvider);
  }
}

// A login error that did not come from a button press (like a failed
// Google login). The login page shows it.
class AuthErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) => state = message;

  void clear() => state = null;
}

final authErrorProvider = NotifierProvider<AuthErrorNotifier, String?>(
  AuthErrorNotifier.new,
);
