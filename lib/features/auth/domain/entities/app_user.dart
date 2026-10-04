class AppUser {
  final String uid;
  final String email;
  final String name;
  AppUser({required this.uid, required this.email, required this.name});

  //convert app user
  Map<String, dynamic> toMap() {
    return {'uid': uid, 'email': email, 'name': name};
  }

  // Convert AppUser instance into a Map for Firestore
  Map<String, dynamic> toJson() {
    return {'uid': uid, 'email': email, 'name': name};
  }

  //convert json -> app user
  factory AppUser.fromJson(Map<String, dynamic> jsonUser) {
    return AppUser(
      uid: jsonUser['uid'],
      email: jsonUser['email'],
      name: jsonUser['name'],
    );
  }
}
