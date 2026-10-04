import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import 'package:edunest_app/features/search/domain/search_repos.dart';

class FirebaseSearchRepo implements SearchRepos {
  @override
  Future<List<ProfileUser?>> searchUsers(String query) async {
    try {
      final restult = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      return restult.docs
          .map((doc) => ProfileUser.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error searching user: $e');
    }
  }
}
