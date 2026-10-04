import 'package:edunest_app/features/auth/domain/entities/app_user.dart';

class ProfileUser extends AppUser {
  final String bio;
  final String profileImageUrl;
  final List<String> following;
  final List<String> followers;
  final String dateofbirth;
  final String gender;
  final String phoneNumber;
  final String address;
  final String university;
  final String major;
  final String years;
  final String semester;
  final String hobbies;
  final String nickname;
  final String relationshipStatus;

  ProfileUser({
    required super.uid,
    required super.email,
    required super.name,
    required this.bio,
    required this.profileImageUrl,
    required this.following,
    required this.followers,
    required this.dateofbirth,
    required this.gender,
    required this.phoneNumber,
    required this.address,
    required this.university,
    required this.major,
    required this.years,
    required this.semester,
    required this.hobbies,
    required this.nickname,
    required this.relationshipStatus,
  });
  //method to update profile
  ProfileUser copyWith({
    String? newBio,
    String? newProfileImageUrl,
    String? newName,
    String? newEmail,
    List<String>? newFollowers,
    List<String>? newFollowering,
    String? newDateofbirth,
    String? newGender,
    String? newPhoneNumber,
    String? newAddress,
    String? newUniversity,
    String? newMajor,
    String? newYears,
    String? newSemester,
    String? newHobbies,
    String? newNickname,
    String? newRelationshipStatus,
  }) {
    return ProfileUser(
      uid: uid,
      email: newEmail ?? email,
      name: newName ?? name,
      bio: newBio ?? bio,
      profileImageUrl: newProfileImageUrl ?? profileImageUrl,
      followers: newFollowers ?? followers,
      following: newFollowering ?? following,
      dateofbirth: newDateofbirth ?? dateofbirth,
      gender: newGender ?? gender,
      phoneNumber: newPhoneNumber ?? phoneNumber,
      address: newAddress ?? address,
      university: newUniversity ?? university,
      major: newMajor ?? major,
      years: newYears ?? years,
      semester: newSemester ?? semester,
      hobbies: newHobbies ?? hobbies,
      nickname: newNickname ?? nickname,
      relationshipStatus: newRelationshipStatus ?? relationshipStatus,
    );
  }

  // convert users -> json
  @override
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'bio': bio,

      'profileImageUrl': profileImageUrl,
      'followers': followers,
      'following': following,
      'dateofbirth': dateofbirth,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'address': address,
      'university': university,
      'major': major,
      'years': years,
      'semester': semester,
      'hobbies': hobbies,
      'nickname': nickname,
      'relationshipStatus': relationshipStatus,
    };
  }

  //convert json -> profile user
  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      uid: json['uid'],
      email: json['email'],
      name: json['name'],
      bio: json['bio'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      dateofbirth: json['dateofbirth'] ?? '',
      gender: json['gender'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'] ?? '',
      university: json['university'] ?? '',
      major: json['major'] ?? '',
      years: json['years'] ?? '',
      semester: json['semester'] ?? '',
      hobbies: json['hobbies'] ?? '',
      nickname: json['nickname'] ?? '',
      relationshipStatus: json['relationshipStatus'] ?? '',
    );
  }
}
