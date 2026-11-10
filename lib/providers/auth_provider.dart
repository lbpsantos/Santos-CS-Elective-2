import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart.dart';
import '../services/auth_service.dart';

// Gives the app the AuthService. The tests replace it with a fake one.
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(Supabase.instance.client.auth),
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
      (authState) {
        if (authState.event == AuthChangeEvent.signedOut) {
          // The next user should not see this user's cart.
          clearCart();
        }
        state = authState.session;
      },
      // e.g. the GitHub login was cancelled or is not set up in Supabase.
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

// A login error that did not come from a button press (like a failed
// GitHub login). The login page shows it.
class AuthErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) => state = message;

  void clear() => state = null;
}

final authErrorProvider = NotifierProvider<AuthErrorNotifier, String?>(
  AuthErrorNotifier.new,
);
