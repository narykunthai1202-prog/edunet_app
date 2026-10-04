import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';

abstract class SearchRepos {
  Future<List<ProfileUser?>> searchUsers(String query);
}
