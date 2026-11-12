import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

// All the Supabase queries for the `profiles` table.
class ProfileService {
  ProfileService(this._supabase);

  final SupabaseClient _supabase;

  // Every column, plus the role's name. "roles(role)" follows role_id to
  // the roles table, so each row comes back with {'roles': {'role': ...}}.
  static const String _columns = '*, roles(role)';

  // The logged-in user's own profile. RLS only lets a user read their own
  // row (admins can read every row). Returns null if the row is missing,
  // e.g. the handle_new_user trigger was not set up yet.
  Future<Profile?> fetchMyProfile(String userId) async {
    final row = await _supabase
        .from('profiles')
        .select(_columns)
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  // Change the user's own name. The role can't be changed from the app:
  // Supabase only grants updates on the firstname and lastname columns.
  Future<Profile> updateMyName({
    required String userId,
    required String firstName,
    required String lastName,
  }) async {
    final row = await _supabase
        .from('profiles')
        .update({'firstname': firstName, 'lastname': lastName})
        .eq('id', userId)
        .select(_columns)
        .single();
    return Profile.fromJson(row);
  }
}
