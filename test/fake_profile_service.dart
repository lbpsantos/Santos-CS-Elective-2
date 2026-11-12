import 'package:my_first_flutter_ui/models/profile.dart';
import 'package:my_first_flutter_ui/services/profile_service.dart';

// A ProfileService without Supabase. Every user gets a profile with [role]
// ("customer" or "admin"), like the handle_new_user trigger plus, for
// admins, the SQL that promotes an account.
class FakeProfileService implements ProfileService {
  FakeProfileService({this.role = 'customer', this.missing = false});

  String role;
  // Like an account whose profile row was never made.
  bool missing;
  String firstName = 'Lucas';
  String lastName = 'Santos';
  int loads = 0;

  Profile _profile(String userId) => Profile(
    id: userId,
    email: 'lucas@example.com',
    firstName: firstName,
    lastName: lastName,
    role: role,
  );

  @override
  Future<Profile?> fetchMyProfile(String userId) async {
    loads++;
    return missing ? null : _profile(userId);
  }

  @override
  Future<Profile> updateMyName({
    required String userId,
    required String firstName,
    required String lastName,
  }) async {
    this.firstName = firstName;
    this.lastName = lastName;
    return _profile(userId);
  }
}
