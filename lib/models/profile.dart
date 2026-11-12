// The logged-in user's row in the Supabase `profiles` table, with the name
// of their role from the `roles` table ("customer" or "admin").
//
// The trigger handle_new_user (supabase/final_project.sql) makes this row
// when an account is created, always as a customer.
class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  // Same uuid as the user in Supabase Auth.
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  bool get isAdmin => role == 'admin';

  String get fullName => '$firstName $lastName'.trim();

  // The row looks like {..., 'role_id': 1, 'roles': {'role': 'customer'}}
  // because ProfileService asks for the role's name with the profile.
  factory Profile.fromJson(Map<String, dynamic> json) {
    final roleRow = json['roles'] as Map<String, dynamic>?;
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      firstName: json['firstname'] as String? ?? '',
      lastName: json['lastname'] as String? ?? '',
      role: roleRow?['role'] as String? ?? 'customer',
    );
  }
}
