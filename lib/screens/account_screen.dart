import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/profile.dart';
import '../providers/auth_provider.dart';
import '../routing/app_router.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../widgets/state_views.dart';

// The user's profile (from the profiles table), their role, a way to change
// their name, and Sign Out.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider)?.user;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      // null for a moment while logging out, before the router moves on.
      body: user == null
          ? const SizedBox.shrink()
          : profileAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                title: 'Could not load your profile',
                message: friendlyErrorMessage(error),
                onRetry: () => ref.invalidate(profileProvider),
              ),
              data: (profile) => SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileCard(
                          name: profile?.fullName.isNotEmpty == true
                              ? profile!.fullName
                              : displayNameOf(user),
                          email: profile?.email ?? user.email ?? '',
                          role: profile?.role ?? 'customer',
                          provider: providerOf(user),
                          avatarUrl: avatarUrlOf(user),
                        ),
                        const SizedBox(height: 16),
                        if (profile != null)
                          _MenuTile(
                            icon: Icons.badge_outlined,
                            title: 'Edit name',
                            onTap: () => _editName(context, ref, profile),
                          ),
                        if (profile?.isAdmin == true) ...[
                          _MenuTile(
                            icon: Icons.receipt_long_outlined,
                            title: 'All orders',
                            onTap: () => context.push(AppRoutes.adminOrders),
                          ),
                          _MenuTile(
                            icon: Icons.category_outlined,
                            title: 'Manage genres',
                            onTap: () => context.push(AppRoutes.adminGenres),
                          ),
                        ] else
                          _MenuTile(
                            icon: Icons.receipt_long_outlined,
                            title: 'My orders',
                            onTap: () => context.push(AppRoutes.orders),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            // The router sends the user to the login page
                            // once the session is gone; the cart empties.
                            onPressed: () =>
                                ref.read(authActionsProvider).signOut(),
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final names = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _EditNameDialog(profile: profile),
    );
    if (names == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(authActionsProvider)
          .updateName(firstName: names.$1, lastName: names.$2);
      messenger.showSnackBar(const SnackBar(content: Text('Name saved')));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not save. ${friendlyErrorMessage(error)}'),
        ),
      );
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.role,
    required this.provider,
    required this.avatarUrl,
  });

  final String name;
  final String email;
  final String role;
  final String provider;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = role == 'admin';
    final loginLabel = switch (provider) {
      'google' => 'Logged in with Google',
      'github' => 'Logged in with GitHub',
      _ => 'Logged in with email',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              foregroundImage: avatarUrl == null
                  ? null
                  : NetworkImage(avatarUrl!),
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          isAdmin
                              ? Icons.admin_panel_settings_outlined
                              : Icons.person_outline,
                          size: 16,
                        ),
                        label: Text(isAdmin ? 'Admin' : 'Customer'),
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          provider == 'email'
                              ? Icons.email_outlined
                              : Icons.login,
                          size: 16,
                        ),
                        label: Text(loginLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// Returns (first name, last name), or null when cancelled.
class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.profile});

  final Profile profile;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.profile.firstName);
  late final _last = TextEditingController(text: widget.profile.lastName);

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit name'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _first,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: (text) =>
                  (text ?? '').trim().isEmpty ? 'Enter your first name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _last,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, (_first.text.trim(), _last.text.trim()));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
